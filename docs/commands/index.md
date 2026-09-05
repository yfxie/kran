---
title: Commands
description: Every kran command, the kamal command it corresponds to and the docker, krane or kubectl command it runs.
---

# Commands

| Command | kamal | Runs |
| --- | --- | --- |
| [`kran init`]({{ '/commands/init/' | relative_url }}) | `kamal init` | writes `config/kran.yml` |
| [`kran deploy`]({{ '/commands/deploy/' | relative_url }}) | `kamal deploy` | `docker login`, `docker build --push`, `krane render \| krane deploy` |
| [`kran build push`]({{ '/commands/build/' | relative_url }}) | `kamal build push` | `docker login`, `docker build --push` |
| [`kran build details`]({{ '/commands/build/' | relative_url }}) | `kamal build details` | `docker version`, `docker buildx ls` |
| [`kran logs`]({{ '/commands/logs/' | relative_url }}) | `kamal app logs` | `kubectl logs -l <selector> --prefix --timestamps` |
| [`kran exec`]({{ '/commands/exec/' | relative_url }}) | `kamal app exec` | `kubectl get pods` then `kubectl exec` |
| [`kran shell`]({{ '/aliases/' | relative_url }}) | `kamal shell` | alias for `kran exec --interactive bash` |
| [`kran console`]({{ '/aliases/' | relative_url }}) | `kamal console` | alias for `kran exec --interactive bin/rails console` |
| [`kran details`]({{ '/commands/details/' | relative_url }}) | `kamal details` | `kubectl get all -o wide` |
| [`kran audit`]({{ '/commands/audit/' | relative_url }}) | `kamal audit` | `kubectl rollout history deployment -l <selector>` |
| [`kran version`]({{ '/commands/version/' | relative_url }}) | `kamal version` | `docker --version`, `krane version`, `kubectl version --client` |

## Global options

| Option | Meaning |
| --- | --- |
| `-d NAME`, `--destination NAME` | Deep-merge `config/kran.NAME.yml` over `config/kran.yml` |
| `--dry-run` | Print every command that would run, and run none of them |
{: .opts }

`--dry-run` also skips the check that docker, krane and kubectl are installed. Passwords are shown
as `printf '%s' '[REDACTED]' | docker login ...`.

## Shared behaviour

Every kubectl command is
`KUBECONFIG=<kubeconfig> kubectl --context <context> --namespace <namespace> ...`, filled in from
`config/kran.yml`. Kran never changes the context your shell has selected.

Every external command runs inside `Bundler.with_unbundled_env`. Kran is often started through
`bundle exec`, and krane and ejson are Ruby programs of their own; without this they would inherit
`RUBYOPT` and `BUNDLE_GEMFILE` and refuse to start.

Tools are checked before the first command runs, so a missing `krane` cannot leave a pushed image
with no deploy behind it.

## kamal commands with no kran equivalent

Kamal manages the lifecycle of a host. On Kubernetes that is the cluster's job and the templates':

* `kamal setup`, `kamal server bootstrap` — the cluster already exists, and nodes are not kran's to
  prepare.
* `kamal proxy`, `kamal traefik` — routing is an Ingress or a Service in your templates.
* `kamal accessory` — a database or Redis is a Deployment, a StatefulSet or a managed service.
* `kamal env push` — environment variables come from a ConfigMap or a Secret that krane applies.
* `kamal rollback` — krane deploys a desired state, not a sequence of releases. Roll back with
  `kran deploy --version <previous sha> -P`.
