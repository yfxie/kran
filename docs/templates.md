---
title: krane templates
description: What krane renders, the image and current_sha variables kran binds, partials, and where secrets.ejson goes.
---

# krane templates

> **This page is about krane, not kran.** It summarises the krane features kran relies on. None of
> it is part of kran, and krane's own documentation is authoritative: see
> [the krane README](https://github.com/Shopify/krane#readme).
{: .callout .warning }

Kran does not write manifests. It renders the krane templates you already have.

## The directory

`krane.templates` is a directory, `config/deploy` by default. Krane renders every file in it ending
in `.yml`, `.yaml`, `.yml.erb` or `.yaml.erb`, in an order it works out from their kinds.

```text
config/
├── kran.yml
└── deploy/
    ├── deployment.yaml.erb
    ├── service.yaml
    ├── ingress.yaml.erb
    ├── secrets.ejson
    └── partials/
        └── container.yaml.erb
```
{: .tree }

## render, then deploy

```sh
krane render -f config/deploy --current-sha 9c1f4d0 \
  --bindings image=ghcr.io/acme/storefront:9c1f4d0
```

writes plain YAML to standard output, and

```sh
krane deploy storefront prod-east -f -
```

applies YAML with no ERB left in it. `krane deploy` does not evaluate ERB, which is why kran runs
the two as a pipeline with `-f -`.

## The variables kran binds

Every `--bindings key=value` becomes a local variable in the templates, and `--current-sha` becomes
`current_sha`.

| Variable | Value |
| --- | --- |
| `image` | The full reference, `ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2` |
| `current_sha` | The tag alone, `9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2` |
| `deployment_id` | A short random string krane generates for each deploy |

```erb
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storefront
  labels:
    app: storefront
    app.kubernetes.io/version: <%= current_sha %>
spec:
  replicas: 2
  selector:
    matchLabels:
      app: storefront
  template:
    metadata:
      labels:
        app: storefront
    spec:
      imagePullSecrets:
        - name: registry
      containers:
        - name: web
          image: <%= image %>
          envFrom:
            - secretRef:
                name: rails-app
```

The pod labels here are what `app.selector: app=storefront` has to match; nothing enforces that, so
if `kran logs` shows nothing, look here first.

`current_sha` is the same string as the tag in `image`. Use it for version labels, not for building
an image reference by hand.

## Partials

Put them in a `partials/` directory next to the templates, or above them, and call them with locals:

```erb
spec:
  template:
    spec:
      containers:
        <%= partial "container", name: "web", command: ["bin/rails", "server"] %>
```

```erb
<%# config/deploy/partials/container.yaml.erb %>
- name: <%= name %>
  image: <%= image %>
  command: <%= command.inspect %>
  envFrom:
    - secretRef:
        name: rails-app
```

Command-line bindings are visible inside partials, so `image` need not be passed as a local.

## secrets.ejson

`secrets.ejson` sits in the templates directory but is not a template. Krane recognises it by name
and expects it on a separate `-f`, which kran adds when `<templates>/secrets.ejson` exists; set
`krane.secrets` for any other location. See [Secrets]({{ '/secrets/' | relative_url }}).

## Rendering by hand

```console
$ krane render -f config/deploy --current-sha 9c1f4d0 \
>   --bindings image=ghcr.io/acme/storefront:9c1f4d0
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storefront
...
```

`kran deploy --dry-run` prints the exact `krane render` invocation to copy.

## Protected namespaces

> Krane refuses to deploy to `default`, `kube-system` and `kube-public` unless given permission.
> Give the application a namespace of its own. See the
> [FAQ]({{ '/faq/#krane-refuses-to-deploy-to-my-namespace' | relative_url }}).
{: .callout .warning }
