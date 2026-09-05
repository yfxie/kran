---
title: Prerequisites
description: The tools kran drives, the kubeconfig and context it needs, and how kran version verifies them.
---

# Prerequisites

Kran drives four external programs.

| Tool | Why kran needs it | Install |
| --- | --- | --- |
| `docker` with buildx | builds and pushes the image | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| `krane` | renders the templates and deploys them | `gem install krane` |
| `kubectl` | `logs`, `exec`, `details`, `audit` | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| `ejson` | only when a registry password is read from `secrets.ejson` | `gem install ejson` |

One command checks all of them at once:

```console
# a tool not on PATH shows `not found`; one that fails to run shows its first error line
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    failed: Could not locate Gemfile (Bundler::GemfileNotFound)
kubectl  not found
```

`kran version` works without a configuration file. With one, the krane line uses `krane.command`.

## docker

`--platform` and pushing straight from a build both come from BuildKit, through the `buildx`
plugin. Docker Desktop and recent Docker Engine packages ship it.

```console
$ docker buildx version
github.com/docker/buildx v0.20.1 47ac5aa
```

> Without buildx, `--platform` fails for any platform other than the host's own. `kran build
> details` prints the daemon and builders a build would use.
{: .callout .warning }

## krane

Krane applies the manifests, waits for the rollout and reports failures. Kran replaces no part of
it. Install it globally, or pin it in a deploy bundle and tell kran how to run it:

```yaml
krane:
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```

Kran checks the first word of that command that is not an environment assignment — here `bundle`,
not `krane`. See [krane templates]({{ '/templates/' | relative_url }}) for what krane renders.

## ejson

[ejson](https://github.com/Shopify/ejson) encrypts values inside a JSON file so the file can be
committed. You need the binary locally only when a registry password is read from it.

> The cluster needs its own copy of the private key, in a Secret named `ejson-keys`. That is a
> separate thing from the key on your machine. See [Secrets]({{ '/secrets/' | relative_url }}).
{: .callout .note }

## A kubeconfig and a context

```console
$ kubectl config get-contexts
CURRENT   NAME        CLUSTER     AUTHINFO         NAMESPACE
*         prod-east   prod-east   deploy@acme
          stage-eu    stage-eu    deploy@acme
```

The `NAME` column goes into `kubernetes.context`. Add `kubernetes.kubeconfig` when the cluster has
a file of its own; kran then prefixes every krane and kubectl command with it and leaves your
shell's own selection alone.

```yaml
kubernetes:
  kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront
```
