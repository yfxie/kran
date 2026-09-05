---
title: Installation
description: Install kran as a gem, or add it to a project's Gemfile, and check the result with kran version.
---

# Installation

```console
$ gem install kran
$ kran version
kran     1.0.0
docker   Docker version 27.5.1, build 9f9e405
krane    krane 3.7.3
kubectl  Client Version: v1.32.1
```

## In a Gemfile

To pin kran per project, put it in a group the application does not load:

```ruby
group :deploy, optional: true do
  gem "kran"
end
```

```console
$ bundle install --with deploy
$ bundle exec kran version
kran     1.0.0
```

Kran runs every external command with `Bundler.with_unbundled_env`, so `bundle exec kran` can drive
a krane from a different Gemfile or a global install. See
[running under bundle exec]({{ '/faq/#running-kran-under-bundle-exec' | relative_url }}).

## Tools kran does not install

Kran shells out to `docker`, `krane`, `kubectl`, and to `ejson` when a registry password comes from
krane's encrypted secrets. None of them is a gem dependency.

Krane is deliberately excluded: it pulls in a large part of the Kubernetes client stack, and most
projects already pin it in a deploy bundle of their own.

Every command checks the tools it needs before running anything:

```console
$ kran deploy
ERROR: krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
```

See [Prerequisites]({{ '/prerequisites/' | relative_url }}).
