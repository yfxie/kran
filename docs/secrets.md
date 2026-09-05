---
title: Secrets
description: Where the registry password comes from, how krane turns secrets.ejson into Kubernetes Secrets, and how to produce an image pull secret from the same file.
---

# Secrets

Two things are decrypted in two places, and both can live in the same `secrets.ejson`.

* The **registry password** that `docker login` needs, decrypted on your machine by kran.
* The **application's secrets**, decrypted in the cluster by krane.

## ejson

[ejson](https://github.com/Shopify/ejson) encrypts the values in a JSON file but not the keys, so
the file can be committed. Anyone can add a value with the public key stored in the file; only the
private key reads one. Keys starting with an underscore stay in plain text, which is how
`_public_key` and `_type` remain readable.

```console
$ ejson keygen
Public Key:
8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c
Private Key:
b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3
$ ejson encrypt config/deploy/secrets.ejson
Wrote 842 bytes to config/deploy/secrets.ejson
```

`ejson keygen` writes the private key to `/opt/ejson/keys`, where `ejson decrypt` looks for it;
`EJSON_KEYDIR` overrides that directory.

## The registry password

Needed only when kran logs in itself; leave `registry.username` and `registry.password` out to
reuse the login `docker` already has.

A plain value, or any ERB expression, since the file is evaluated as ERB before it is parsed:

```yaml
registry:
  password: <%= ENV["GITHUB_TOKEN"] %>
```

```yaml
registry:
  password: <%= %x(aws ecr get-login-password --region us-east-1).strip %>
```

```yaml
registry:
  password: <%= %x(op read op://deploy/ghcr/token).strip %>
```

Or a dotted path into the decrypted `secrets.ejson`:

```yaml
registry:
  password:
    ejson: registry.password
```

Kran runs `ejson decrypt` on `krane.secrets` — `config/deploy/secrets.ejson` by default — and walks
the path, using the `ejson` binary and the private key on your machine.

```console
$ kran deploy
ERROR: registry.password not found in config/deploy/secrets.ejson

# and when the file is not configured at all
$ kran deploy
ERROR: registry.password refers to ejson but krane.secrets is not set and config/deploy/secrets.ejson does not exist
```

## How krane reads secrets.ejson

`secrets.ejson` lives in the templates directory, beside the manifests:

```text
config/
├── kran.yml
└── deploy/
    ├── deployment.yaml.erb
    └── secrets.ejson
```
{: .tree }

The file must be named exactly `secrets.ejson`, and kran passes it with its own `-f`:

```text
krane render -f config/deploy ... \
  | krane deploy storefront prod-east \
      -f config/deploy/secrets.ejson -
```

Krane looks at one top-level key. Every entry under `kubernetes_secrets` becomes one Secret:

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "kubernetes_secrets": {
    "rails-app": {
      "_type": "Opaque",
      "data": {
        "SECRET_KEY_BASE": "EJ[1:...]",
        "DATABASE_URL": "EJ[1:...]"
      }
    }
  }
}
```

* The entry name is the Secret's name.
* `_type` is written into the Secret's `type` field verbatim.
* Every value under `data` is decrypted, then base64-encoded.

```yaml
envFrom:
  - secretRef:
      name: rails-app
```

Keys outside `kubernetes_secrets` are ignored and create nothing in the cluster.

## The ejson-keys Secret

Krane reads a Secret named `ejson-keys` in the target namespace: each data key is a public key, its
value the private key.

```console
$ kubectl --context prod-east --namespace storefront \
>   create secret generic ejson-keys \
>   --from-literal=8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c=<private key>
secret/ejson-keys created

# without it, krane stops before applying anything
$ kran deploy
Secret `ejson-keys` not found in namespace `storefront`
```

> **Create it, never apply it.** Krane prunes resources its own deploy did not produce, and a
> Secret carrying the last-applied-configuration annotation looks like one of those: it would be
> deleted on the next deploy, and every deploy after that would fail to decrypt.
{: .callout .danger }

## An image pull secret from the same file

The Secret type `kubernetes.io/dockerconfigjson` holds a docker configuration file under one key,
`.dockerconfigjson`.

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "kubernetes_secrets": {
    "registry": {
      "_type": "kubernetes.io/dockerconfigjson",
      "data": {
        ".dockerconfigjson": "EJ[1:...]"
      }
    }
  }
}
```

The encrypted value is the docker configuration, serialised to one JSON string:

```json
{"auths":{"ghcr.io":{"username":"acme-deploy","password":"ghp_notarealtoken","auth":"YWNtZS1kZXBsb3k6Z2hwX25vdGFyZWFsdG9rZW4="}}}
```

`auth` is the base64 of `username:password`:

```console
$ printf '%s' 'acme-deploy:ghp_notarealtoken' | base64
YWNtZS1kZXBsb3k6Z2hwX25vdGFyZWFsdG9rZW4=
```

Run `ejson encrypt`, and krane creates the Secret on every deploy:

```yaml
spec:
  imagePullSecrets:
    - name: registry
  containers:
    - name: web
      image: <%= image %>
```

## Reusing one password for both

Keep it as a plain key in the same Secret and point kran at it:

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "kubernetes_secrets": {
    "registry": {
      "_type": "Opaque",
      "data": {
        "password": "EJ[1:...]"
      }
    }
  }
}
```

```yaml
registry:
  username: acme-deploy
  password:
    ejson: kubernetes_secrets.registry.data.password
```

Kran decrypts locally for `docker login`; krane creates an `Opaque` Secret named `registry`. To
avoid that Secret, move the key out of `kubernetes_secrets`:

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "registry": {
    "password": "EJ[1:...]"
  }
}
```

```yaml
registry:
  password:
    ejson: registry.password
```

The file is still valid ejson; the extra key exists only for kran.

## What is never printed

```console
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
```

The real password is written to `docker login` on standard input, so it never appears in a process
list, a shell history or a CI log.
