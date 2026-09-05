---
title: kran build
description: Build and push the image without deploying, and inspect the Docker daemon and builders a build would use.
---

# kran build

<p class="usage"><b>Usage</b><code>kran build push [--version TAG]
kran build details</code></p>

The build half of `kran deploy`, on its own.

## kran build push

Runs `docker login` when `registry.username` and `registry.password` are set, then
`docker build --push`. Same tag rules as `kran deploy`, and only `docker` has to be installed.

| Option | Meaning |
| --- | --- |
| `--version TAG` | Use `TAG` instead of deriving one from git |
| `-d NAME` | Load `config/kran.NAME.yml` over `config/kran.yml` |
| `--dry-run` | Print the commands and run none of them |
{: .opts }

```console
$ kran build push --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
```

Build in CI and deploy from somewhere else:

```sh
kran build push --version "$GITHUB_SHA"
# later, elsewhere
kran deploy --version "$GITHUB_SHA" -P
```

## kran build details

```console
# with a builder.remote configured, both lines are prefixed and this is the remote daemon
$ kran build details
DOCKER_HOST=ssh://builder@build.internal docker version
DOCKER_HOST=ssh://builder@build.internal docker buildx ls
NAME/NODE       DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*        docker
 \_ default      \_ default       running   v0.19.0    linux/amd64, linux/amd64/v2, linux/386
```

The `PLATFORMS` column answers most build problems. If it lists only `linux/amd64` and your
configuration says `arch: [amd64, arm64]`, the build will fail. See
[Remote builder]({{ '/remote-builder/' | relative_url }}).

## No builder management

Kamal's `build` group also has `create` and `remove` for a buildx builder instance. Kran points
`DOCKER_HOST` at a daemon instead, so there is no builder to create and none to clean up.
