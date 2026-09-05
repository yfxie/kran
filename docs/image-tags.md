---
title: Image tags
description: How kran derives the image tag from git, what the _uncommitted_ suffix means, and how this differs from kamal.
---

# Image tags

| Situation | Tag |
| --- | --- |
| `--version TAG` given | `TAG`, exactly as written |
| Clean working tree | `git rev-parse HEAD` |
| Uncommitted changes | `<sha>_uncommitted_<16 random hex>` |

```text
ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2
ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2_uncommitted_4b81d0e6a37f92c5
ghcr.io/acme/storefront:v2.4.0
```

One deploy uses the tag three times: as the docker tag, as krane's `--current-sha`, and inside the
`image` binding. They cannot disagree.

## The uncommitted suffix

The working tree is dirty when `git status --porcelain` prints anything. Kran then appends
`_uncommitted_` and sixteen random hex characters.

> **The suffix is random, not a content hash.** Two builds from the same dirty tree get two
> different tags. That guarantees a tag is never reused for different content; it is not
> deduplication. Kamal does the same.
{: .callout .note }

A content hash would have to decide what counts as content — tracked files, untracked files, file
modes, submodules — and would reuse a tag whenever it guessed wrong.

Treat an `_uncommitted_` tag as disposable: no commit reproduces it.

## The difference from kamal

Kamal, by default, does not build your uncommitted changes. It builds from a clean clone, adding the
`_uncommitted_` suffix as a warning that the *tag* does not match the tree. Only with
`builder.context` set does kamal build from the working directory.

Kran always builds from the working directory, because `builder.context` defaults to `.`.

A tag that says `_uncommitted_` and contains only committed code misleads in the more dangerous
direction: you believe your change is deployed and it is not. To get kamal's behaviour, commit
first; a clean tree produces a plain sha tag either way.

## Outside a git repository

```console
# the same message appears in a repository with no commits yet
$ kran deploy
ERROR: Git could not provide an image tag in /srv/build: Command failed (exit 128): git rev-parse HEAD
fatal: not a git repository (or any of the parent directories): .git
Pass --version to set the tag explicitly.
$ kran deploy --version 2024-06-01-1
```

## In CI

CI checkouts are clean, so the derived tag is the commit sha. Pass it explicitly when the checkout
is shallow or detached:

```sh
kran build push --version "$GITHUB_SHA"
kran deploy --version "$GITHUB_SHA" -P
```

Building once and deploying the same tag to several environments:

```sh
kran deploy --version "$GITHUB_SHA" -P -d staging
kran deploy --version "$GITHUB_SHA" -P
```

## In a template

```erb
image: <%= image %>            # ghcr.io/acme/storefront:9c1f4d0...
labels:
  app.kubernetes.io/version: <%= current_sha %>
```

`image` is the full reference; `current_sha` is the tag alone. See
[krane templates]({{ '/templates/' | relative_url }}).
