# Quality Checks

## Table of Contents

- [Overview](#overview)
- [Example Consumer Workflow](#example-consumer-workflow)
- [Reusable Workflow Architecture](#reusable-workflow-architecture)
- [Input Parameters](#input-parameters)
- [Supported Linters](#supported-linters)

## Overview

This repository contains a reusable GitHub Actions workflow that performs quality checks on code in pull requests. The workflow runs linters (Prettier and ShellCheck) on committed code changes and fails if any linting errors are detected.

## Example Consumer Workflow

To use this reusable workflow in your repository, create a workflow file (e.g., `.github/workflows/quality-checks.yml`) that calls it:

```yaml
name: Quality Checks

on:
  pull_request:
  push:
    branches:
      - main
      - master

jobs:
  quality-checks:
    uses: ./.github/workflows/quality-checks.yml
    with:
      prettier_run: true
      shellcheck_run: true
      runs_on: ubuntu-latest
    secrets: inherit
```

You can also selectively enable/disable linters:

```yaml
jobs:
  quality-checks:
    uses: ./.github/workflows/quality-checks.yml
    with:
      prettier_run: true
      shellcheck_run: false
```

## Reusable Workflow Architecture

This repository contains a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows) located at [.github/workflows/quality-checks.yml](.github/workflows/quality-checks.yml). The workflow is designed to perform essential quality checks across projects by running linters on code changes in pull requests.

The workflow checks only the files that have been changed in the pull request, making it efficient and focused on the code being reviewed.

## Input Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `prettier_run` | boolean | No | `true` | Whether to run the Prettier code formatter check |
| `shellcheck_run` | boolean | No | `true` | Whether to run the ShellCheck shell script linter |
| `runs_on` | string | No | `ubuntu-latest` | The GitHub Actions runner to use for execution |

## Supported Linters

### Prettier

Prettier checks code formatting for the following file types:
- JavaScript (`.js`, `.jsx`)
- TypeScript (`.ts`, `.tsx`)
- JSON (`.json`)
- CSS/SCSS (`.css`, `.scss`)
- Markdown (`.md`)
- YAML (`.yml`, `.yaml`)

Prettier runs with the `--check` flag, which means it will fail if any files are not properly formatted. It does not modify files, only reports formatting issues.

### ShellCheck

ShellCheck analyzes shell scripts for common errors and best practices. It checks the following file types:
- Shell scripts (`.sh`)
- Bash scripts (`.bash`)
- Zsh scripts (`.zsh`)

ShellCheck will fail if it detects any issues in the shell scripts, helping to catch potential bugs and security issues before they reach production.
