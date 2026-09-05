---
title: 安裝
description: 用 gem 安裝 kran，或加進專案的 Gemfile，並確認它能正常運作。
---

# 安裝

```console
$ gem install kran
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    krane 3.7.3
kubectl  Client Version: v1.32.1
```

## 放進 Gemfile

想在各專案分別鎖版本，就放進應用程式不會載入的 group：

```ruby
group :deploy, optional: true do
  gem "kran"
end
```

```console
$ bundle install --with deploy
$ bundle exec kran version
kran     1.0.0
```

kran 呼叫外部指令時都包在 `Bundler.with_unbundled_env` 裡，所以 `bundle exec kran` 照樣能驅動裝在
別的 Gemfile 或全域的 krane。詳情見
[在 bundle exec 底下跑 kran]({{ '/zh-tw/faq/#running-kran-under-bundle-exec' | relative_url }})。

## kran 不會幫你裝的工具

kran 會呼叫 `docker`、`krane`、`kubectl`；當 registry 密碼要從 krane 的加密機密檔讀取時，還會用到
`ejson`。這些都不是 gem 依賴。

krane 之所以刻意排除，是因為它會連帶安裝大量 Kubernetes client 相依套件，而多數專案本來就在自己的
部署 bundle 裡鎖好版本了。

每個指令動手之前都會先確認需要的工具在不在：

```console
$ kran deploy
ERROR: krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
```

各工具怎麼裝，見[前置條件]({{ '/zh-tw/prerequisites/' | relative_url }})。
