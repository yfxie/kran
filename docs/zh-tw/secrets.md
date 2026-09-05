---
title: 機密資料
description: registry 密碼的三種來源、krane 如何處理 secrets.ejson，以及怎麼順便做出 image pull secret。
---

# 機密資料

有兩種機密資料，解密的地點不同，但可以放在同一份 `secrets.ejson` 裡。

* **registry 密碼**，`docker login` 要用的，由 kran 在你的機器上解密。
* **應用程式的機密資料**，由 krane 在叢集裡解密。

## ejson

[ejson](https://github.com/Shopify/ejson) 只加密 JSON 檔裡的值、不加密鍵，所以整份檔案可以進版控。
任何人都能用檔案裡附的公鑰新增一筆值，但只有私鑰讀得出來。以底線開頭的鍵維持明文，`_public_key`
和 `_type` 因此看得見。

```console
$ ejson keygen
Public Key:
8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c
Private Key:
b1d3f5a7c9e1b3d5f7a9c1e3b5d7f9a1c3e5b7d9f1a3c5e7b9d1f3a5c7e9b1d3
$ ejson encrypt config/deploy/secrets.ejson
Wrote 842 bytes to config/deploy/secrets.ejson
```

`ejson keygen` 會把私鑰寫進 `/opt/ejson/keys`，`ejson decrypt` 也是去那裡找；`EJSON_KEYDIR` 可以改
這個目錄。

## registry 密碼

只有要讓 kran 自己登入時才需要；不設 `registry.username` 和 `registry.password`，推送就用 `docker`
已有的登入。

可以是純字串，也可以是任何 ERB 運算式，因為這個檔案在解析成 YAML 之前會先跑 ERB：

```yaml
registry:
  password: <%= ENV["GITHUB_TOKEN"] %>
```

```yaml
registry:
  password: <%= %x(aws ecr get-login-password --region us-east-1).strip %>
```

```yaml
registry:
  password: <%= %x(op read op://deploy/ghcr/token).strip %>
```

也可以是解密後 `secrets.ejson` 裡的一條點分路徑：

```yaml
registry:
  password:
    ejson: registry.password
```

kran 會對 `krane.secrets`（預設 `config/deploy/secrets.ejson`）跑 `ejson decrypt`，再沿路徑取值，
用的是你機器上的 `ejson` 執行檔與私鑰。

```console
$ kran deploy
ERROR: registry.password not found in config/deploy/secrets.ejson

# 連檔案都沒設定時
$ kran deploy
ERROR: registry.password refers to ejson but krane.secrets is not set and config/deploy/secrets.ejson does not exist
```

## krane 怎麼讀 secrets.ejson

`secrets.ejson` 就放在模板目錄裡，跟 manifest 擺在一起：

```text
config/
├── kran.yml
└── deploy/
    ├── deployment.yaml.erb
    └── secrets.ejson
```
{: .tree }

檔名必須剛好是 `secrets.ejson`，kran 用一個獨立的 `-f` 傳進去：

```text
krane render -f config/deploy ... \
  | krane deploy storefront prod-east \
      -f config/deploy/secrets.ejson -
```

krane 只看一個頂層鍵，`kubernetes_secrets` 底下每一項都會變成一個 Secret：

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "kubernetes_secrets": {
    "rails-app": {
      "_type": "Opaque",
      "data": {
        "SECRET_KEY_BASE": "EJ[1:...]",
        "DATABASE_URL": "EJ[1:...]"
      }
    }
  }
}
```

* 項目名稱就是 Secret 的名稱。
* `_type` 原封不動寫進 Secret 的 `type` 欄位。
* `data` 底下每個值先解密，再做 base64 編碼。

```yaml
envFrom:
  - secretRef:
      name: rails-app
```

`kubernetes_secrets` 以外的鍵 krane 不理，也不會在叢集裡產生東西。

## ejson-keys Secret
{: #the-ejson-keys-secret }

krane 讀的是目標 namespace 裡一個叫 `ejson-keys` 的 Secret：每個 data 鍵是公鑰，值是對應的私鑰。

```console
$ kubectl --context prod-east --namespace storefront \
>   create secret generic ejson-keys \
>   --from-literal=8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c=<私鑰>
secret/ejson-keys created

# 沒有它的話，krane 在套用任何東西之前就會停住
$ kran deploy
Secret `ejson-keys` not found in namespace `storefront`
```

> **要用 `create`，絕對不要用 `apply`。** krane 會 prune 掉不是自己這次部署產生的資源，而帶著
> last-applied-configuration annotation 的 Secret 就會被當成那一類：它會在下次部署時被刪掉，之後
> 每次部署都解不開密。
{: .callout .danger }

## 用同一份檔案產生 image pull secret

`kubernetes.io/dockerconfigjson` 這個 Secret 型別，用單一個 `.dockerconfigjson` 鍵裝一份 docker
設定檔。

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "kubernetes_secrets": {
    "registry": {
      "_type": "kubernetes.io/dockerconfigjson",
      "data": {
        ".dockerconfigjson": "EJ[1:...]"
      }
    }
  }
}
```

被加密的那個值，是整份 docker 設定序列化成的一個 JSON 字串：

```json
{"auths":{"ghcr.io":{"username":"acme-deploy","password":"ghp_notarealtoken","auth":"YWNtZS1kZXBsb3k6Z2hwX25vdGFyZWFsdG9rZW4="}}}
```

`auth` 是 `username:password` 的 base64：

```console
$ printf '%s' 'acme-deploy:ghp_notarealtoken' | base64
YWNtZS1kZXBsb3k6Z2hwX25vdGFyZWFsdG9rZW4=
```

跑過 `ejson encrypt` 之後，krane 每次部署都會建出這個 Secret：

```yaml
spec:
  imagePullSecrets:
    - name: registry
  containers:
    - name: web
      image: <%= image %>
```

## 一組密碼兩邊共用

把密碼當成同一個 Secret 裡的普通鍵，再讓 kran 指過去：

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "kubernetes_secrets": {
    "registry": {
      "_type": "Opaque",
      "data": {
        "password": "EJ[1:...]"
      }
    }
  }
}
```

```yaml
registry:
  username: acme-deploy
  password:
    ejson: kubernetes_secrets.registry.data.password
```

kran 在本機解密拿去 `docker login`，krane 則在 namespace 裡建一個叫 `registry` 的 `Opaque` Secret。
不想要那個 Secret 的話，把這個鍵移出 `kubernetes_secrets`：

```json
{
  "_public_key": "8b0a1f5c9d3e47a2b6c8d0e2f4a6b8c0d2e4f6a8b0c2d4e6f8a0b2c4d6e8f0a2c",
  "registry": {
    "password": "EJ[1:...]"
  }
}
```

```yaml
registry:
  password:
    ejson: registry.password
```

檔案仍然是合法的 ejson，多出來的那個鍵只給 kran 用。

## 不會出現在輸出裡的資料

```console
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
```

真正的密碼是寫進 `docker login` 的標準輸入，所以不會出現在 process 列表、shell 歷史或 CI log 裡。
