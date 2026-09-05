---
title: FAQ
description: Missing tools, deploying outside a git repository, protected namespaces, registry login, ejson-keys, multi-arch remote builds, exec flags and bundle exec.
---

# FAQ

## A tool is not on PATH

```console
$ kran deploy
ERROR: krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
```

The check runs before the first command, and lists every missing tool at once. The other hints:

| Tool | Hint |
| --- | --- |
| `docker` | Install it from `https://docs.docker.com/get-docker/` |
| `kubectl` | Install it from `https://kubernetes.io/docs/tasks/tools/` |
| `ejson` | Install it with `gem install ejson` (krane depends on it) or `brew install ejson` |

With `krane.command: bundle exec krane` you may see `bundle is not on PATH` instead: kran checks the
program it actually starts. `kran deploy -P` does not need docker, and `--dry-run` skips the check.

## kran cannot find an image tag

```console
$ kran deploy
ERROR: Git could not provide an image tag in /srv/build: Command failed (exit 128): git rev-parse HEAD
fatal: not a git repository (or any of the parent directories): .git
Pass --version to set the tag explicitly.
$ kran deploy --version 2024-06-01-1
```

See [Image tags]({{ '/image-tags/' | relative_url }}).

## Why does my tag say _uncommitted_

`git status --porcelain` printed something. The suffix is sixteen random hex characters, not a hash.
The image really contains those changes, because kran builds from the working directory; kamal, by
default, does not. See
[Image tags]({{ '/image-tags/' | relative_url }}#the-difference-from-kamal).

## krane refuses to deploy to my namespace

Krane treats `default`, `kube-system` and `kube-public` as protected. Use another namespace:

```console
$ kubectl --context prod-east create namespace storefront
namespace/storefront created
```

```yaml
kubernetes:
  context: prod-east
  namespace: storefront
```

This is krane's rule; kran passes the namespace through unchanged.

## Do I have to put the registry password in kran.yml

No. Leave `registry.username` and `registry.password` out and kran skips `docker login`; the push
uses whatever `docker login` already stored on this machine. Set both when nothing has logged in
beforehand, in CI for example.

## Secret ejson-keys not found

Krane decrypts `secrets.ejson` inside the cluster and needs the private key there:

```console
$ kubectl --context prod-east --namespace storefront \
>   create secret generic ejson-keys \
>   --from-literal=<public key>=<private key>
secret/ejson-keys created
```

Use `create`, not `apply`, or krane's prune will delete it. See
[Secrets]({{ '/secrets/' | relative_url }}#the-ejson-keys-secret).

Separate from `registry.password: { ejson: ... }`, which kran decrypts locally with the `ejson`
binary and a key in `/opt/ejson/keys/<public key>` or `EJSON_KEYDIR`.

## A multi-arch build fails on the remote daemon

With `builder.remote` set, one daemon has to build both platforms, which needs binfmt/QEMU plus the
containerd image store, or a buildx builder with a node per architecture.

```console
$ kran build details
DOCKER_HOST=ssh://builder@build.internal docker version
DOCKER_HOST=ssh://builder@build.internal docker buildx ls
NAME/NODE       DRIVER/ENDPOINT   STATUS    BUILDKIT   PLATFORMS
default*        docker
 \_ default      \_ default       running   v0.19.0    linux/amd64
```

If the `PLATFORMS` column lists one architecture, build one:

```yaml
builder:
  arch: amd64
  remote: ssh://builder@build.internal
```

See [Remote builder]({{ '/remote-builder/' | relative_url }}#multi-arch-on-a-remote-daemon).

## My exec command has flags and kran eats them

Put a bare `--` before the command, or `-e` is read as a kran option:

```sh
kran exec -- bin/rails runner -e production 'puts Rails.env'
```

## No running pod matches my selector

```console
$ kran exec bin/rails db:migrate
No running pod matches app=storefront
```

`kran exec` needs a pod that matches `app.selector` and is in phase `Running`. Check the labels in
your krane templates against the selector — `kran details` prints the pods — and check that they are
running. `kran logs` still works on ones that are not.

## kran logs shows almost nothing

Without `-n`, kubectl shows only the last 10 lines per pod when a selector is used.

```sh
kran logs -n 500
kran logs --since 1h
```

## Running kran under bundle exec

Kran runs every external command inside `Bundler.with_unbundled_env`, so `RUBYOPT` and
`BUNDLE_GEMFILE` are removed before krane, ejson, docker, kubectl or git start. Otherwise krane
would resolve against kran's Gemfile.

So `bundle exec kran deploy` works with krane installed globally, and with krane in a separate
bundle if you name it:

```yaml
krane:
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```

Variables you export yourself are untouched. Check with `kran version`.

## Can I see the commands without running them

```sh
kran deploy --dry-run
kran build push --dry-run
kran logs --dry-run
```

`--dry-run` works on every command and never prints a password.

## Does kran change my current kubectl context

No. It passes `--context` and `--namespace` on every kubectl command and, with
`kubernetes.kubeconfig` set, prefixes them with `KUBECONFIG=`.

## Can I still use krane and kubectl directly

Yes. Take the prefix from `kran deploy --dry-run`:

```sh
KUBECONFIG=/home/dana/.kube/prod-east.yml \
  kubectl --context prod-east --namespace storefront get ingress
```

Kran holds no state and installs no hooks.
