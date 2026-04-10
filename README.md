# Quality Checks

## Table of Contents

- [Overview](#overview)
- [Example Consumer Workflow](#example-consumer-workflow)
- [Reusable Workflow Architecture](#reusable-workflow-architecture)
- [Input Parameters](#input-parameters)
- [Supported Linters](#supported-linters)

## Overview

This repository contains a reusable GitHub Actions workflow that performs quality checks on code in pull requests. The workflow runs linters (Actionlint, ESLint, Hadolint, jq, Markdownlint, Prettier, Ruff, ShellCheck, StyLua, Taplo, and Yamllint) on committed code changes and fails if any linting errors are detected.

## Example Consumer Workflow

To use this reusable workflow in your repository, create a workflow file (e.g., `.github/workflows/quality-checks.yaml`) that calls it:

```yaml
name: 'Quality Checks'

on: pull_request

jobs:
  quality-checks:
    uses: garretpatten/quality-checks/.github/workflows/quality-checks.yaml@master
    with:
      actionlint_run: true
      eslint_run: true
      hadolint_run: true
      jq_run: true
      markdownlint_run: true
      prettier_run: true
      ruff_run: true
      shellcheck_run: true
      taplo_run: true
      yamllint_run: true
    secrets: inherit
```

## Reusable Workflow Architecture

This repository contains a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows) located at [.github/workflows/quality-checks.yaml](.github/workflows/quality-checks.yaml). The workflow is designed to perform essential quality checks across projects by running linters on code changes in pull requests.

The workflow checks only the files that have been changed in the pull request, making it efficient and focused on the code being reviewed. Each linter is invoked once with the full list of changed paths (where the tool supports that), which matches typical CLI usage and keeps runs fast.

### Comparing against the correct base commit

By default, the workflow diffs against `origin/main`, then `origin/master`, otherwise `HEAD~1`. For pull requests, you can pin the base explicitly so only commits on the PR branch are checked (recommended when the default branch is not `main`/`master`, or you want an exact merge-base):

```yaml
with:
  diff_base: ${{ github.event.pull_request.base.sha }}
  prettier_run: true
```

## Input Parameters

Each linter is **opt-in**: every `*_run` input defaults to `false`, so callers must pass `true` for each tool they want to run (as in the [example](#example-consumer-workflow) above).

| Parameter          | Type    | Required | Default   | Description |
| ------------------ | ------- | -------- | --------- | ----------- |
| `diff_base`        | string  | No       | *(empty)* | Git ref (SHA or branch) to diff against; see above |
| `node_version`     | string  | No       | `20`      | Node.js version for ESLint, markdownlint-cli2, and Prettier |
| `stylua_args`      | string  | No       | `--check .` | Arguments passed to [StyLua](https://github.com/JohnnyMorganz/StyLua) |
| `stylua_version`   | string  | No       | `v2.4.1`  | StyLua release tag for `JohnnyMorganz/stylua-action` |
| `actionlint_run`   | boolean | No       | `false`   | Whether to run the Actionlint GitHub Actions linter |
| `eslint_run`       | boolean | No       | `false`   | Whether to run the ESLint JavaScript/TypeScript linter |
| `hadolint_run`     | boolean | No       | `false`   | Whether to run the Hadolint Dockerfile linter |
| `jq_run`           | boolean | No       | `false`   | Whether to run the jq JSON validator |
| `markdownlint_run` | boolean | No       | `false`   | Whether to run the Markdownlint Markdown linter |
| `prettier_run`     | boolean | No       | `false`   | Whether to run the Prettier code formatter check |
| `ruff_run`         | boolean | No       | `false`   | Whether to run the Ruff Python linter |
| `shellcheck_run`   | boolean | No       | `false`   | Whether to run the ShellCheck shell script linter |
| `stylua_run`       | boolean | No       | `false`   | Whether to run the StyLua Lua formatter check |
| `taplo_run`        | boolean | No       | `false`   | Whether to run the Taplo TOML linter |
| `yamllint_run`     | boolean | No       | `false`   | Whether to run the Yamllint YAML linter |

## Supported Linters

### Actionlint

Actionlint statically checks GitHub Actions workflow files for common errors and best practices. It checks the following file types:

- GitHub Actions workflow files (`.yml`, `.yaml` in `.github/workflows/`)
- GitHub Actions action files (`.yml`, `.yaml` in `.github/actions/`)

Actionlint will fail if it detects any issues in GitHub Actions workflow files, helping to catch potential errors before they reach production.

### ESLint

ESLint statically analyzes JavaScript and TypeScript code to find problems and enforce code quality standards. It checks the following file types:

- JavaScript (`.js`, `.jsx`)
- TypeScript (`.ts`, `.tsx`)

ESLint will fail if it detects any linting errors or rule violations in the code. The workflow will use a local ESLint configuration if one exists in the repository (via `.eslintrc.*`, `eslint.config.*`, or `package.json`), otherwise it will use ESLint's default configuration. If the repository has a `package.json` file, dependencies will be installed before running ESLint to ensure any ESLint plugins or configurations are available.

### Hadolint

Hadolint is a Dockerfile linter that checks Dockerfiles for best practices and common mistakes. It checks the following file types:

- Dockerfiles (`Dockerfile`, `.dockerfile`)

Hadolint will fail if it detects any issues in Dockerfiles, helping to catch potential security vulnerabilities and best practice violations before deployment.

### jq

jq is a lightweight and flexible command-line JSON processor. When used with the `-e` flag, it validates JSON syntax. It checks the following file types:

- JSON files (`.json`)

The job uses the `jq` binary from the GitHub-hosted Ubuntu runner image (no extra install step). jq will fail if it detects any syntax errors in JSON files. The `jq -e .` command reads the JSON file and exits with a non-zero status code if the JSON is invalid, making it an effective JSON validator.

### Markdownlint

Markdownlint-cli2 is a fast and flexible Markdown linter that checks Markdown files for style and formatting issues. It checks the following file types:

- Markdown files (`.md`, `.markdown`)

Markdownlint-cli2 will fail if it detects any linting errors or rule violations in Markdown files. The workflow will use a local Markdownlint configuration if one exists in the repository (via `.markdownlint.json`, `.markdownlint.yaml`, `.markdownlint.yml`, or `package.json`), otherwise it will use Markdownlint's default configuration.

### Prettier

Prettier checks code formatting for the following file types:

- JavaScript (`.js`, `.jsx`)
- TypeScript (`.ts`, `.tsx`)
- JSON (`.json`)
- CSS/SCSS (`.css`, `.scss`)
- Markdown (`.md`)
- YAML (`.yml`, `.yaml`)

The job runs from the repository root and, when present, passes explicit `--ignore-path` values for the root `.gitignore` and `.prettierignore` (Prettier replaces its default ignore list whenever any `--ignore-path` is set, so both are supplied when both files exist). Changed paths that Prettier treats as ignored (for example under `node_modules`) are skipped using `prettier --file-info`, then the remaining files are checked in a single `prettier --check` invocation with `--no-error-on-unmatched-pattern` as a safety net. It does not modify files, only reports formatting issues.

### Ruff

Ruff is a fast Python linter and code formatter that checks Python code for errors, style issues, and potential bugs. It checks the following file types:

- Python scripts (`.py`)
- Python wheel scripts (`.pyw`)

Ruff will fail if it detects any linting errors or rule violations in the Python code. The workflow will use a local Ruff configuration if one exists in the repository (via `ruff.toml`, `pyproject.toml`, or `.ruff.toml`), otherwise it will use Ruff's default configuration.

### ShellCheck

ShellCheck analyzes shell scripts for common errors and best practices. It checks the following file types:

- Shell scripts (`.sh`)
- Bash scripts (`.bash`)
- Zsh scripts (`.zsh`)

The job uses the `shellcheck` binary from the GitHub-hosted Ubuntu runner image (no extra install step). ShellCheck will fail if it detects any issues in the shell scripts, helping to catch potential bugs and security issues before they reach production.

### StyLua

StyLua is a formatter for Lua. Enable it with `stylua_run: true`. By default the workflow runs `stylua --check .` at the repository root; override with `stylua_args` (for example `--check config/nvim` for Neovim-only trees) and optionally `stylua_version`.

### Taplo

Taplo is a fast and feature-complete TOML toolkit that includes a linter for TOML files. It checks the following file types:

- TOML files (`.toml`)

Taplo will fail if it detects any syntax errors or linting issues in TOML files. The workflow will use a local Taplo configuration if one exists in the repository (via `taplo.toml` or `pyproject.toml`), otherwise it will use Taplo's default configuration.

### Yamllint

Yamllint is a linter for YAML files that checks for syntax validity, key repetition, and cosmetic problems. It checks the following file types:

- YAML files (`.yml`, `.yaml`)

Yamllint will fail if it detects any syntax errors or linting issues in YAML files. The workflow will use a local Yamllint configuration if one exists in the repository (via `.yamllint`, `.yamllint.yml`, or `.yamllint.yaml`), otherwise it will use Yamllint's default configuration.
