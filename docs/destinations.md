---
title: Destinations
description: Deploy the same project to staging and production with -d and a second, partial configuration file.
---

# Destinations

`-d NAME` layers `config/kran.NAME.yml` over `config/kran.yml`.

```text
config/
├── kran.yml
├── kran.staging.yml
└── kran.eu.yml
```
{: .tree }

```sh
kran deploy -d staging
kran logs -d staging -f
kran console -d staging
```

## The two files

The base file holds what does not change:

```yaml
# config/kran.yml
image: acme/storefront

registry:
  server: ghcr.io
  username: acme-deploy
  password: <%= ENV["GITHUB_TOKEN"] %>

builder:
  arch: amd64

kubernetes:
  kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront

app:
  selector: app=storefront
```

The destination file holds only the differences:

```yaml
# config/kran.staging.yml
kubernetes:
  kubeconfig: ~/.kube/stage-eu.yml
  context: stage-eu
  namespace: storefront-staging

app:
  selector: app=storefront-staging
```

```console
# the image and the registry are inherited; the cluster and namespace are not
$ kran deploy -d staging --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | KUBECONFIG=/home/dana/.kube/stage-eu.yml krane deploy storefront-staging stage-eu -f config/deploy/secrets.ejson -
```

## The merge

* A key in both files — the destination wins.
* A key only in the base file — kept.
* A nested hash — merged key by key.
* An array — replaced whole, not concatenated.

```yaml
# config/kran.yml
builder:
  arch: [amd64, arm64]
```

```yaml
# config/kran.staging.yml
builder:
  arch: [amd64]
```

Staging builds `linux/amd64` only.

## The destination variable

`destination` holds the name given to `-d`, or `nil` without the flag.

```yaml
# config/kran.yml
kubernetes:
  namespace: <%= destination ? "storefront-#{destination}" : "storefront" %>

app:
  selector: app=<%= ["storefront", destination].compact.join("-") %>
```

## The file must exist

```console
$ kran deploy -d production
ERROR: Configuration file not found in config/kran.production.yml
```

A typo in a destination name is worth stopping for, so kran does not fall back to the base file.
When the ERB above already does the work, an empty file is enough:

```sh
: > config/kran.staging.yml
```

## Overriding a section

To push staging to a different registry, override the whole section:

```yaml
# config/kran.staging.yml
registry:
  server: registry.internal
  username: ci
  password: <%= ENV["INTERNAL_REGISTRY_TOKEN"] %>
```

`registry` is a hash, so leaving out `username` would inherit `acme-deploy` from the base file.

## A destination in another cloud account

Docker's credential helper and kubectl's auth plugin pick their account from the environment, so a
destination that lives in another account sets it in `env`:

```yaml
# config/kran.staging.yml
env:
  CLOUDSDK_ACTIVE_CONFIG_NAME: acme-staging
```

The same works for `AWS_PROFILE` with ECR and EKS. See
[env]({{ '/configuration/' | relative_url }}#env).

## Aliases

Aliases are read after the merge, so a destination file can add or replace one:

```yaml
# config/kran.staging.yml
aliases:
  console: exec --interactive bin/rails console --sandbox
```

## One image, several environments

```sh
kran build push --version "$GITHUB_SHA"
kran deploy --version "$GITHUB_SHA" -P -d staging
kran deploy --version "$GITHUB_SHA" -P
```

`-P` skips the build and push, so the last two commands deploy exactly the image the first produced.
