---
title: kran audit
description: 查看應用程式 deployment 的 rollout 歷史。
---

# kran audit

<p class="usage"><b>用法</b><code>kran audit</code></p>

符合 `app.selector` 的 deployment 的 rollout 歷史。

```console
$ kran audit
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront rollout history deployment -l app=storefront
deployment.apps/storefront
REVISION  CHANGE-CAUSE
12        <none>
13        <none>
14        <none>
```

Deployment 的 pod template 每改一次，Kubernetes 就留一個 revision。kran 用 git sha 當 tag，所以每
部署一個新 commit 就多一筆，重複部署同一個 tag 則不會多。

除非有東西寫入 `kubernetes.io/change-cause` annotation，否則 `CHANGE-CAUSE` 是空的；krane 和 kran
都不會寫。想讓它有內容，就在 Deployment 模板裡拿 krane 已經給的 sha 自己填：

```yaml
metadata:
  annotations:
    kubernetes.io/change-cause: "kran deploy <%= current_sha %>"
```

想細看某一個 revision：

```sh
kubectl --context prod-east --namespace storefront \
  rollout history deployment/storefront --revision=13
```

## 它不是稽核紀錄

這是 Kubernetes 自己的 rollout 歷史，不是「誰跑了什麼」的紀錄。那種資訊要看 CI log 或叢集的
audit policy。
