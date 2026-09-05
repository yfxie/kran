---
title: kran exec
description: Run a command inside the first running pod that matches the app selector, interactively or not.
---

# kran exec

<p class="usage"><b>Usage</b><code>kran exec [-i|--interactive] [--] COMMAND...</code></p>

Find a running pod matching `app.selector` and run a command in it.

## Options

| Option | Meaning |
| --- | --- |
| `-i`, `--interactive` | Allocate a terminal (`kubectl exec -it`) |
| `-d NAME` | Load `config/kran.NAME.yml` over `config/kran.yml` |
| `--dry-run` | Print the command and run none of it |
{: .opts }

## The command it runs

```console
$ kran exec bin/rails db:migrate --dry-run
pod=$(KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront get pods -l app=storefront --field-selector status.phase=Running -o 'jsonpath={.items[0].metadata.name}') && test -n "$pod" || { echo 'No running pod matches app=storefront' >&2; exit 1; }
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront exec "$pod" -- bin/rails db:migrate
```

The first line asks for the first pod matching the selector that is in phase `Running`, because a
`Pending`, `Terminating` or `CrashLoopBackOff` pod cannot accept an exec.

With `-i` the second command becomes `kubectl exec -it "$pod" -- ...`. With `app.container` set it
gains `-c <container>`.

## Flags for your command

```console
$ kran exec -- bin/rails runner -e production 'puts Rails.env' --dry-run
... exec "$pod" -- bin/rails runner -e production 'puts Rails.env'
```

> **Use `--` when your command has flags.** Kran parses its own options first, so without it `-e`
> is taken as a kran option and rejected.
{: .callout .warning }

```console
$ kran exec
ERROR: exec needs a command to run, for example `kran exec bin/rails db:migrate`
$ kran exec bin/rails db:migrate
No running pod matches app=storefront
```

## Which pod

The first running match the API returns; there is no ordering guarantee. To reach a specific pod,
use `kubectl exec` with a name from `kran details`.

## shell and console

The template's two aliases are ordinary `kran exec` calls: `exec --interactive bash` and
`exec --interactive bin/rails console`. See [Aliases]({{ '/aliases/' | relative_url }}).
