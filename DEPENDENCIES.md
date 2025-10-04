# Dependency inventory for rails_fast_epost

This file is an automated inventory of the project's dependencies produced by scanning `Gemfile`, `Gemfile.lock`, and `Dockerfile`.

## Ruby (gems)

Source files: `Gemfile`, `Gemfile.lock`

Top-level declared gems (from `Gemfile`):

- rails (~> 8.0.1)
- propshaft
- pg (~> 1.1)
- puma (>= 5.0)
- importmap-rails
- turbo-rails
- stimulus-rails
- jbuilder
- tzinfo-data (platforms: windows, jruby)
- solid_cache
- solid_queue
- solid_cable
- bootsnap (require: false)
- kamal (require: false)
- thruster (require: false)

Development & test groups:

- debug (development, test)
- brakeman (development, test)
- rubocop-rails-omakase (development, test)
- web-console (development)
- capybara (test)
- selenium-webdriver (test)

Resolved gem versions (from `Gemfile.lock` - partial list):

- rails 8.0.1
- actioncable 8.0.1
- actionmailbox 8.0.1
- actionmailer 8.0.1
- actionpack 8.0.1
- actiontext 8.0.1
- actionview 8.0.1
- activerecord 8.0.1
- activesupport 8.0.1
- bootsnap 1.18.4
- pg 1.5.9
- puma 6.6.0
- tzinfo 2.0.6
- nokogiri 1.18.2 (platform variants)
- thruster 0.1.11
- kamal 2.5.2
- propshaft 1.1.0
- importmap-rails 2.1.0
- turbo-rails 2.0.11
- stimulus-rails 1.3.4

Full Bundler dependencies are available in `Gemfile.lock`.

## System / OS packages (from `Dockerfile`)

Base image:

- docker.io/library/ruby:3.3.4-slim

Packages installed in the Docker image (from Dockerfile build stages):

- curl
- libjemalloc2
- libvips
- postgresql-client
- build-essential
- git
- libpq-dev
- pkg-config

See `apt-packages.txt` for a plain list suitable for `xargs apt-get install` or other automation.

## Node / JS dependencies

No `package.json`, `yarn.lock`, or other JS package manifest was found. The project uses Importmap (`importmap-rails`) and Stimulus via the gem; JS packages are likely vendor-managed or loaded via CDN/importmap.

## Python / Other ecosystems

No `requirements.txt`, `Pipfile`, or `pyproject.toml` was found in the repository.

## Recommendations / Next steps

1. Keep `Gemfile.lock` under version control (already present). Use `bundle install --deployment` in CI/production.
2. If you want an explicit Node.js dependency manifest (for tooling, ESM bundling, or front-end packages), add a `package.json` at the project root and include any build tools you need.
3. Consider adding an `apt-packages.txt` (created here) consumed by CI or documentation so OS packages are kept in sync with the Dockerfile.
4. If you want, I can also create a `DEPENDENCIES.json` machine-readable manifest.

---
Generated: 2025-09-16
