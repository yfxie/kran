---
title: kran version
description: 一次列出 kran 與各項外部工具的版本，缺少或異常都只回報不中斷。
---

# kran version

<p class="usage"><b>用法</b><code>kran version</code></p>

kran 自己與它會用到的每個工具的版本。

```console
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    krane 3.7.3
kubectl  Client Version: v1.32.1

# 缺少或異常的工具只會被列出來，不會中斷指令
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    failed: Could not locate Gemfile (Bundler::GemfileNotFound)
kubectl  not found
```

它跑的是 `docker --version`、`krane version`、`kubectl version --client`，每個只留第一行。
`failed:` 後面是該工具 standard error 的第一行。

## 沒有設定檔也能執行

`kran version` 是唯一不需要 `config/kran.yml` 的指令。

有設定檔時，krane 那行會照 `krane.command` 執行，所以這也是確認 `bundle exec krane` 設定能不能
解出來的最快方式：

```yaml
krane:
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```
