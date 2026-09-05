---
title: 遠端 builder
description: 怎麼把建置交給另一台 Docker 主機，以及這個做法在多架構上的限制。
---

# 遠端 builder

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

兩行都加了前綴，所以本機不必跑著 Docker daemon。登入資訊不管怎樣都是存在你這台機器的 docker CLI
設定裡，這也是為什麼手動 `docker login` 過的帳號在遠端 builder 上照樣能用。

## 什麼情況下值得用

* 筆電是 arm64、叢集是 amd64。在本機建 `linux/amd64` 只能靠模擬。
* 一台離 registry 近的 build 主機推得快，快取也能全隊共用。

build context 還是在本機讀、透過 SSH 傳過去，所以 `.dockerignore` 在這裡比什麼時候都重要。

## 用 DOCKER_HOST，不建 buildx builder

kran 只設 `DOCKER_HOST`。docker CLI 開一條 SSH 連線，建置就在遠端 daemon 上跑。不會建立任何東西，
也沒有要清理，同一份設定在任何連得到那台主機的機器上都能用。

kamal 的做法是建一個 docker context 加一個 buildx builder：

```sh
docker context create kamal-remote \
  --docker host=ssh://builder@build.internal
docker buildx create --name kamal-builder kamal-remote
```

buildx builder 可以掛多個 node，所以 kamal 能把多架構建置拆給本機的 arm64 node 和遠端的 amd64
node，兩邊都用原生方式建。

| | `DOCKER_HOST`（kran） | buildx builder（kamal） |
| --- | --- | --- |
| 在本機留下的狀態 | 無 | 一個 docker context 加一個 builder 實例 |
| 要管的生命週期 | 無 | 建立、檢視、移除 |
| 單一架構 | 可用 | 可用 |
| 多架構 | 看遠端 daemon 的能力 | 可以拆給多個 node |

遠端 builder 通常就是一台「架構剛好跟叢集一致」而被選中的主機；在這種前提下，builder 實例只是多出
來的維護成本。

## 遠端 daemon 上的多架構建置
{: #multi-arch-on-a-remote-daemon }

設了 `arch: [amd64, arm64]` 又指定 remote，兩個平台就得由同一台 daemon 建完，這需要以下其中之一：

* 裝好 binfmt 與 QEMU（在 build 主機上跑
  `docker run --privileged --rm tonistiigi/binfmt --install all`），**而且**啟用 containerd
  image store，因為舊的 image store 存不下多平台 image；或是
* 那台主機上已經有一個 buildx builder，每個架構各掛一個 node。

先確認：

```console
$ kran build details
DOCKER_HOST=ssh://builder@build.internal docker version
DOCKER_HOST=ssh://builder@build.internal docker buildx ls
NAME/NODE       DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*        docker
 \_ default      \_ default       running   v0.19.0    linux/amd64, linux/arm64
```

`PLATFORMS` 兩個都列出來，多架構建置就沒問題。只部署單一架構的話，`arch` 設一個就好。

## 遠端主機需要具備的條件

* SSH 使用者要在 `docker` 群組裡，或有同等的 daemon socket 權限；這在那台主機上等同 root。
* 金鑰認證要能非互動運作。`docker` 是用你平常的設定去跑 `ssh`，所以 `~/.ssh/config`、jump host、
  agent forwarding 都會生效：

```console
$ ssh builder@build.internal docker version
Client: Docker Engine - Community
 Version:  27.5.1
```

* 建置快取要有足夠的磁碟空間，沒有人會幫你清。
