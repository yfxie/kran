---
title: 前置條件
description: kran 會呼叫哪些外部工具、需要什麼 kubeconfig 與 context，以及怎麼一次確認。
---

# 前置條件

kran 會驅動四個外部程式。

| 工具 | kran 拿它做什麼 | 安裝方式 |
| --- | --- | --- |
| `docker`（含 buildx） | 建置並推送 image | [docs.docker.com/get-docker](https://docs.docker.com/get-docker/) |
| `krane` | render 模板並部署 | `gem install krane` |
| `kubectl` | `logs`、`exec`、`details`、`audit` | [kubernetes.io](https://kubernetes.io/docs/tasks/tools/) |
| `ejson` | 只有 registry 密碼要從 `secrets.ejson` 讀時才需要 | `gem install ejson` |

一行指令就能全部檢查：

```console
# 不在 PATH 上的顯示 not found；跑得起來但失敗的會印出錯誤第一行
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    failed: Could not locate Gemfile (Bundler::GemfileNotFound)
kubectl  not found
```

`kran version` 沒有設定檔也能執行。有設定檔時，krane 那行會照 `krane.command` 執行。

## docker

`--platform` 和「建置完直接推送」都來自 BuildKit 的 `buildx` plugin，Docker Desktop 和近期的
Docker Engine 都內建。

```console
$ docker buildx version
github.com/docker/buildx v0.20.1 47ac5aa
```

> 沒有 buildx 的話，只要目標不是本機架構，`--platform` 就會失敗。`kran build details` 會印出建置
> 實際會落在哪個 daemon、支援哪些平台。
{: .callout .warning }

## krane

krane 負責把 manifest 套進叢集、等 rollout 完成、回報失敗，這些 kran 都沒有重做。可以裝在全域，
也可以放進獨立的部署 bundle，再告訴 kran 怎麼執行它：

```yaml
krane:
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```

kran 檢查的是這串指令裡第一個不是環境變數指定的字，以上面為例是 `bundle` 而不是 `krane`。krane 會
render 什麼，見 [krane 模板]({{ '/zh-tw/templates/' | relative_url }})。

## ejson

[ejson](https://github.com/Shopify/ejson) 會加密 JSON 檔裡的值，讓整份檔案可以進版控。只有當
registry 密碼要從它讀取時，本機才需要這支執行檔。

> 叢集自己也需要一份私鑰，放在名為 `ejson-keys` 的 Secret 裡。那跟你本機那把是兩回事。見
> [機密資料]({{ '/zh-tw/secrets/' | relative_url }})。
{: .callout .note }

## kubeconfig 與 context

```console
$ kubectl config get-contexts
CURRENT   NAME        CLUSTER     AUTHINFO         NAMESPACE
*         prod-east   prod-east   deploy@acme
          stage-eu    stage-eu    deploy@acme
```

`NAME` 這一欄填進 `kubernetes.context`。如果那個叢集有自己的設定檔，再加上
`kubernetes.kubeconfig`；kran 會把它加在每個 krane 與 kubectl 指令前面，不動你 shell 目前選的
context。

```yaml
kubernetes:
  kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront
```
