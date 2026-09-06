---
title: Configuration
description: Every key of config/kran.yml, its default, how ERB is evaluated and how the -d destination mechanism merges a second file.
---

# Configuration

Configuration is read from `config/kran.yml`.

## The file kran init writes

```yaml
# Name of the container image, without registry and tag.
# The tag comes from `kran deploy --version`, or from git HEAD when omitted.
image: my-user/my-app

# Where the image is pushed. Leave username and password out to reuse the login docker already
# has on this machine; set both, in CI for example, and `docker login` runs before every push.
registry:
  # Leave empty for Docker Hub.
  server: ghcr.io
  # username: my-user
  # This file is ERB, so the password can come from the environment or any Ruby expression.
  # password: <%= ENV["KRAN_REGISTRY_PASSWORD"] %>
  # Or read it from krane's secrets.ejson (a dotted path from the top of the decrypted file):
  # password:
  #   ejson: registry.password

# How the image is built.
builder:
  # One or more of amd64, arm64. Becomes `docker build --platform linux/<arch>[,linux/<arch>]`.
  arch: amd64
  # Build on another Docker host over SSH. Sets DOCKER_HOST for `docker login` and `docker build`.
  # remote: ssh://user@builder.example.com
  # Build context. Defaults to the current directory, so uncommitted changes are included.
  # context: .

# Cluster and namespace that every command targets.
kubernetes:
  # Defaults to the KUBECONFIG environment variable, then ~/.kube/config.
  # kubeconfig: ~/.kube/my-cluster.yml
  context: my-cluster
  namespace: my-app

# How krane is invoked.
krane:
  # Directory of krane templates, passed to `krane render -f`.
  templates: config/deploy
  # ejson file passed to `krane deploy -f`. Defaults to <templates>/secrets.ejson when it exists.
  # secrets: config/deploy/secrets.ejson
  # Command used to run krane. Override when krane lives in a Gemfile.
  # command: bundle exec krane

# Pods used by logs and exec.
app:
  # Label selector for the application pods (kubectl -l).
  selector: app=my-app
  # Container inside the pod (kubectl -c). Defaults to the pod's default container.
  # container: web

# Environment variables put in front of every docker, krane and kubectl command, for settings those
# tools read from the environment: which cloud account docker's credential helper and kubectl's
# auth plugin sign in with, for example.
# env:
#   CLOUDSDK_ACTIVE_CONFIG_NAME: acme

# Shortcuts run with `kran <alias>`. Extra arguments are appended to the command.
aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
```

## image

Required. The repository name, without a registry host and without a tag.

```yaml
image: acme/storefront
```

The full reference is `<registry.server>/<image>:<tag>`. An empty `server` omits the host, which
is what Docker Hub wants. The tag never comes from this file; see
[Image tags]({{ '/image-tags/' | relative_url }}).

## registry

| Key | Required | Default | Effect |
| --- | --- | --- | --- |
| `server` | no | none (Docker Hub) | First argument to `docker login`, and the host in the image reference |
| `username` | no | none | `docker login -u <username>` |
| `password` | no | none | Written to `docker login --password-stdin` on standard input |

```yaml
registry:
  server: ghcr.io
  username: acme-deploy
  password: <%= ENV["GITHUB_TOKEN"] %>
```

`username` and `password` go together. Leave both out and no `docker login` runs: the push uses
whatever `docker login` already stored on this machine. Set both, in CI for example, and kran logs
in before every push.

The password is never placed on a command line. It can be a plain string, an ERB expression, or a
dotted path into krane's encrypted secrets. See [Secrets]({{ '/secrets/' | relative_url }}) for all
three.

## builder

| Key | Required | Default | Effect |
| --- | --- | --- | --- |
| `arch` | no | none | `docker build --platform linux/<arch>[,linux/<arch>]` |
| `remote` | no | none | `DOCKER_HOST=<url>` in front of `docker login` and `docker build` |
| `context` | no | `.` | Last argument to `docker build` |

