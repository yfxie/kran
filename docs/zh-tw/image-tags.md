---
title: Image tag
description: image tag 怎麼決定、_uncommitted_ 後綴代表什麼，以及和 kamal 的差異。
---

# Image tag

| 情況 | tag |
| --- | --- |
| 有給 `--version TAG` | 就用 `TAG`，原樣不動 |
| 工作目錄乾淨 | `git rev-parse HEAD` |
| 有未 commit 的變更 | `<sha>_uncommitted_<16 位隨機十六進位>` |

```text
ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2
ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2_uncommitted_4b81d0e6a37f92c5
ghcr.io/acme/storefront:v2.4.0
```

一次部署會用到這個 tag 三次：docker tag、krane 的 `--current-sha`、以及 `image` binding，所以三者
不可能對不起來。

## uncommitted 後綴

只要 `git status --porcelain` 有輸出，工作目錄就算不乾淨，kran 會補上 `_uncommitted_` 和十六位隨機
十六進位字元。

> **後綴是隨機值，不是內容雜湊。** 同一個不乾淨的工作目錄建置兩次，會得到兩個不同的 tag。這保證
> 同一個 tag 不會對應到不同內容，而不是拿來去重的。kamal 也是這樣做。
{: .callout .note }

內容雜湊得先定義什麼算內容 — 追蹤的檔案、未追蹤的檔案、檔案權限、submodule — 只要判斷錯一次就會
重用到 tag。

帶 `_uncommitted_` 的 tag 用完就丟：沒有任何 commit 重現得出它。

## 跟 kamal 的差別
{: #the-difference-from-kamal }

kamal 預設不會把未 commit 的變更建進去。它從乾淨的 clone 建置，只是仍然補上 `_uncommitted_` 後綴，
提醒你這個 *tag* 跟當下的工作目錄對不起來。只有設了 `builder.context`，kamal 才改從工作目錄建置。

kran 一律從工作目錄建置，因為 `builder.context` 預設就是 `.`。

一個標著 `_uncommitted_`、內容卻只有已 commit 程式碼的 tag，誤導的方向更危險：你以為改動上去了，
其實沒有。想要 kamal 的行為就先 commit，工作目錄乾淨的話兩邊產出的都是純 sha 的 tag。

## 不在 git repository 裡

```console
# repository 還沒有任何 commit 時也是同樣的訊息
$ kran deploy
ERROR: Git could not provide an image tag in /srv/build: Command failed (exit 128): git rev-parse HEAD
fatal: not a git repository (or any of the parent directories): .git
Pass --version to set the tag explicitly.
$ kran deploy --version 2024-06-01-1
```

## 在 CI 裡

CI 的 checkout 是乾淨的，推導出來就是 commit sha。checkout 是 shallow 或 detached 時，明確指定
比較保險：

```sh
kran build push --version "$GITHUB_SHA"
kran deploy --version "$GITHUB_SHA" -P
```

建置一次、同一個 tag 部署到多個環境：

```sh
kran deploy --version "$GITHUB_SHA" -P -d staging
kran deploy --version "$GITHUB_SHA" -P
```

## 在模板裡怎麼用

```erb
image: <%= image %>            # ghcr.io/acme/storefront:9c1f4d0...
labels:
  app.kubernetes.io/version: <%= current_sha %>
```

`image` 是完整位址，`current_sha` 只有 tag。見
[krane 模板]({{ '/zh-tw/templates/' | relative_url }})。
