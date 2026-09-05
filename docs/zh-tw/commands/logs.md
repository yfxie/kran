---
title: kran logs
description: 一次看完所有應用 pod 的 log，支援即時追蹤、行數、時間範圍與關鍵字過濾。
---

# kran logs

<p class="usage"><b>用法</b><code>kran logs [-f] [-n N] [-s DURATION] [-g PATTERN]</code></p>

對所有符合 `app.selector` 的 pod 執行 `kubectl logs`。

## 選項

| 選項 | 說明 |
| --- | --- |
| `-f`、`--follow` | 持續輸出新的行 |
| `-n N`、`--lines N` | 每個 pod 顯示最後 `N` 行（`--tail`） |
| `-s X`、`--since X` | 只顯示比 `X` 新的行，例如 `10m` 或 `1h` |
| `-g P`、`--grep P` | 把輸出接給 `grep P` |
| `-d NAME` | 把 `config/kran.NAME.yml` 疊到 `config/kran.yml` 上 |
| `--dry-run` | 只印出指令，不執行 |
{: .opts }

## 實際執行的指令

```console
$ kran logs --dry-run
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront logs -l app=storefront --prefix --timestamps

# 全部選項都給，順序就是 kran 接上去的順序
$ kran logs -f -n 200 --since 10m -g "ERROR" --dry-run
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront logs -l app=storefront --prefix --timestamps --tail 200 --since 10m -f | grep ERROR
```

`--prefix` 會在每行前面標上 pod 名稱，因為 selector 通常對到好幾個 pod，輸出是交錯的；
`--timestamps` 讓這種交錯看得懂。

`-g` 是 shell 管線接 `grep`，不是 kubectl 的功能，所以可以跟 `-f` 一起用。

設了 `app.container` 時，`-c <container>` 會接在 selector 後面。

## 預設顯示幾行

不給 `-n` 時，用了 selector 的 kubectl 每個 pod 只顯示最近 10 行。

```sh
kran logs -n 500
```

## 只涵蓋應用程式的 pod

`kran logs` 跟著 `app.selector` 走，所以同一個 namespace 裡的 job、sidecar deployment、一次性 pod
都不會混進來。它們的名稱可以從 `kran details` 拿到，再自己用 `kubectl` 查。
