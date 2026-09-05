---
title: kran deploy
description: Build the image, push it, render the krane templates with the image reference bound in, and pipe the result into krane deploy.
---

# kran deploy

<p class="usage"><b>Usage</b><code>kran deploy [--version TAG] [-P|--skip-push]</code></p>

Build and push the image, then render the krane templates and deploy them.

The deployment process is:

1. Check that `docker` (unless `-P`), the executable behind `krane.command` and `kubectl` are on
   PATH.
2. Decide the tag: `--version` if given, otherwise `git rev-parse HEAD`, with an `_uncommitted_`
   suffix when the working tree is dirty.
3. `docker login`, with the password on standard input, when `registry.username` and
   `registry.password` are set.
4. `docker build --platform ... --push`, tagging `<server>/<image>:<tag>`.
5. `krane render | krane deploy`, with the tag as `--current-sha` and the full image reference as
   `--bindings image=...`.

Steps 3 and 4 are skipped with `-P`.

## Options

| Option | Meaning |
| --- | --- |
| `--version TAG` | Use `TAG` as the image tag instead of deriving one from git |
| `-P`, `--skip-push` | Skip the login, build and push |
| `-d NAME` | Load `config/kran.NAME.yml` over `config/kran.yml` |
| `--dry-run` | Print the commands and run none of them |
{: .opts }

## The commands it runs

```console
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | KUBECONFIG=/home/dana/.kube/prod-east.yml krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

The third line:

* `krane render -f config/deploy` evaluates the ERB in every template there and writes plain YAML.
* `--current-sha` and `--bindings image=...` become local variables in those templates, so a
  Deployment can write `image: <%= image %>`. See
  [krane templates]({{ '/templates/' | relative_url }}).
* `krane deploy storefront prod-east` is namespace first, context second.
* `-f config/deploy/secrets.ejson -` passes the encrypted secrets, then `-` reads the rendered YAML
  from the pipe. Both share one `-f` because krane keeps only the last `-f` it is given. See
  [Secrets]({{ '/secrets/' | relative_url }}).

> **`krane deploy` does not evaluate ERB.** That is the whole reason kran pipes `krane render` into
> it instead of calling `krane deploy` on the template directory.
{: .callout .note }

```console
# with a builder.remote configured, both docker lines are prefixed
$ kran deploy --dry-run
printf '%s' '[REDACTED]' | DOCKER_HOST=ssh://builder@build.internal docker login ghcr.io -u acme-deploy --password-stdin
DOCKER_HOST=ssh://builder@build.internal docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
```

## --dry-run

Prints the command sequence, runs nothing, and does not require docker, krane or kubectl. The
`printf '%s' '[REDACTED]' |` prefix shows that the password reaches `docker login` on standard
input, never a command line.

## -P, --skip-push

```console
# only the krane pipeline, so docker is not needed either
$ kran deploy -P --dry-run
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | KUBECONFIG=/home/dana/.kube/prod-east.yml krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

Use it to re-apply templates, or with `--version` to move a known image between environments:

```sh
kran deploy --version 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 -P -d staging
```

It is also how you roll back: krane deploys a desired state, so rolling back is deploying the
previous tag.

## --version

Overrides the tag. Outside a git repository it is the only way to deploy:

```console
$ kran deploy
ERROR: Git could not provide an image tag in /srv/build: Command failed (exit 128): git rev-parse HEAD
fatal: not a git repository (or any of the parent directories): .git
Pass --version to set the tag explicitly.
$ kran deploy --version v2.4.0
```

## Missing tools

```console
$ kran deploy
ERROR: krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
```

With `krane.command: bundle exec krane` the check applies to `bundle`, the program kran starts.
