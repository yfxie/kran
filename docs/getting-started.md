---
title: Getting started
description: Create config/kran.yml with kran init, fill it in, use the image binding in your templates, check the pipeline with a dry run, then deploy.
---

# Getting started

This assumes a project that already has a directory of krane templates. If it does not, read
[krane templates]({{ '/templates/' | relative_url }}) first.

## 1. Create the configuration file

```console
$ cd ~/code/storefront
$ kran init
Created config/kran.yml
```

## 2. Fill it in

A Rails application called `storefront`, deployed to a namespace of the same name on the
`prod-east` cluster:

```yaml
image: acme/storefront

registry:
  server: ghcr.io

builder:
  arch: amd64

kubernetes:
  # Optional; defaults to KUBECONFIG, then ~/.kube/config.
  # kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront

krane:
  templates: config/deploy

app:
  selector: app=storefront

aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
```

`image`, `kubernetes.context`, `kubernetes.namespace` and `app.selector` are required; everything
else has a default. See [Configuration]({{ '/configuration/' | relative_url }}).

The push uses the login `docker` already has on this machine. To have kran log in instead, set
`registry.username` and `registry.password`. The file is ERB, so the password can come from the
environment, a password manager, or krane's `secrets.ejson`. See
[Secrets]({{ '/secrets/' | relative_url }}).

## 3. Use the image in your templates

Kran builds and pushes the image, but only the template decides what the pods run. Point the
container at the `image` binding kran passes to `krane render`:

```erb
spec:
  containers:
    - name: web
      image: <%= image %>
```

> **Nothing checks this for you.** Without that line the deploy still succeeds and the pods keep
> running whatever image the template names. Kran does not fail and prints no warning.
{: .callout .danger }

`current_sha` keeps working for templates that already use it; it is the tag alone, where `image`
is the full reference. See [krane templates]({{ '/templates/' | relative_url }}).

Three more things a first deploy needs:

* The namespace must already exist on the cluster. Krane checks this and stops if it does not.
* If `config/deploy/secrets.ejson` exists, the namespace needs an `ejson-keys` Secret so krane can
  decrypt it. See [Secrets]({{ '/secrets/' | relative_url }}#the-ejson-keys-secret).
* `kran version` shows whether docker, krane and kubectl are found.

## 4. Read what kran would run

```console
# --dry-run runs nothing and does not require docker, krane or kubectl
$ kran deploy --dry-run
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

## 5. Deploy

```console
$ kran deploy
```

Kran stops at the first command that fails. The tag is the current git sha, or that sha with an
`_uncommitted_` suffix when the tree is dirty. See
[Image tags]({{ '/image-tags/' | relative_url }}).

```console
# deploy an image already in the registry
$ kran deploy -P

# deploy a specific tag
$ kran deploy --version v2.4.0
```

## Then

```sh
kran logs -f
kran details
kran console
```

These are `kubectl logs`, `kubectl get all -o wide` and `kubectl exec -it ... bin/rails console`
against the context and namespace in the configuration file.
