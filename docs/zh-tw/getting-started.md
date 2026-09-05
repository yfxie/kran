---
title: 快速開始
description: 從 kran init 到第一次部署，包含模板要怎麼接上 image 變數。
---

# 快速開始

以下假設專案已經有一個 krane 模板目錄。還沒有的話，先看
[krane 模板]({{ '/zh-tw/templates/' | relative_url }})。

## 1. 產生設定檔

```console
$ cd ~/code/storefront
$ kran init
Created config/kran.yml
```

## 2. 填好設定

以一個叫 `storefront` 的 Rails 應用為例，部署到 `prod-east` 叢集上同名的 namespace：

```yaml
image: acme/storefront

registry:
  server: ghcr.io

builder:
  arch: amd64

kubernetes:
  # 選填；不設就用 KUBECONFIG，再退回 ~/.kube/config。
  # kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront

krane:
  templates: config/deploy

app:
  selector: app=storefront

aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
```

必填的是 `image`、`kubernetes.context`、`kubernetes.namespace` 和 `app.selector`，其餘都有預設值。
逐欄說明見[設定檔]({{ '/zh-tw/configuration/' | relative_url }})。

推送用的是這台機器上 `docker` 已有的登入。要改由 kran 登入，就設 `registry.username` 和
`registry.password`；這個檔案是 ERB，密碼可以來自環境變數、密碼管理器，或 krane 的
`secrets.ejson`，見[機密資料]({{ '/zh-tw/secrets/' | relative_url }})。

## 3. 讓模板用上 image

kran 負責建置和推送 image，但 pod 究竟跑哪個 image，決定權在模板。把容器指向 kran 傳給
`krane render` 的 `image`：

```erb
spec:
  containers:
    - name: web
      image: <%= image %>
```

> **這件事沒有任何機制會幫你檢查。** 少了這一行，部署一樣會成功，pod 也一樣跑模板裡原本寫死的
> image。kran 不會失敗，也不會提出警告。
{: .callout .danger }

模板裡原本就在用的 `current_sha` 一樣有效：它只有 tag，`image` 則是完整位址。見
[krane 模板]({{ '/zh-tw/templates/' | relative_url }})。

第一次部署還需要三件事：

* namespace 必須已經存在於叢集上，krane 會檢查，不存在就停下來。
* 有 `config/deploy/secrets.ejson` 的話，該 namespace 裡要有 `ejson-keys` Secret，krane 才解得開，見[機密資料]({{ '/zh-tw/secrets/' | relative_url }}#the-ejson-keys-secret)。
* `kran version` 可以確認 docker、krane、kubectl 都找得到。

## 4. 先看看會執行什麼

```console
# --dry-run 什麼都不執行，也不需要裝 docker、krane、kubectl
$ kran deploy --dry-run
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

## 5. 部署

```console
$ kran deploy
```

遇到第一個失敗的指令就停。tag 是目前的 git sha；工作目錄有未 commit 的變更時，會是該 sha 加上
`_uncommitted_` 後綴，詳見 [Image tag]({{ '/zh-tw/image-tags/' | relative_url }})。

```console
# 直接部署 registry 上已有的 image
$ kran deploy -P
# 部署指定的 tag
$ kran deploy --version v2.4.0
```

## 接下來

```sh
kran logs -f
kran details
kran console
```

這三個分別是對設定檔裡的 context 與 namespace 執行 `kubectl logs`、`kubectl get all -o wide` 和
`kubectl exec -it ... bin/rails console`。
