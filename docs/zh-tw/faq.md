---
title: 常見問題
description: 常見錯誤訊息的成因與解法，從工具沒裝、registry 登入到 ejson-keys 與多架構建置。
---

# 常見問題

## 工具不在 PATH 上

```console
$ kran deploy
ERROR: krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
```

檢查在第一行指令之前就做完，而且會一次列出所有缺的工具。其他提示：

| 工具 | 提示 |
| --- | --- |
| `docker` | 從 `https://docs.docker.com/get-docker/` 安裝 |
| `kubectl` | 從 `https://kubernetes.io/docs/tasks/tools/` 安裝 |
| `ejson` | `gem install ejson`（krane 本來就依賴它）或 `brew install ejson` |

設成 `krane.command: bundle exec krane` 時，你看到的可能是 `bundle is not on PATH`：kran 檢查的是
它實際啟動的那支程式。`kran deploy -P` 不需要 docker，`--dry-run` 則完全跳過檢查。

## kran 推導不出 image tag

```console
$ kran deploy
ERROR: Git could not provide an image tag in /srv/build: Command failed (exit 128): git rev-parse HEAD
fatal: not a git repository (or any of the parent directories): .git
Pass --version to set the tag explicitly.
$ kran deploy --version 2024-06-01-1
```

見 [Image tag]({{ '/zh-tw/image-tags/' | relative_url }})。

## tag 為什麼多了 _uncommitted_

因為 `git status --porcelain` 有輸出。後綴是十六位隨機十六進位字元，不是雜湊。image 裡真的含有那些
變更，因為 kran 從工作目錄建置；kamal 預設不是這樣。見
[Image tag]({{ '/zh-tw/image-tags/' | relative_url }}#the-difference-from-kamal)。

## krane 不肯部署到我的 namespace
{: #krane-refuses-to-deploy-to-my-namespace }

krane 把 `default`、`kube-system`、`kube-public` 當成受保護的，換一個 namespace：

```console
$ kubectl --context prod-east create namespace storefront
namespace/storefront created
```

```yaml
kubernetes:
  context: prod-east
  namespace: storefront
```

這是 krane 的規則，kran 只是原樣把 namespace 傳過去。

## registry 密碼一定要寫進 kran.yml 嗎

不用。不設 `registry.username` 和 `registry.password`，kran 就跳過 `docker login`，推送直接用這台
機器上 `docker login` 過的帳號。只有事先沒人登入過的環境（例如 CI）才需要兩個都設。

## Secret ejson-keys not found

krane 是在叢集裡解 `secrets.ejson`，私鑰得放在那邊：

```console
$ kubectl --context prod-east --namespace storefront \
>   create secret generic ejson-keys \
>   --from-literal=<公鑰>=<私鑰>
secret/ejson-keys created
```

要用 `create` 不要用 `apply`，否則會被 krane 的 prune 刪掉。見
[機密資料]({{ '/zh-tw/secrets/' | relative_url }}#the-ejson-keys-secret)。

這跟 `registry.password: { ejson: ... }` 是兩回事，後者由 kran 在本機用 `ejson` 執行檔和
`/opt/ejson/keys/<公鑰>` 或 `EJSON_KEYDIR` 裡的金鑰解開。

## 遠端 daemon 的多架構建置失敗

設了 `builder.remote` 時，兩個平台得由同一台 daemon 建完，這需要 binfmt/QEMU 加 containerd image
store，或是每個架構各掛一個 node 的 buildx builder。

```console
$ kran build details
DOCKER_HOST=ssh://builder@build.internal docker version
DOCKER_HOST=ssh://builder@build.internal docker buildx ls
NAME/NODE       DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*        docker
 \_ default      \_ default       running   v0.19.0    linux/amd64
```

`PLATFORMS` 只列出一個架構的話，就只建一個：

```yaml
builder:
  arch: amd64
  remote: ssh://builder@build.internal
```

見[遠端 builder]({{ '/zh-tw/remote-builder/' | relative_url }}#multi-arch-on-a-remote-daemon)。

## exec 的旗標被 kran 吃掉

在指令前面補一個單獨的 `--`，否則 `-e` 會被當成 kran 的選項：

```sh
kran exec -- bin/rails runner -e production 'puts Rails.env'
```

## 沒有符合 selector 的執行中 pod

```console
$ kran exec bin/rails db:migrate
No running pod matches app=storefront
```

`kran exec` 需要一個符合 `app.selector` 且階段是 `Running` 的 pod。先確認 krane 模板裡的 label 跟
selector 對得上（`kran details` 會列出 pod），再確認它們真的在執行。沒在執行的 pod，`kran logs`
還是讀得到。

## kran logs 幾乎沒東西

不給 `-n` 時，用了 selector 的 kubectl 每個 pod 只顯示最後 10 行。

```sh
kran logs -n 500
kran logs --since 1h
```

## 在 bundle exec 底下跑 kran
{: #running-kran-under-bundle-exec }

kran 在 `Bundler.with_unbundled_env` 裡執行每個外部指令，所以 krane、ejson、docker、kubectl、git
啟動前，`RUBYOPT` 和 `BUNDLE_GEMFILE` 都已經被拿掉，否則 krane 會跑去對 kran 的 Gemfile 解相依。

所以 krane 裝在全域時 `bundle exec kran deploy` 可用；krane 在另一個 bundle 裡時，只要指明也可用：

```yaml
krane:
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```

你自己 export 的環境變數不受影響。用 `kran version` 確認。

## 可以只看指令、不實際執行嗎

```sh
kran deploy --dry-run
kran build push --dry-run
kran logs --dry-run
```

`--dry-run` 每個指令都支援，而且不會印出密碼。

## kran 會改到我目前的 kubectl context 嗎

不會。它在每個 kubectl 指令上帶 `--context` 與 `--namespace`；有設 `kubernetes.kubeconfig` 時再加上
`KUBECONFIG=` 前綴。

## 用另一個 gcloud 或 AWS 帳號部署

docker 的 credential helper 與 kubectl 的 auth plugin 都從環境變數讀帳號：Artifact Registry 與 GKE 看
`CLOUDSDK_ACTIVE_CONFIG_NAME`，ECR 與 EKS 看 `AWS_PROFILE`。寫進 `env`，每個 docker、krane 與 kubectl
指令都會帶上，不用每次在命令列前面加：

```yaml
env:
  CLOUDSDK_ACTIVE_CONFIG_NAME: acme
```

見 [env]({{ '/zh-tw/configuration/' | relative_url }}#env)。

## 還可以直接用 krane 和 kubectl 嗎

可以。從 `kran deploy --dry-run` 把前綴複製走：

```sh
KUBECONFIG=/home/dana/.kube/prod-east.yml \
  kubectl --context prod-east --namespace storefront get ingress
```

kran 不存狀態，也不裝任何 hook。
