---
title: Aliases
description: shell and console, and how to define your own shortcuts in config/kran.yml.
---

# Aliases

An alias is a name in `config/kran.yml` that expands to a kran command string.

## The two in the template

```yaml
aliases:
  shell: exec --interactive bash
  console: exec --interactive bin/rails console
```

```sh
kran shell
kran console
```

The names come from kamal.

If your image has no `bash`:

```yaml
aliases:
  shell: exec --interactive sh
```

## Your own

```yaml
aliases:
  migrate: exec bin/rails db:migrate
  routes: exec bin/rails routes
  errors: logs -g ERROR
  tail: logs -f -n 100
  psql: exec --interactive psql $DATABASE_URL
```

The value is the rest of a kran command line, split with shell word rules.

## Extra arguments are appended

```console
$ kran migrate --trace --dry-run
... exec "$pod" -- bin/rails db:migrate --trace
```

## With destinations

```sh
kran console -d staging
```

The destination is read before the alias is expanded, so `config/kran.staging.yml` can define its
own aliases or override one from the base file.

## They cannot shadow a built-in

Kran resolves built-in commands first and only asks the alias table about names it does not
recognise.

```console
$ kran nope
Could not find command "nope".
```

## Limits

Aliases are expanded by kran, not by your shell, so they are shared with everyone who checks out the
repository. The expansion is a kran command line, so `deploy && curl ...` is not an alias.
