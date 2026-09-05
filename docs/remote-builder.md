---
title: Remote builder
description: Building on another Docker host with DOCKER_HOST, why kran does not create a buildx builder, and what that costs for multi-arch builds.
---

# Remote builder

```yaml
builder:
  arch: amd64
  remote: ssh://builder@build.internal
```

```console
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | DOCKER_HOST=ssh://builder@build.internal docker login ghcr.io -u acme-deploy --password-stdin
DOCKER_HOST=ssh://builder@build.internal docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
```

Both commands are prefixed, so no local daemon has to be running. The login itself lands in the
docker CLI's config on your machine either way, which is why a `docker login` you ran by hand also
works with a remote builder.

## Why

* Your laptop is arm64 and the cluster is amd64. Building `linux/amd64` locally means emulation.
* A build host next to the registry pushes faster and keeps a warm layer cache everyone shares.

The build context is still read locally and streamed over SSH, so `.dockerignore` matters more here
than anywhere else.

## DOCKER_HOST, not a buildx builder

Kran sets `DOCKER_HOST`. The docker CLI opens an SSH connection and the build runs on the remote
daemon. Nothing is created or cleaned up, and the same configuration works from any machine that
can reach the host.

Kamal creates a docker context and a buildx builder instead:

```sh
docker context create kamal-remote \
  --docker host=ssh://builder@build.internal
docker buildx create --name kamal-builder kamal-remote
```

A buildx builder can have several nodes, so kamal can split a multi-arch build between a local
arm64 node and a remote amd64 node and build each natively.

| | `DOCKER_HOST` (kran) | buildx builder (kamal) |
| --- | --- | --- |
| State on your machine | none | a docker context and a builder instance |
| Lifecycle to manage | none | create, inspect, remove |
| Single architecture | works | works |
| Multi-arch | depends on the remote daemon | can be split across nodes |

A remote builder is usually one host chosen to match the cluster's architecture, and for that a
builder instance is bookkeeping with no benefit.

## Multi-arch on a remote daemon

> **Multi-arch depends entirely on the remote daemon.** Kran sets `DOCKER_HOST` and nothing else,
> so it cannot split the build across machines the way kamal's buildx builder can.
{: .callout .warning }

With `arch: [amd64, arm64]` and a remote, one daemon must build both platforms. That needs either:

* binfmt and QEMU installed
  (`docker run --privileged --rm tonistiigi/binfmt --install all` on the build host) **and** the
  containerd image store enabled, because the classic image store cannot hold a multi-platform
  image; or
* a buildx builder configured on that host with a node for each architecture.

```console
$ kran build details
DOCKER_HOST=ssh://builder@build.internal docker version
DOCKER_HOST=ssh://builder@build.internal docker buildx ls
NAME/NODE       DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*        docker
 \_ default      \_ default       running   v0.19.0    linux/amd64, linux/arm64
```

If `PLATFORMS` lists both, a multi-arch build works. When only one architecture is deployed, set
one:

```yaml
builder:
  arch: amd64
  remote: ssh://builder@build.internal
```

## Requirements on the host

* SSH access as a user in the `docker` group, or with equivalent access to the daemon socket, which
  is root-equivalent on the host.
* Key-based authentication that works non-interactively. `docker` runs `ssh` with your normal
  configuration, so `~/.ssh/config`, jump hosts and agent forwarding apply:

```console
$ ssh builder@build.internal docker version
Client: Docker Engine - Community
 Version:  27.5.1
```

* Enough disk for the build cache. Nothing prunes it for you.

## No remote

```yaml
builder:
  arch: arm64
```

```console
$ kran build push --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/arm64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
```
