---
title: 設定檔
description: config/kran.yml 每個欄位的意義、預設值，以及 ERB 與多環境的用法。
---

# 設定檔

設定讀自 `config/kran.yml`。

## kran init 產生的檔案

```yaml
# Name of the container image, without registry and tag.
# The tag comes from `kran deploy --version`, or from git HEAD when omitted.
image: my-user/my-app

# Where the image is pushed. Leave username and password out to reuse the login docker already
# has on this machine; set both, in CI for example, and `docker login` runs before every push.
registry:
  # Leave empty for Docker Hub.
  server: ghcr.io
  # username: my-user
  # This file is ERB, so the password can come from the environment or any Ruby expression.
  # password: <%= ENV["KRAN_REGISTRY_PASSWORD"] %>
  # Or read it from krane's secrets.ejson (a dotted path from the top of the decrypted file):
  # password:
  #   ejson: registry.password

# How the image is built.
builder:
  # One or more of amd64, arm64. Becomes `docker build --platform linux/<arch>[,linux/<arch>]`.
  arch: amd64
  # Build on another Docker host over SSH. Sets DOCKER_HOST for `docker login` and `docker build`.
  # remote: ssh://user@builder.example.com
  # Build context. Defaults to the current directory, so uncommitted changes are included.
  # context: .

# Cluster and namespace that every command targets.
kubernetes:
  # Defaults to the KUBECONFIG environment variable, then ~/.kube/config.
  # kubeconfig: ~/.kube/my-cluster.yml
  context: my-cluster
  namespace: my-app

# How krane is invoked.
krane:
  # Directory of krane templates, passed to `krane render -f`.
  templates: config/deploy
  # ejson file passed to `krane deploy -f`. Defaults to <templates>/secrets.ejson when it exists.
  # secrets: config/deploy/secrets.ejson
  # Command used to run krane. Override when krane lives in a Gemfile.
  # command: bundle exec krane

# Pods used by logs and exec.
app:
  # Label selector for the application pods (kubectl -l).
  selector: app=my-app
  # Container inside the pod (kubectl -c). Defaults to the pod's default container.
  # container: web

# Shortcuts run with `kran <alias>`. Extra arguments are appended to the command.
aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
```

## image

必填。image 的 repository 名稱，不含 registry 主機也不含 tag。

完整位址是 `<registry.server>/<image>:<tag>`。`server` 留空就不帶主機，那正是 Docker Hub 要的格式。
tag 不會來自這個檔案，見 [Image tag]({{ '/zh-tw/image-tags/' | relative_url }})。

## registry

| 欄位 | 必填 | 預設 | 作用 |
| --- | --- | --- | --- |
| `server` | 否 | 無（Docker Hub） | `docker login` 的第一個參數，也是 image 位址裡的主機 |
| `username` | 否 | 無 | `docker login -u <username>` |
| `password` | 否 | 無 | 經標準輸入寫給 `docker login --password-stdin` |

```yaml
registry:
  server: ghcr.io
  username: acme-deploy
  password: <%= ENV["GITHUB_TOKEN"] %>
```

`username` 和 `password` 要一起設。兩個都不設就不跑 `docker login`，推送直接用這台機器上已經
`docker login` 過的帳號；兩個都設（例如在 CI 上）就由 kran 在每次推送前登入。

密碼不會出現在命令列上。可以寫成純字串、ERB 運算式，或是指向 krane 加密機密檔的一條點分路徑。
三種寫法都在[機密資料]({{ '/zh-tw/secrets/' | relative_url }})。

## builder

| 欄位 | 必填 | 預設 | 作用 |
| --- | --- | --- | --- |
| `arch` | 否 | 無 | `docker build --platform linux/<arch>[,linux/<arch>]` |
| `remote` | 否 | 無 | 在 `docker login` 與 `docker build` 前面加上 `DOCKER_HOST=<url>` |
| `context` | 否 | `.` | `docker build` 的最後一個參數 |

```yaml
builder:
  arch: amd64            # 也可以寫成 [amd64, arm64]
  remote: ssh://builder@build.internal
```

