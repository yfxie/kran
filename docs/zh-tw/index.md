---
title: 簡介
description: kran 包裝 Shopify 的 krane，一行指令完成 build image、push、render 模板並部署。
sidebar: false
---

# kran
{: .home-title }

用最簡單的方式，透過 [krane](https://github.com/Shopify/krane) 把應用部署到 Kubernetes。
一行指令搞定 build image、push、render krane 模板並部署。
{: .home-lede }

<div class="actions">
  <a class="btn btn-primary" href="{{ '/zh-tw/getting-started/' | relative_url }}">開始使用</a>
  <a class="btn" href="{{ '/zh-tw/configuration/' | relative_url }}">設定檔</a>
  <a class="btn" href="{{ '/zh-tw/commands/' | relative_url }}">指令</a>
</div>

*Kran* 是德文的「起重機」，也就是 Shopify 的 *krane* 這個字的由來。
{: .aside }

> **kran 和 krane 是兩個不同的工具。** *krane* 是 Shopify 的部署工具，真正做事的是它；*kran* 是這個
> gem，負責驅動它。兩者只差一個字母，看指令的時候請留意。
{: .callout .warning }

## 手動用 krane 部署

```console
$ export DOCKER_HOST=ssh://builder@build.internal
$ export KUBECONFIG=$HOME/.kube/prod-east.yml

$ echo "$GITHUB_TOKEN" | docker login ghcr.io -u acme-deploy \
>   --password-stdin
Login Succeeded

$ docker build --platform linux/amd64 --push \
>   -t ghcr.io/acme/storefront:$(git rev-parse HEAD) .
pushed ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2

$ krane render -f config/deploy --current-sha $(git rev-parse HEAD) \
>   | krane deploy storefront prod-east \
>       -f config/deploy/secrets.ejson -
Deploying resources
Successfully deployed 4 resources
```

上面每一個值，描述的都是這個專案本身：用哪個 registry、在哪台機器建置、目標平台、kubeconfig、
namespace、context、模板目錄。它們跟部署的流程無關，卻每次都得重打一遍。

## 改用 kran

把這些設定寫進 `config/kran.yml`，然後只要一行指令：

```console
# kran 會把每一步先印出來再執行
$ kran deploy
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

一樣的 docker、一樣的 krane、一樣的模板。tag 取自 git sha，完整的 image 位址則以 `image` 這個變數
傳進 krane 模板。

平常會用到的指令：

```sh
kran logs -f
kran exec bin/rails db:migrate

# namespace 內的所有資源，以及 rollout 歷史
kran details
kran audit

# 定義在 config/kran.yml 裡的別名
kran shell
kran console
```

`shell` 和 `console` 分別展開成 `exec --interactive bash` 與
`exec --interactive bin/rails console`。

用過 [kamal](https://kamal-deploy.org) 的話會覺得一樣簡單：熟悉的指令名稱、一個設定檔、一行指令部署，
只是目標從主機換成叢集。

## 它不是抽象層

kran 不產生 manifest、不發明資源型別、也不存任何狀態，只是把 `docker`、`krane`、`kubectl` 的指令
組出來執行。

> 每個指令都支援 `--dry-run`，會完整印出將要執行的指令，但一行都不跑。
{: .callout .tip }
