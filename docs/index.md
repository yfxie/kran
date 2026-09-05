---
title: Introduction
description: kran wraps Shopify's krane so one command builds an image, pushes it, renders the krane templates and deploys them.
sidebar: false
---

# kran
{: .home-title }

Deploy to Kubernetes with [krane](https://github.com/Shopify/krane), the simple way.
One command builds the image, pushes it, renders the krane templates and deploys them.
{: .home-lede }

<div class="actions">
  <a class="btn btn-primary" href="{{ '/getting-started/' | relative_url }}">Get started</a>
  <a class="btn" href="{{ '/configuration/' | relative_url }}">Configuration</a>
  <a class="btn" href="{{ '/commands/' | relative_url }}">Commands</a>
  <a class="btn" href="{{ site.repo_url }}" rel="noopener">{% include icons.html name="github" %}GitHub</a>
</div>

*Kran* is the German word for crane, the same word behind Shopify's *krane*.
{: .aside }

> **kran and krane are two different tools.** *krane* is Shopify's deployment tool and does the
> actual work. *kran* is this gem, which drives it. One letter apart, so read command names
> carefully.
{: .callout .warning }

## Deploying with krane by hand

```console
$ export DOCKER_HOST=ssh://builder@build.internal
$ export KUBECONFIG=$HOME/.kube/prod-east.yml

$ echo "$GITHUB_TOKEN" | docker login ghcr.io -u acme-deploy \
>   --password-stdin
Login Succeeded

$ docker build --platform linux/amd64 --push \
>   -t ghcr.io/acme/storefront:$(git rev-parse HEAD) .
pushed ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2

$ krane render -f config/deploy --current-sha $(git rev-parse HEAD) \
>   | krane deploy storefront prod-east \
>       -f config/deploy/secrets.ejson -
Deploying resources
Successfully deployed 4 resources
```

Every value in that session is a fact about the project, not about deploying: the registry, the
build host, the platform, the kubeconfig, the namespace, the context, the template directory.

## With kran

Those facts move into `config/kran.yml`, and one command reads them:

```console
# kran prints every step before it runs
$ kran deploy
printf '%s' '[REDACTED]' | docker login ghcr.io -u acme-deploy --password-stdin
docker build --platform linux/amd64 --push -t ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 .
krane render -f config/deploy --current-sha 9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 --bindings image=ghcr.io/acme/storefront:9c1f4d0b7a2e58c3d6f1b8a4e70925d3c8b1a6f2 | krane deploy storefront prod-east -f config/deploy/secrets.ejson -
```

Same docker, same krane, same templates. The tag is the git sha, and the full image reference is
bound into the krane templates as `image`.

The daily work:

```sh
kran logs -f
kran exec bin/rails db:migrate

# every resource in the namespace, then the rollout history
kran details
kran audit

# aliases, defined in config/kran.yml
kran shell
kran console
```

`shell` and `console` expand to `exec --interactive bash` and
`exec --interactive bin/rails console`.

If you have used [kamal](https://kamal-deploy.org), this will feel just as simple: familiar command
names, one config file, one command to deploy. Only the target changes, from a host to a cluster.

## Not an abstraction

Kran writes no manifests, invents no resource types and holds no state. It builds command lines for
`docker`, `krane` and `kubectl` and runs them.

> Every command takes `--dry-run`, which prints the exact sequence and runs none of it.
{: .callout .tip }

## Next

<ul class="next-steps">
  <li><a class="card" href="{{ '/installation/' | relative_url }}">Installation<span>Install the gem and the tools it drives.</span></a></li>
  <li><a class="card" href="{{ '/getting-started/' | relative_url }}">Getting started<span>From <code>kran init</code> to a first deploy.</span></a></li>
  <li><a class="card" href="{{ '/configuration/' | relative_url }}">Configuration<span>Every key of <code>config/kran.yml</code>.</span></a></li>
  <li><a class="card" href="{{ '/commands/' | relative_url }}">Commands<span>Each command and the command it runs.</span></a></li>
</ul>
