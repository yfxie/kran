---
title: kran version
description: Print the version of kran and of every tool it drives, reporting missing or broken ones instead of failing.
---

# kran version

<p class="usage"><b>Usage</b><code>kran version</code></p>

The version of kran and of every tool it drives.

```console
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    krane 3.7.3
kubectl  Client Version: v1.32.1

# a missing tool and a broken one are reported, not raised
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    failed: Could not locate Gemfile (Bundler::GemfileNotFound)
kubectl  not found
```

It runs `docker --version`, `krane version` and `kubectl version --client`, keeping the first line
of each. `failed:` carries the first line of the tool's standard error.

## Without a configuration file

`kran version` is the one command that does not require `config/kran.yml`.

With a configuration file, the krane line uses `krane.command`, which makes this the quickest check
that a `bundle exec krane` setup resolves:

```yaml
krane:
  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane
```
