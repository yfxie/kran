---
title: kran details
description: 列出 namespace 裡的所有資源，含節點與 image 欄位。
---

# kran details

<p class="usage"><b>用法</b><code>kran details</code></p>

namespace 裡正在跑的所有東西。

```console
$ kran details
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront get all -o wide
NAME                              READY   STATUS    RESTARTS   AGE     IP           NODE
pod/storefront-7d4c9f8b5c-4xk2p   1/1     Running   0          6m14s   10.42.1.37   node-a
pod/storefront-7d4c9f8b5c-r9vqt   1/1     Running   0          6m02s   10.42.2.19   node-b

NAME                 TYPE        CLUSTER-IP     PORT(S)   AGE   SELECTOR
service/storefront   ClusterIP   10.43.118.42   80/TCP    31d   app=storefront

NAME                         READY   UP-TO-DATE   AVAILABLE   AGE   IMAGES
deployment/storefront        2/2     2            2           31d   ghcr.io/acme/storefront:9c1f4d0
```

`-o wide` 幫 pod 多帶出 `NODE` 與 `IP`，幫 deployment 和 replica set 多帶出 `IMAGES`。想確認
「部署上去的 tag 就是正在跑的 tag」，看的就是 `IMAGES`。

## 不受 app.selector 限制

`kran details` 不理會 `app.selector`，整個 namespace 都列出來；用 selector 的是 `kran logs`、
`kran exec` 與 `kran audit`。

`get all` 是 kubectl 的簡寫，並不涵蓋所有資源型別。Ingress、ConfigMap、Secret 和自訂資源都不在
裡面，那些直接用 `kubectl` 查，前綴可以從 `kran deploy --dry-run` 的輸出複製。
