---
title: kran build
description: 只做建置與推送，以及查看建置會落在哪台 Docker daemon 上。
---

# kran build

<p class="usage"><b>用法</b><code>kran build push [--version TAG]
kran build details</code></p>

`kran deploy` 的建置部分，單獨拿出來用。

## kran build push

有設 `registry.username` 和 `registry.password` 時先跑 `docker login`，再跑 `docker build --push`。
tag 規則跟 `kran deploy` 一樣，而且只需要裝 `docker`。

| 選項 | 說明 |
| --- | --- |
| `--version TAG` | 直接指定 tag，不從 git 推導 |
| `-d NAME` | 把 `config/kran.NAME.yml` 疊到 `config/kran.yml` 上 |
| `--dry-run` | 只印出指令，一行都不執行 |
{: .opts }

```console
$ kran build push --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
```

適合在 CI 建置、換個地方再部署：

```sh
kran build push --version "$GITHUB_SHA"
# 稍後，在另一台機器上
kran deploy --version "$GITHUB_SHA" -P
```

## kran build details

```console
# 有設定 builder.remote 時兩行都會加前綴，看到的就是遠端那台 daemon
$ kran build details
DOCKER_HOST=ssh://builder@build.internal docker version
DOCKER_HOST=ssh://builder@build.internal docker buildx ls
NAME/NODE       DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*        docker
 \_ default      \_ default       running   v0.19.0    linux/amd64, linux/amd64/v2, linux/386
```

多數建置問題的答案就在 `PLATFORMS` 這一欄。如果它只列出 `linux/amd64`，設定卻寫著
`arch: [amd64, arm64]`，建置就會失敗。見[遠端 builder]({{ '/zh-tw/remote-builder/' | relative_url }})。

## kran 不管理 builder

kamal 的 `build` 底下還有 `create` 與 `remove`，用來管理 buildx builder 實例。kran 只是把
`DOCKER_HOST` 指向某台 daemon，所以沒有 builder 要建，也沒有要清。
