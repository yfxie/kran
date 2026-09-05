---
title: krane 模板
description: krane 會 render 什麼、kran 傳進去哪些變數，以及 secrets.ejson 的位置。
---

# krane 模板

> **這一頁講的是 krane，不是 kran。** 這裡整理 kran 會用到的 krane 功能，但這些都不屬於 kran，
> 實際行為以 krane 自己的文件為準：見 [krane README](https://github.com/Shopify/krane#readme)。
{: .callout .warning }

kran 不寫 manifest，它 render 的是你本來就有的 krane 模板。

## 模板目錄

`krane.templates` 是一個目錄，預設 `config/deploy`。krane 會 render 裡面所有結尾是 `.yml`、
`.yaml`、`.yml.erb`、`.yaml.erb` 的檔案，套用順序由它依資源種類自行決定。

```text
config/
├── kran.yml
└── deploy/
    ├── deployment.yaml.erb
    ├── service.yaml
    ├── ingress.yaml.erb
    ├── secrets.ejson
    └── partials/
        └── container.yaml.erb
```
{: .tree }

## 先 render，再 deploy

```sh
krane render -f config/deploy --current-sha 9c1f4d0 \
  --bindings image=ghcr.io/acme/storefront:9c1f4d0
```

把純 YAML 寫到標準輸出，而

```sh
krane deploy storefront prod-east -f -
```

套用的是已經沒有 ERB 的 YAML。`krane deploy` 不處理 ERB，所以 kran 才用管線加 `-f -` 把兩者串起來。

## kran 傳進去的變數

每個 `--bindings key=value` 都會變成模板裡的區域變數，`--current-sha` 則會變成 `current_sha`。

| 變數 | 值 |
| --- | --- |
| `image` | 完整位址 `ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2` |
| `current_sha` | 只有 tag `9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2` |
| `deployment_id` | krane 每次部署產生的短隨機字串 |

```erb
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storefront
  labels:
    app: storefront
    app.kubernetes.io/version: <%= current_sha %>
spec:
  replicas: 2
  selector:
    matchLabels:
      app: storefront
  template:
    metadata:
      labels:
        app: storefront
    spec:
      imagePullSecrets:
        - name: registry
      containers:
        - name: web
          image: <%= image %>
          envFrom:
            - secretRef:
                name: rails-app
```

這裡 pod 的 label，必須和 `app.selector: app=storefront` 對得起來。沒有機制會替你檢查，所以
`kran logs` 撈不到東西時，先回頭看這裡。

`current_sha` 跟 `image` 裡的 tag 是同一個字串，拿來當版本 label 就好，不要自己拼 image 位址。

## partial

放在模板目錄底下、或上一層的 `partials/` 目錄裡，用 locals 呼叫：

```erb
spec:
  template:
    spec:
      containers:
        <%= partial "container", name: "web", command: ["bin/rails", "server"] %>
```

```erb
<%# config/deploy/partials/container.yaml.erb %>
- name: <%= name %>
  image: <%= image %>
  command: <%= command.inspect %>
  envFrom:
    - secretRef:
        name: rails-app
```

命令列傳進來的 binding 在 partial 裡也看得到，所以 `image` 不必再當成 local 傳一次。

## secrets.ejson

`secrets.ejson` 放在模板目錄裡，但它不是模板。krane 靠檔名認出它，而且要單獨用一個 `-f` 傳進去；
`<templates>/secrets.ejson` 存在時 kran 會自動帶上，放別的位置就設 `krane.secrets`。見
[機密資料]({{ '/zh-tw/secrets/' | relative_url }})。

## 手動 render

```console
$ krane render -f config/deploy --current-sha 9c1f4d0 \
>   --bindings image=ghcr.io/acme/storefront:9c1f4d0
apiVersion: apps/v1
kind: Deployment
metadata:
  name: storefront
...
```

`kran deploy --dry-run` 會印出完整的 `krane render` 指令，複製過來就能用。

## 受保護的 namespace

> 除非明確給權限，krane 不會部署到 `default`、`kube-system`、`kube-public`。請給應用程式一個獨立的
> namespace。見[常見問題]({{ '/zh-tw/faq/#krane-refuses-to-deploy-to-my-namespace' | relative_url }})。
{: .callout .warning }
