---
title: kran init
description: Write config/kran.yml from the built-in template, without overwriting an existing file.
---

# kran init

<p class="usage"><b>Usage</b><code>kran init</code></p>

Copies the built-in template to `config/kran.yml`, creating `config/` if needed.

```console
$ kran init
Created config/kran.yml

# an existing file is left alone
$ kran init
config/kran.yml already exists (remove it first to create a new one)
```

The file it writes is the commented template on the
[Configuration]({{ '/configuration/' | relative_url }}) page.

## Destinations

`kran init` writes the base file only. A destination file such as `config/kran.staging.yml` is a
partial override you write by hand. See [Destinations]({{ '/destinations/' | relative_url }}).
