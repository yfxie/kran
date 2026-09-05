---
title: kran logs
description: Read logs from every pod matching the app selector, with follow, tail, since and grep.
---

# kran logs

<p class="usage"><b>Usage</b><code>kran logs [-f] [-n N] [-s DURATION] [-g PATTERN]</code></p>

`kubectl logs` against every pod matching `app.selector`.

## Options

| Option | Meaning |
| --- | --- |
| `-f`, `--follow` | Stream new lines as they arrive |
| `-n N`, `--lines N` | Show the last `N` lines per pod (`--tail`) |
| `-s X`, `--since X` | Only lines newer than `X`, for example `10m` or `1h` |
| `-g P`, `--grep P` | Pipe the output through `grep P` |
| `-d NAME` | Load `config/kran.NAME.yml` over `config/kran.yml` |
| `--dry-run` | Print the command and run none of it |
{: .opts }

## The command it runs

```console
$ kran logs --dry-run
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront logs -l app=storefront --prefix --timestamps

# every option, in the order kran appends them
$ kran logs -f -n 200 --since 10m -g "ERROR" --dry-run
KUBECONFIG=/home/dana/.kube/prod-east.yml kubectl --context prod-east --namespace storefront logs -l app=storefront --prefix --timestamps --tail 200 --since 10m -f | grep ERROR
```

`--prefix` puts the pod name in front of every line, because the selector usually matches several
pods and their output is interleaved. `--timestamps` makes that readable.

`-g` is a shell pipe into `grep`, not a kubectl feature, so it composes with `-f`.

With `app.container` set, `-c <container>` is added after the selector.

## Default number of lines

Without `-n`, kubectl shows the 10 most recent lines per pod when a selector is used.

```sh
kran logs -n 500
```

## Only the app pods

`kran logs` follows `app.selector`, so jobs, sidecar deployments and one-off pods in the same
namespace are excluded. `kran details` prints their names for use with `kubectl` directly.