不寫 `arch` 就不會帶 `--platform`。換一台機器建置的細節在
[遠端 builder]({{ '/zh-tw/remote-builder/' | relative_url }})；`context` 為什麼預設是工作目錄，
則在 [Image tag]({{ '/zh-tw/image-tags/' | relative_url }})。

## kubernetes

| 欄位 | 必填 | 預設 | 作用 |
| --- | --- | --- | --- |
| `kubeconfig` | 否 | `KUBECONFIG`，再來 `~/.kube/config` | 在每個 krane 與 kubectl 指令前加上 `KUBECONFIG=<路徑>` |
| `context` | 是 | — | `kubectl --context <context>`，以及 `krane deploy` 的第二個位置參數 |
| `namespace` | 是 | — | `kubectl --namespace <namespace>`，以及 `krane deploy` 的第一個位置參數 |

```yaml
kubernetes:
  kubeconfig: ~/.kube/prod-east.yml
  context: prod-east
  namespace: storefront
```

`kubeconfig` 會做路徑展開，所以 `~` 可以用；設了它，kran 就不受你上次選了哪個 context 影響，也不會
去動它。krane 要的參數順序是 `krane deploy <namespace> <context>`，kran 會自動填好。

## krane

| 欄位 | 必填 | 預設 | 作用 |
| --- | --- | --- | --- |
| `templates` | 否 | `config/deploy` | `krane render -f <templates>` |
| `secrets` | 否 | `<templates>/secrets.ejson`（該檔存在時） | `krane deploy -f <secrets>` |
| `command` | 否 | `krane` | 執行 `render`、`deploy`、`version` 用的程式 |

```yaml
krane:
  templates: config/deploy
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```

`templates` 是放 krane manifest 的目錄，見
[krane 模板]({{ '/zh-tw/templates/' | relative_url }})。`secrets` 檔名必須剛好是 `secrets.ejson`，
放在 `templates` 底下就會被自動帶上，見[機密資料]({{ '/zh-tw/secrets/' | relative_url }})。
`command` 是一段 shell 前綴，可以夾帶環境變數。

## app

| 欄位 | 必填 | 預設 | 作用 |
| --- | --- | --- | --- |
| `selector` | 是 | — | `logs`、`exec`、`audit` 的 `kubectl -l <selector>` |
| `container` | 否 | pod 的預設容器 | `kubectl -c <container>` |

```yaml
app:
  selector: app=storefront
  container: web
```

> `selector` 必須和 krane 模板加在應用程式 pod 上的 label 對得起來。沒有機制會替你檢查，對不上的
> 症狀就是 `kran logs` 什麼都撈不到。
{: .callout .warning }

## aliases

把名字對到一段 kran 指令，命令列上額外給的參數會接在後面。

```yaml
aliases:
  migrate: exec bin/rails db:migrate
  routes: exec bin/rails routes
  errors: logs -g ERROR
```

`kran migrate --trace` 會跑 `kran exec bin/rails db:migrate --trace`。別名蓋不掉內建指令，見
[別名]({{ '/zh-tw/aliases/' | relative_url }})。

## ERB

整份檔案先跑 ERB，再交給 YAML 解析：

```yaml
registry:
  password: <%= ENV.fetch("GITHUB_TOKEN") %>

kubernetes:
  namespace: storefront-<%= ENV.fetch("USER") %>
```

kran 提供一個變數 `destination`，也就是 `-d` 給的值，沒給就是 `nil`。運算式產生出來的縮排，跟你
手打的縮排一樣要算數。

## 多環境

`-d NAME` 會把 `config/kran.NAME.yml` 深層合併到 `config/kran.yml` 上。

```sh
kran deploy -d staging
```

合併規則和「哪些設定該寫在哪一份」都在[多環境]({{ '/zh-tw/destinations/' | relative_url }})。

## 欄位缺漏時

```console
$ kran deploy
ERROR: Missing kubernetes.context in config/kran.yml

# 連設定檔都沒有時
$ kran deploy
ERROR: Configuration file not found in config/kran.yml (run `kran init` to create one)
```
