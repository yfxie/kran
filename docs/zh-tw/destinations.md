---
title: 多環境
description: 用 -d 搭配一份只寫差異的設定檔，把同一個專案部署到不同環境。
---

# 多環境

`-d NAME` 會把 `config/kran.NAME.yml` 疊到 `config/kran.yml` 上。

```text
config/
├── kran.yml
├── kran.staging.yml
└── kran.eu.yml
```
{: .tree }

`config/kran.yml` 一定會讀。加上 `-d staging` 就把 `config/kran.staging.yml` 疊上去，`-d eu` 則是
疊 `config/kran.eu.yml`。

```sh
kran deploy -d staging
kran logs -d staging -f
kran console -d staging
```

不給 `-d` 就只讀 `config/kran.yml`。

## 兩個檔案

基礎檔案寫共通的設定：

```yaml
# config/kran.yml
image: acme/storefront

registry:
  server: ghcr.io
  username: acme-deploy
  password: <%= ENV["GITHUB_TOKEN"] %>

builder:
  arch: amd64

kubernetes:
  kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront

app:
  selector: app=storefront
```

多環境檔案只寫不一樣的部分：

```yaml
# config/kran.staging.yml
kubernetes:
  kubeconfig: ~/.kube/stage-eu.yml
  context: stage-eu
  namespace: storefront-staging

app:
  selector: app=storefront-staging
```

```console
# image 和 registry 沿用基礎檔案，叢集和 namespace 被換掉
$ kran deploy -d staging --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | KUBECONFIG=/home/dana/.kube/stage-eu.yml krane deploy storefront-staging stage-eu -f config/deploy/secrets.ejson -
```

## 合併規則

* 兩邊都有的鍵，多環境檔案贏。
* 只有基礎檔案有的鍵，保留。
* 巢狀 hash 逐鍵合併。
* 陣列整個換掉，不會串接。

```yaml
# config/kran.yml
builder:
  arch: [amd64, arm64]
```

```yaml
# config/kran.staging.yml
builder:
  arch: [amd64]
```

staging 只會建 `linux/amd64`。

## ERB 裡的 destination

`destination` 是 `-d` 給的名稱，沒給就是 `nil`。

```yaml
# config/kran.yml
kubernetes:
  namespace: <%= destination ? "storefront-#{destination}" : "storefront" %>

app:
  selector: app=<%= ["storefront", destination].compact.join("-") %>
```

即使這樣寫，`-d NAME` 還是要求 `config/kran.NAME.yml` 存在，空檔案就夠：

```sh
: > config/kran.staging.yml
```

## 檔案必須存在

```console
$ kran deploy -d production
ERROR: Configuration file not found in config/kran.production.yml
```

環境名稱打錯是該停下來的錯，所以 kran 不會默默退回基礎檔案。

## 該寫在哪一份

屬於專案的寫基礎檔案：`image`、registry、模板目錄、krane 的執行方式、別名。屬於環境的寫多環境
檔案：kubeconfig、context、namespace、selector，有時候還有架構。

staging 要推到別的 registry 的話，整個區塊覆寫：

```yaml
# config/kran.staging.yml
registry:
  server: registry.internal
  username: ci
  password: <%= ENV["INTERNAL_REGISTRY_TOKEN"] %>
```

`registry` 是 hash，逐鍵合併，所以少寫 `username` 就會沿用基礎檔案的 `acme-deploy`。

## 別名

別名是合併之後才讀的，所以多環境檔案可以加或換掉其中一個：

```yaml
# config/kran.staging.yml
aliases:
  console: exec --interactive bin/rails console --sandbox
```

## 同一份 image 部署到多個環境

```sh
kran build push --version "$GITHUB_SHA"
kran deploy --version "$GITHUB_SHA" -P -d staging
kran deploy --version "$GITHUB_SHA" -P
```

`-P` 會略過建置與推送，所以後兩行部署的正是第一行產生的那份 image。
