---
title: 別名
description: 內建的 shell 與 console，以及如何自訂常用指令的捷徑。
---

# 別名

別名就是在 `config/kran.yml` 裡替一段 kran 指令取個名字。

## 內建的 shell 與 console

```yaml
aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
```

```sh
kran shell
kran console
```

名字沿用 kamal 的習慣。

image 裡沒有 `bash` 的話：

```yaml
aliases:
  shell: exec --interactive sh
```

## 自訂別名

```yaml
aliases:
  migrate: exec bin/rails db:migrate
  routes: exec bin/rails routes
  errors: logs -g ERROR
  tail: logs -f -n 100
  psql: exec --interactive psql $DATABASE_URL
```

值就是 `kran` 後面那一段，照 shell 的斷詞規則拆開。

## 額外參數會接在後面

```console
$ kran migrate --trace --dry-run
... exec "$pod" -- bin/rails db:migrate --trace
```

## 搭配多環境使用

```sh
kran console -d staging
```

多環境設定會在別名展開之前先讀進來，所以 `config/kran.staging.yml` 可以自己加別名，或覆寫基礎檔案
裡的某一個。

## 蓋不掉內建指令

kran 先比對內建指令，比不到才去查別名表。

```console
$ kran nope
Could not find command "nope".
```

## 別名做不到的事

別名是 kran 展開的，不是 shell 展開的，所以會跟著 repository 一起分享給團隊。展開的結果必須是一行
kran 指令，`deploy && curl ...` 這種就不能當別名。
