# GitHub Action for arity

[![CI](https://github.com/jolars/arity-action/actions/workflows/ci.yml/badge.svg)](https://github.com/jolars/arity-action/actions/workflows/ci.yml)

A GitHub Action that installs [arity](https://github.com/jolars/arity) and runs
formatting and lint checks in CI.

The action installs prebuilt release binaries and supports GitHub-hosted runners
for Linux, macOS, and Windows on both x64 and ARM64. Downloaded binaries are
verified against their published SHA256 checksum and cached between runs.

## Usage

### Basic

```yaml
name: arity

on:
  pull_request:
  push:
    branches: [main]

jobs:
  arity:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: jolars/arity-action@v1
```

### Pin arity version

```yaml
- uses: jolars/arity-action@v1
  with:
    version: v0.8.0
```

### Format only

```yaml
- uses: jolars/arity-action@v1
  with:
    lint: "false"
```

### Lint only

```yaml
- uses: jolars/arity-action@v1
  with:
    format: "false"
```

### Run only on a specific path

```yaml
- uses: jolars/arity-action@v1
  with:
    path: R/
```

### Use a custom config

```yaml
- uses: jolars/arity-action@v1
  with:
    config: arity.toml
```

## Inputs

| Input             | Description                                       | Default  |
| ----------------- | ------------------------------------------------- | -------- |
| `path`            | File or directory to check                        | `.`      |
| `version`         | arity version to install (`latest` or `vX.Y.Z`)   | `latest` |
| `format`          | Run `arity format --check`                        | `true`   |
| `lint`            | Run `arity lint`                                  | `true`   |
| `config`          | Optional path to an `arity.toml` config file      | `""`     |
| `verify-checksum` | Verify the downloaded asset against its SHA256    | `true`   |

## Outputs

| Output    | Description                 |
| --------- | --------------------------- |
| `version` | Installed arity CLI version |

## Checksum verification

When `verify-checksum` is `true` (the default), the action downloads the
`.sha256` sidecar published alongside each release asset and verifies the
archive before installing. Releases that predate checksum publishing have no
sidecar; for those the action prints a warning and installs without
verification rather than failing.

## Versioning

This action uses semantic versioning based on action API changes:

- Major: breaking changes to action inputs/outputs/behavior
- Minor: backward-compatible features
- Patch: fixes and internal improvements

Use `@v1` for stable major updates, or pin exact tags like `@v1.2.3`.
