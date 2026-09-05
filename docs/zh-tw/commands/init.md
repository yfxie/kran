---
title: kran init
description: 產生 config/kran.yml，已存在的檔案不會被覆蓋。
---

# kran init

<p class="usage"><b>用法</b><code>kran init</code></p>

把內建模板複製成 `config/kran.yml`，必要時一併建立 `config/` 目錄。

```console
$ kran init
Created config/kran.yml

# 檔案已經在了就不動它
$ kran init
config/kran.yml already exists (remove it first to create a new one)
```

寫出來的就是[設定檔]({{ '/zh-tw/configuration/' | relative_url }})那頁列出的完整註解版模板。

## 多環境

`kran init` 只產生基礎檔案。多環境的檔案（例如 `config/kran.staging.yml`）是你自己寫的部分覆寫，
見[多環境]({{ '/zh-tw/destinations/' | relative_url }})。
