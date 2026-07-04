# AGENTS.md

Guidance for agentic coding assistants in `arity-action`.

## Scope

- Repo type: composite GitHub Action.
- Purpose: install `arity` and run format/lint checks.
- Primary files: `action.yml`, `scripts/install-arity.sh`, `scripts/install-arity.ps1`.
- CI coverage: Linux/macOS/Windows on x64 and ARM64.

## Repository Map

- `action.yml`: action API (inputs/outputs) and execution steps.
- `scripts/install-arity.sh`: Unix installer (with SHA256 verification).
- `scripts/install-arity.ps1`: Windows installer (with SHA256 verification).
- `.github/workflows/ci.yml`: integration tests + versionary release job.
- `.github/workflows/update-major-minor-tags.yml`: release tag maintenance.
- `fixtures/ok.R`, `fixtures/bad.R`: expected pass/fail fixtures.
- `versionary.jsonc`: versionary release config (`simple` strategy).
- `version.txt`: the current version, managed by versionary.

## Tooling Assumptions

- No `package.json`, `Makefile`, or Python project files.
- No compile/build artifact pipeline; tests are workflow-driven.
- Installer smoke checks require network access.

## Lint and Validation

Run from repo root.

- Shell syntax: `sh -n scripts/install-arity.sh`
- PowerShell parse check:
  `pwsh -NoLogo -NoProfile -Command "[void][ScriptBlock]::Create((Get-Content -Raw 'scripts/install-arity.ps1'))"`
- Optional stronger checks (if installed): `shellcheck scripts/install-arity.sh`, `actionlint`

## Test

- Main workflow: `.github/workflows/ci.yml`.
  - `test-pass` should succeed with `fixtures/ok.R`.
  - `test-fail` should fail with `fixtures/bad.R` (failure is asserted).
- Focused Unix smoke check without CI:
  - `tmpdir="$(mktemp -d)" && ARITY_INSTALL_DIR="$tmpdir" ARITY_VERIFY_CHECKSUM=false bash scripts/install-arity.sh && "$tmpdir/arity" --version`

## Code Style Guidelines

- Preserve Unix/Windows behavior parity; keep OS conditionals explicit.
- YAML: 2-space indent, kebab-case input names, string booleans (`"true"`/`"false"`).
- Shell: POSIX `sh`, prologue `#!/usr/bin/env sh` + `set -eu`, `case` for OS/arch
  branching, quote expansions, HTTPS-only downloads, `trap` cleanup.
- PowerShell: `$ErrorActionPreference = 'Stop'`, camelCase names, explicit
  cmdlets, `try/finally` cleanup, throw on unsupported architecture.
- Env vars: `ARITY_*` (UPPER_SNAKE_CASE).
- Update `README.md` when behavior or the input/output API changes.
- Use Conventional Commits (`feat:`, `fix:`, `chore:`).

## Security

- Download artifacts only over HTTPS from GitHub Releases.
- Never log secrets/tokens.
- Treat release/tag automation edits as high risk.
