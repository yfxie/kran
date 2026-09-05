---
title: kran exec
description: 在正在執行的應用 pod 裡執行指令，可互動也可不互動。
---

# kran exec

<p class="usage"><b>用法</b><code>kran exec [-i|--interactive] [--] COMMAND...</code></p>

挑一個符合 `app.selector` 且正在執行的 pod，在裡面跑指令。

## 選項

| 選項 | 說明 |
| --- | --- |
| `-i`、`--interactive` | 配一個終端機（`kubectl exec -it`） |
| `-d NAME` | 把 `config/kran.NAME.yml` 疊到 `config/kran.yml` 上 |
| `--dry-run` | 只印出指令，不執行 |
{: .opts }

## 實際執行的指令

```console
$ kran exec bin/rails db:migrate --dry-run
pod=$(KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront get pods -l app=storefront --field-selector status.phase=Running -o 'jsonpath={.items[0].metadata.name}') && test -n "$pod" || { echo 'No running pod matches app=storefront' >&2; exit 1; }
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront exec "$pod" -- bin/rails db:migrate
```

第一行是去問 API 要「第一個符合 selector 且階段是 `Running` 的 pod」，因為 `Pending`、
`Terminating`、`CrashLoopBackOff` 的 pod 沒辦法接受 exec。

加上 `-i` 時第二行會變成 `kubectl exec -it "$pod" -- ...`；設了 `app.container` 則會多出
`-c <container>`。

## 指令本身帶旗標時

```console
$ kran exec -- bin/rails runner -e production 'puts Rails.env' --dry-run
... exec "$pod" -- bin/rails runner -e production 'puts Rails.env'
```

> **指令自己有旗標時，前面補一個單獨的 `--`。** kran 會先解析自己的選項，少了 `--`，`-e` 就會被
> 當成 kran 的選項而被拒絕。
{: .callout .warning }

```console
$ kran exec
ERROR: exec needs a command to run, for example `kran exec bin/rails db:migrate`
$ kran exec bin/rails db:migrate
No running pod matches app=storefront
```

## 會選到哪一個 pod

API 回傳的第一個符合條件的 pod，沒有排序保證。要指定特定 pod 的話，從 `kran details` 拿名稱，
再直接用 `kubectl exec`。

## shell 與 console

模板裡的兩個別名就是一般的 `kran exec`，分別展開成 `exec --interactive bash` 與
`exec --interactive bin/rails console`。見[別名]({{ '/zh-tw/aliases/' | relative_url }})。