```yaml
builder:
  arch: amd64            # one value, or [amd64, arm64] for both
  remote: ssh://builder@build.internal
```

Omitting `arch` omits `--platform`. Building somewhere else is
[Remote builder]({{ '/remote-builder/' | relative_url }}); why `context` defaults to the working
directory is [Image tags]({{ '/image-tags/' | relative_url }}).

## kubernetes

| Key | Required | Default | Effect |
| --- | --- | --- | --- |
| `kubeconfig` | no | `KUBECONFIG`, then `~/.kube/config` | `KUBECONFIG=<path>` in front of every krane and kubectl command |
| `context` | yes | — | `kubectl --context <context>`, and the second positional argument to `krane deploy` |
| `namespace` | yes | — | `kubectl --namespace <namespace>`, and the first positional argument to `krane deploy` |

```yaml
kubernetes:
  kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront
```

`kubeconfig` is expanded, so `~` works. Setting it means kran ignores whichever context you last
selected, and never changes it.

## krane

| Key | Required | Default | Effect |
| --- | --- | --- | --- |
| `templates` | no | `config/deploy` | `krane render -f <templates>` |
| `secrets` | no | `<templates>/secrets.ejson` when that file exists | `krane deploy -f <secrets>` |
| `command` | no | `krane` | The program used for `render`, `deploy` and `version` |

```yaml
krane:
  templates: config/deploy
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```

`templates` is a directory of krane manifests; see
[krane templates]({{ '/templates/' | relative_url }}). `secrets` must be named exactly
`secrets.ejson` and is found automatically inside `templates`; see
[Secrets]({{ '/secrets/' | relative_url }}). `command` is a shell prefix and may carry environment
assignments.

## app

| Key | Required | Default | Effect |
| --- | --- | --- | --- |
| `selector` | yes | — | `kubectl -l <selector>` for `logs`, `exec` and `audit` |
| `container` | no | the pod's default container | `kubectl -c <container>` |

```yaml
app:
  selector: app=storefront
  container: web
```

> `selector` must match the labels your krane templates put on the application pods. Nothing
> checks that for you, and a mismatch shows up as `kran logs` printing nothing.
{: .callout .warning }

## env

Environment variables put in front of every docker, krane and kubectl command. They are for
settings those tools read from the environment rather than from their arguments: which cloud
account docker's credential helper and kubectl's auth plugin sign in with, which docker
configuration directory to use.

```yaml
env:
  CLOUDSDK_ACTIVE_CONFIG_NAME: acme
```

```console
$ kran details --dry-run
CLOUDSDK_ACTIVE_CONFIG_NAME=acme KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront get all -o wide
```

Kran's own `KUBECONFIG` and `DOCKER_HOST` come after yours, so they win on a clash. `git` and
`ejson` do not get these variables. `--dry-run` prints the values as they are, so a registry
password belongs in `registry.password`, not here.

## aliases

A map of names to kran command strings. Extra command-line arguments are appended.

```yaml
aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
  migrate: exec bin/rails db:migrate
```

`kran migrate --trace` runs `kran exec bin/rails db:migrate --trace`. Aliases cannot shadow a
built-in. See [Aliases]({{ '/aliases/' | relative_url }}).

## ERB

The file is evaluated as ERB before it is parsed as YAML:

```yaml
registry:
  password: <%= ENV.fetch("GITHUB_TOKEN") %>

kubernetes:
  namespace: storefront-<%= ENV.fetch("USER") %>
```

One variable is provided: `destination`, the value of `-d`, or `nil` without it. Indentation
produced by an expression matters as much as indentation you type.

## Destinations

`-d NAME` deep-merges `config/kran.NAME.yml` over `config/kran.yml`.

```sh
kran deploy -d staging
```

The merge rules and what belongs in each file are on
[Destinations]({{ '/destinations/' | relative_url }}).

## Missing keys

```console
$ kran deploy
ERROR: Missing kubernetes.context in config/kran.yml

# with no configuration file at all
$ kran deploy
ERROR: Configuration file not found in config/kran.yml (run `kran init` to create one)
```
