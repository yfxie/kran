---
title: kran deploy
description: 一行指令完成建置、推送、render 模板與部署。
---

# kran deploy

<p class="usage"><b>用法</b><code>kran deploy [--version TAG] [-P|--skip-push]</code></p>

建置並推送 image，然後 render krane 模板並部署。

執行順序：

1. 確認 `docker`（有 `-P` 時略過）、`krane.command` 背後的執行檔、`kubectl` 都在 PATH 上。
2. 決定 tag：有 `--version` 就用它，否則取 `git rev-parse HEAD`；工作目錄不乾淨時加上
   `_uncommitted_` 後綴。
3. 有設 `registry.username` 和 `registry.password` 時跑 `docker login`，密碼走標準輸入。
4. `docker build --platform ... --push`，打上 `<server>/<image>:<tag>`。
5. `krane render | krane deploy`，tag 以 `--current-sha` 傳入，完整 image 位址以
   `--bindings image=...` 傳入。

第 3、4 步在有 `-P` 時會略過。

## 選項

| 選項 | 說明 |
| --- | --- |
| `--version TAG` | 直接指定 tag，不從 git 推導 |
| `-P`、`--skip-push` | 略過登入、建置與推送 |
| `-d NAME` | 把 `config/kran.NAME.yml` 疊到 `config/kran.yml` 上 |
| `--dry-run` | 只印出指令，一行都不執行 |
{: .opts }

## 實際執行的指令

```console
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | KUBECONFIG=/home/dana/.kube/prod-east.yml krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

第三行拆開來看：

* `krane render -f config/deploy` 把那個目錄裡每個模板的 ERB 求值，輸出純 YAML。
* `--current-sha` 與 `--bindings image=...` 會成為模板裡的區域變數，所以 Deployment 可以直接寫
  `image: <%= image %>`。見 [krane 模板]({{ '/zh-tw/templates/' | relative_url }})。
* `krane deploy storefront prod-east` 是 namespace 在前、context 在後。
* `-f config/deploy/secrets.ejson -` 先傳入加密機密檔，`-` 再從管線讀 render 好的 YAML。兩者共用
  同一個 `-f`，因為 krane 只認最後一個 `-f`。見[機密資料]({{ '/zh-tw/secrets/' | relative_url }})。

> **`krane deploy` 不會處理 ERB。** 這就是 kran 把 `krane render` 用管線接給它、而不是直接叫
> `krane deploy` 讀模板目錄的原因。
{: .callout .note }

```console
# 有設定 builder.remote 時，兩行 docker 指令都會加上前綴
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | DOCKER_HOST=ssh://builder@build.internal docker login ghcr.io -u acme-deploy --password-stdin
DOCKER_HOST=ssh://builder@build.internal docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
```

## --dry-run

印出整串指令，什麼都不執行，也不需要裝 docker、krane、kubectl。前面的
`printf '%s' '[REDACTED]' |` 表示密碼是從標準輸入送進 `docker login`，不會出現在命令列上。

## -P、--skip-push

```console
# 只跑 krane 那條管線，連 docker 都不需要
$ kran deploy -P --dry-run
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | KUBECONFIG=/home/dana/.kube/prod-east.yml krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

適合用來重新套用模板，或搭配 `--version` 把某個已知的 image 換到別的環境：

```sh
kran deploy --version 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 -P -d staging
```

回退也是走這條路：krane 部署的是期望狀態，所以回退就是把前一個 tag 部署上去。

## --version

直接指定 tag。不在 git repository 裡時，這是唯一能部署的辦法：

```console
$ kran deploy
ERROR: Git could not provide an image tag in /srv/build: Command failed (exit 128): git rev-parse HEAD
fatal: not a git repository (or any of the parent directories): .git
Pass --version to set the tag explicitly.
$ kran deploy --version v2.4.0
```

## 工具沒安裝時

```console
$ kran deploy
ERROR: krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
```

設成 `krane.command: bundle exec krane` 時，檢查的對象是 `bundle`，因為那才是 kran 實際啟動的程式。
