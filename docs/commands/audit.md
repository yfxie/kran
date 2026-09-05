---
title: kran audit
description: Show the rollout history of the deployments that match the app selector.
---

# kran audit

<p class="usage"><b>Usage</b><code>kran audit</code></p>

The rollout history of the deployments matching `app.selector`.

```console
$ kran audit
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront rollout history deployment -l app=storefront
deployment.apps/storefront
REVISION  CHANGE-CAUSE
12        <none>
13        <none>
14        <none>
```

Kubernetes keeps one revision per change to a Deployment's pod template. Because kran tags every
image with a git sha, each deploy of a new commit adds a revision, and re-deploying the same tag
adds none.

`CHANGE-CAUSE` is empty unless something writes the `kubernetes.io/change-cause` annotation. Neither
krane nor kran does. Set it in your Deployment template from the sha krane already provides:

```yaml
metadata:
  annotations:
    kubernetes.io/change-cause: "kran deploy <%= current_sha %>"
```

For one revision in detail:

```sh
kubectl --context prod-east --namespace storefront \
  rollout history deployment/storefront --revision=13
```

## Not an audit log

This is Kubernetes' rollout history, not a record of who ran what. For that, look at your CI logs or
the cluster's audit policy.
