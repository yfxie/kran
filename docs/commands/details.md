---
title: kran details
description: List every resource in the configured namespace, with node and image columns.
---

# kran details

<p class="usage"><b>Usage</b><code>kran details</code></p>

Everything running in the namespace.

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

`-o wide` adds `NODE` and `IP` for pods and `IMAGES` for deployments and replica sets. The `IMAGES`
column confirms that the tag you deployed is the tag that is running.

## Not filtered by the selector

`kran details` ignores `app.selector` and shows the whole namespace. `kran logs`, `kran exec` and
`kran audit` use the selector.

`get all` is a kubectl shorthand and does not cover every resource type. Ingresses, ConfigMaps,
Secrets and custom resources are not in it; use `kubectl` for those, reusing the prefix from
`kran deploy --dry-run`.
