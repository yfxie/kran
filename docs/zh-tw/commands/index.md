---
title: 指令
description: 所有 kran 指令一覽，對照 kamal 的對應指令與底層實際執行的內容。
---

# 指令

| 指令 | kamal | 執行 |
| --- | --- | --- |
| [`kran init`]({{ '/zh-tw/commands/init/' | relative_url }}) | `kamal init` | 產生 `config/kran.yml` |
| [`kran deploy`]({{ '/zh-tw/commands/deploy/' | relative_url }}) | `kamal deploy` | `docker login`、`docker build --push`、`krane render \| krane deploy` |
| [`kran build push`]({{ '/zh-tw/commands/build/' | relative_url }}) | `kamal build push` | `docker login`、`docker build --push` |
| [`kran build details`]({{ '/zh-tw/commands/build/' | relative_url }}) | `kamal build details` | `docker version`、`docker buildx ls` |
| [`kran logs`]({{ '/zh-tw/commands/logs/' | relative_url }}) | `kamal app logs` | `kubectl logs -l <selector> --prefix --timestamps` |
| [`kran exec`]({{ '/zh-tw/commands/exec/' | relative_url }}) | `kamal app exec` | 先 `kubectl get pods`，再 `kubectl exec` |
| [`kran shell`]({{ '/zh-tw/aliases/' | relative_url }}) | `kamal shell` | `kran exec --interactive bash` 的別名 |
| [`kran console`]({{ '/zh-tw/aliases/' | relative_url }}) | `kamal console` | `kran exec --interactive bin/rails console` 的別名 |
| [`kran details`]({{ '/zh-tw/commands/details/' | relative_url }}) | `kamal details` | `kubectl get all -o wide` |
| [`kran audit`]({{ '/zh-tw/commands/audit/' | relative_url }}) | `kamal audit` | `kubectl rollout history deployment -l <selector>` |
| [`kran version`]({{ '/zh-tw/commands/version/' | relative_url }}) | `kamal version` | `docker --version`、`krane version`、`kubectl version --client` |

## 全域選項

每個指令都收這兩個。

| 選項 | 意義 |
| --- | --- |
| `-d NAME`、`--destination NAME` | 把 `config/kran.NAME.yml` 深層合併到 `config/kran.yml` 上 |
| `--dry-run` | 印出會執行的每一行指令，但一行都不跑 |
{: .opts }

`--dry-run` 同時跳過工具是否安裝的檢查，密碼會顯示成 `printf '%s' '[REDACTED]' | docker login ...`。

## 所有指令的共通行為

每個 kubectl 指令都長成
`KUBECONFIG=<kubeconfig> kubectl --context <context> --namespace <namespace> ...`，值由
`config/kran.yml` 帶進去。kran 不會去動你 shell 選好的 context。

所有外部指令都在 `Bundler.with_unbundled_env` 裡跑。kran 常常是透過 `bundle exec` 啟動的，而 krane
和 ejson 本身也是 Ruby 程式；少了這層隔離，它們會繼承 `RUBYOPT` 和 `BUNDLE_GEMFILE`，根本起不來。

工具在跑第一行指令之前就檢查完，所以不會發生「image 推上去了、卻沒部署成功」這種事。

## kamal 有但 kran 沒有的指令

kamal 管的是一台主機的生命週期，在 Kubernetes 上那些是叢集和模板的事：

* `kamal setup`、`kamal server bootstrap` — 叢集本來就在，節點也不歸 kran 管。
* `kamal proxy`、`kamal traefik` — 路由是模板裡的 Ingress 或 Service。
* `kamal accessory` — 資料庫或 Redis 是 Deployment、StatefulSet 或託管服務，跟應用程式一起寫在
  模板裡就好。
* `kamal env push` — 環境變數來自 krane 套用的 ConfigMap 或 Secret。
* `kamal rollback` — krane 部署的是期望狀態，不是一疊 release。要回退就把前一個 tag 部署上去：
  `kran deploy --version <前一個 sha> -P`。
