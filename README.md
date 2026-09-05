# kran

[![Gem Version](https://img.shields.io/gem/v/kran)](https://rubygems.org/gems/kran)
[![CI](https://github.com/yfxie/kran/actions/workflows/ci.yml/badge.svg)](https://github.com/yfxie/kran/actions/workflows/ci.yml)
[![Coverage Status](https://coveralls.io/repos/github/yfxie/kran/badge.svg?branch=main)](https://coveralls.io/github/yfxie/kran?branch=main)
[![License](https://img.shields.io/github/license/yfxie/kran)](LICENSE)

Deploy to Kubernetes with [krane](https://github.com/Shopify/krane), the simple way.
One command builds the image, pushes it, renders the krane templates and deploys them. A few more
commands cover the daily work: logs, exec, details, audit.

Kran is the German word for crane.

## Install

```sh
gem install kran
```

Kran drives `docker`, `krane` and `kubectl`, and `ejson` when secrets come from krane's `secrets.ejson`.
None of them is a gem dependency. `kran version` shows which ones are found.

## Use

```sh
kran init                 # writes config/kran.yml
kran deploy --dry-run     # prints every command it would run
kran deploy               # docker login, docker build --push, krane render | krane deploy
kran deploy -P            # skip the build and push
kran logs -f
kran exec bin/rails db:migrate
kran shell                # alias for: exec --interactive bash
kran console              # alias for: exec --interactive bin/rails console
```

Every command reads `config/kran.yml`. `-d staging` layers `config/kran.staging.yml` on top of it.

If you have used [kamal](https://kamal-deploy.org), this will feel just as simple: familiar command names,
one config file, one command to deploy.

Documentation: https://kran.bincode.tw

## Develop

```sh
bundle install
bundle exec rake test
bundle exec rubocop
```

## License

MIT
