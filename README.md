# Quality Checks

## Table of Contents

- [Overview](#overview)
- [Example Consumer Workflow](#example-consumer-workflow)
- [Reusable Workflow Architecture](#reusable-workflow-architecture)
- [Input Parameters](#input-parameters)
- [Supported Linters](#supported-linters)

## Overview

This repository contains a reusable GitHub Actions workflow that performs quality checks on code in pull requests. The workflow runs linters (Actionlint, ESLint, Hadolint, jq, Markdownlint, Prettier, Ruff, ShellCheck, Taplo, and Yamllint) on committed code changes and fails if any linting errors are detected.

## Example Consumer Workflow

To use this reusable workflow in your repository, create a workflow file (e.g., `.github/workflows/quality-checks.yml`) that calls it:

```yaml
name: 'Quality Checks'

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

This repository contains a [reusable workflow](https://docs.github.com/en/actions/using-workflows/reusing-workflows) located at [.github/workflows/quality-checks.yml](.github/workflows/quality-checks.yml). The workflow is designed to perform essential quality checks across projects by running linters on code changes in pull requests.

The workflow checks only the files that have been changed in the pull request, making it efficient and focused on the code being reviewed.

## Input Parameters

| Parameter          | Type    | Required | Default | Description                                            |
| ------------------ | ------- | -------- | ------- | ------------------------------------------------------ |
| `actionlint_run`   | boolean | No       | `true`  | Whether to run the Actionlint GitHub Actions linter    |
| `eslint_run`       | boolean | No       | `true`  | Whether to run the ESLint JavaScript/TypeScript linter |
| `hadolint_run`     | boolean | No       | `true`  | Whether to run the Hadolint Dockerfile linter          |
| `jq_run`           | boolean | No       | `true`  | Whether to run the jq JSON validator                   |
| `markdownlint_run` | boolean | No       | `true`  | Whether to run the Markdownlint Markdown linter        |
| `prettier_run`     | boolean | No       | `true`  | Whether to run the Prettier code formatter check       |
| `ruff_run`         | boolean | No       | `true`  | Whether to run the Ruff Python linter                  |
| `shellcheck_run`   | boolean | No       | `true`  | Whether to run the ShellCheck shell script linter      |
| `taplo_run`        | boolean | No       | `true`  | Whether to run the Taplo TOML linter                   |
| `yamllint_run`     | boolean | No       | `true`  | Whether to run the Yamllint YAML linter                |

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

jq will fail if it detects any syntax errors in JSON files. The `jq -e .` command reads the JSON file and exits with a non-zero status code if the JSON is invalid, making it an effective JSON validator.

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

Prettier runs with the `--check` flag, which means it will fail if any files are not properly formatted. It does not modify files, only reports formatting issues.

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

ShellCheck will fail if it detects any issues in the shell scripts, helping to catch potential bugs and security issues before they reach production.

### Taplo

Taplo is a fast and feature-complete TOML toolkit that includes a linter for TOML files. It checks the following file types:

- TOML files (`.toml`)

Taplo will fail if it detects any syntax errors or linting issues in TOML files. The workflow will use a local Taplo configuration if one exists in the repository (via `taplo.toml` or `pyproject.toml`), otherwise it will use Taplo's default configuration.

### Yamllint

Yamllint is a linter for YAML files that checks for syntax validity, key repetition, and cosmetic problems. It checks the following file types:

- YAML files (`.yml`, `.yaml`)

Yamllint will fail if it detects any syntax errors or linting issues in YAML files. The workflow will use a local Yamllint configuration if one exists in the repository (via `.yamllint`, `.yamllint.yml`, or `.yamllint.yaml`), otherwise it will use Yamllint's default configuration.
