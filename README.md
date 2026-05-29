<p align="center">
    <img
        src="./docs/assets/quality-checks-mark.svg"
        alt="Quality Checks logo"
        width="96"
        height="96"
    />
</p>

<h1 align="center">Quality Checks</h1>

<p align="center">
    <strong>Reusable GitHub Actions for PR-scoped linting and accessibility audits.</strong>
</p>

<p align="center">
    Suite 1 runs opt-in linters only on changed files. Suite 2 runs axe-core and
    Lighthouse CI against deployed URLs and/or local HTML — tuned for fast,
    actionable feedback in pull requests.
</p>

<p align="center">
    <a href="./LICENSE"
        ><img
            src="https://img.shields.io/github/license/garretpatten/quality-checks?style=flat-square"
            alt="License: MIT"
    /></a>
    <img
        src="https://img.shields.io/badge/scope-PR%20diff-059669?style=flat-square"
        alt="PR-scoped checks"
    />
    <img
        src="https://img.shields.io/badge/Suite%201-linters-10b981?style=flat-square&logo=githubactions&logoColor=white"
        alt="Suite 1: Linters"
    />
    <img
        src="https://img.shields.io/badge/Suite%202-a11y-7c3aed?style=flat-square&logo=lighthouse&logoColor=white"
        alt="Suite 2: Accessibility"
    />
</p>

<p align="center">
    <a href="https://github.com/garretpatten/quality-checks/actions/workflows/test-workflow.yaml"
        ><img
            src="https://img.shields.io/github/actions/workflow/status/garretpatten/quality-checks/test-workflow.yaml?branch=master&label=CI&logo=github&style=flat-square"
            alt="Test workflow status"
    /></a>
    <a href="https://github.com/garretpatten/quality-checks/blob/master/CODE_OF_CONDUCT.md"
        ><img
            src="https://img.shields.io/badge/Community-Standards-2563eb?style=flat-square"
            alt="GitHub Community Standards"
    /></a>
</p>

<p align="center">
    ✓ Opt-in linters &nbsp;
    ✓ Changed-files only &nbsp;
    ✓ axe-core + Lighthouse &nbsp;
    ✓ Consumer-friendly inputs &nbsp;
    ✓ MIT licensed
</p>

---

## Overview

**Quality Checks** provides two [reusable
workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
for pull requests:

| Suite                 | Workflow                                                                     | Purpose                                      |
| --------------------- | ---------------------------------------------------------------------------- | -------------------------------------------- |
| **1 — Linters**       | [`quality-checks.yaml`](./.github/workflows/quality-checks.yaml)             | Language and config linters on the PR diff   |
| **2 — Accessibility** | [`accessibility-checks.yaml`](./.github/workflows/accessibility-checks.yaml) | axe-core and Lighthouse accessibility audits |

Each tool is **opt-in** (`*_run` defaults to `false`). Jobs no-op when nothing
relevant changed, keeping runs fast.

## Quick start

### Suite 1 — Linters

```yaml
name: 'Quality Checks'

on: pull_request

jobs:
  linters:
    name: 'Suite 1 — Linters'
    uses: garretpatten/quality-checks/.github/workflows/quality-checks.yaml@master
    with:
      diff_base: ${{ github.event.pull_request.base.sha }}
      actionlint_run: true
      editorconfig_run: true
      eslint_run: true
      hadolint_run: true
      jq_run: true
      markdownlint_run: true
      prettier_run: true
      ruff_run: true
      shellcheck_run: true
      shfmt_run: true
      taplo_run: true
      typos_run: true
      yamllint_run: true
    secrets: inherit
```

### Suite 2 — Accessibility

```yaml
name: 'Accessibility Checks'

on: pull_request

jobs:
  accessibility:
    name: 'Suite 2 — Accessibility'
    uses: garretpatten/quality-checks/.github/workflows/accessibility-checks.yaml@master
    with:
      axe_run: true
      lighthouse_run: true
      urls: |
        https://your-preview.example.com/
      local_html_paths: |
        docs/index.html
      lighthouse_min_accessibility: '0.9'
    secrets: inherit
```

**Pin a commit SHA** instead of `@master` for supply-chain control:

```yaml
uses: garretpatten/quality-checks/.github/workflows/quality-checks.yaml@<full-commit-sha>
```

### Comparing against the correct base commit

By default, workflows diff against `origin/main`, then `origin/master`, otherwise
`HEAD~1`. For pull requests, pin the merge base:

```yaml
with:
  diff_base: ${{ github.event.pull_request.base.sha }}
```

## Suite 1 — Linter inputs

| Parameter           | Type    | Default     | Description                                   |
| ------------------- | ------- | ----------- | --------------------------------------------- |
| `diff_base`         | string  | _(empty)_   | Git ref to diff against                       |
| `node_version`      | string  | `20`        | Node.js for ESLint, markdownlint, Prettier    |
| `go_version`        | string  | `stable`    | Go toolchain for golangci-lint                |
| `stylua_args`       | string  | `--check .` | Arguments for StyLua                          |
| `stylua_version`    | string  | `v2.4.1`    | StyLua release tag                            |
| `actionlint_run`    | boolean | `false`     | GitHub Actions workflow linter                |
| `editorconfig_run`  | boolean | `false`     | EditorConfig consistency                      |
| `eslint_run`        | boolean | `false`     | ESLint (JS/TS)                                |
| `golangci_lint_run` | boolean | `false`     | golangci-lint (`--new-from-rev`)              |
| `hadolint_run`      | boolean | `false`     | Dockerfile linter                             |
| `jq_run`            | boolean | `false`     | JSON syntax validation                        |
| `markdownlint_run`  | boolean | `false`     | Markdownlint-cli2                             |
| `prettier_run`      | boolean | `false`     | Prettier format check                         |
| `ruff_run`          | boolean | `false`     | Ruff (Python)                                 |
| `shellcheck_run`    | boolean | `false`     | ShellCheck                                    |
| `shfmt_run`         | boolean | `false`     | shfmt shell formatting                        |
| `stylua_run`        | boolean | `false`     | StyLua (Lua)                                  |
| `taplo_run`         | boolean | `false`     | Taplo (TOML)                                  |
| `typos_run`         | boolean | `false`     | typos spell checker                           |
| `typos_config`      | string  | _(empty)_   | Path to `typos.toml` (auto-detected if empty) |
| `yamllint_run`      | boolean | `false`     | Yamllint                                      |

## Suite 2 — Accessibility inputs

| Parameter                      | Type    | Default   | Description                                           |
| ------------------------------ | ------- | --------- | ----------------------------------------------------- |
| `diff_base`                    | string  | _(empty)_ | Git ref for changed `.html` detection                 |
| `node_version`                 | string  | `20`      | Node.js for axe-core CLI                              |
| `axe_run`                      | boolean | `false`   | Run axe-core audits                                   |
| `lighthouse_run`               | boolean | `false`   | Run Lighthouse CI (accessibility category)            |
| `urls`                         | string  | _(empty)_ | URLs to audit (one per line; required for Lighthouse) |
| `local_html_paths`             | string  | _(empty)_ | Extra repo HTML paths served locally for axe          |
| `lighthouse_min_accessibility` | string  | `0.9`     | Minimum Lighthouse accessibility score (0–1)          |
| `static_server_port`           | string  | `8765`    | Port for local HTML serving                           |

If the consumer repo already has `lighthouserc.json` or `lighthouserc.js`, that
config is used instead of the generated accessibility-only defaults.

## Supported linters (Suite 1)

| Tool              | Files                                  | Notes                                             |
| ----------------- | -------------------------------------- | ------------------------------------------------- |
| **Actionlint**    | `.github/workflows`, `.github/actions` | GitHub Actions-specific rules                     |
| **EditorConfig**  | Changed text files                     | Uses `ec`; respects `.editorconfig`               |
| **ESLint**        | `.js`, `.jsx`, `.ts`, `.tsx`           | Installs `npm ci` when `package.json` exists      |
| **golangci-lint** | Go packages                            | `--new-from-rev` on PR diff                       |
| **Hadolint**      | `Dockerfile`, `*.dockerfile`           | Dockerfile best practices                         |
| **jq**            | `.json`                                | Syntax validation (`jq -e`)                       |
| **Markdownlint**  | `.md`, `.markdown`                     | markdownlint-cli2                                 |
| **Prettier**      | JS/TS, JSON, CSS, MD                   | Format check; honors `.prettierignore` (not YAML) |
| **Ruff**          | `.py`, `.pyw`                          | Python lint                                       |
| **ShellCheck**    | `.sh`, `.bash`, `.zsh`                 | Shell analysis (runner image binary)              |
| **shfmt**         | `.sh`, `.bash`, `.zsh`                 | Shell formatting (`-d`)                           |
| **StyLua**        | Lua (via `stylua_args`)                | Whole-tree or path-scoped                         |
| **Taplo**         | `.toml`                                | TOML lint                                         |
| **typos**         | `.md`, `.txt`, `.rst`, `.html`, …      | Prose spell check; uses your repo’s `typos.toml`  |
| **Yamllint**      | `.yml`, `.yaml`                        | General YAML lint                                 |

### typos.toml in consumer repositories

When `typos_run: true`, the job checks out **your** repository and runs `typos` from
its root. Your `typos.toml` (or `_typos.toml` / `.typos.toml`) is loaded automatically
so you can allow names, product terms, and other valid words:

```toml
[default.extend-words]
Patten = "Patten"
MyProduct = "MyProduct"
```

Copy [docs/typos.toml.example](./docs/typos.toml.example) as a starting point. For a
config file outside the root, pass `typos_config: path/to/typos.toml` in the workflow
`with:` block.

### Intentional overlap (not redundant)

- **jq** validates JSON syntax; **Prettier** enforces formatting — enable both for JSON-heavy repos.
- **Markdownlint** enforces Markdown style; **Prettier** formats Markdown — complementary.
- **Yamllint** owns YAML formatting and lint; **Prettier** does not format `.yml`/`.yaml`
  in this workflow (they conflict on quote style and wrapping).
- **Actionlint** targets GitHub Actions semantics; **Yamllint** covers all YAML — use both for workflows.
- **ShellCheck** finds shell bugs; **shfmt** enforces layout — complementary.

### What we deliberately omit

Tools that duplicate Ruff/ESLint/Prettier for the same languages (e.g. Flake8, Black,
Biome-as-full-replacement) or need heavy language SDKs (RuboCop, Clippy, `terraform validate`)
are out of scope so the workflow stays maintainable. Open an issue if you need a
narrow, high-signal addition.

## Accessibility (Suite 2)

| Job            | Tool                                                           | When to use                                                     |
| -------------- | -------------------------------------------------------------- | --------------------------------------------------------------- |
| **axe-core**   | [@axe-core/cli](https://www.npmjs.com/package/@axe-core/cli)   | WCAG checks; CI syncs ChromeDriver via `browser-driver-manager` |
| **Lighthouse** | [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) | Accessibility category score gate on deployed URLs              |

### Typical patterns

- **Static site / docs**: set `axe_run: true` and rely on changed `.html` plus
  optional `local_html_paths`.
- **Web app with preview**: pass the preview URL in `urls` for both axe and
  Lighthouse.
- **Production smoke**: `urls` only, on a schedule or after deploy (call the
  reusable workflow from `workflow_dispatch` or `deployment_status`).

## Related projects

- [Security Guardrails](https://github.com/garretpatten/security-guardrails) —
  companion repo for SAST, secrets, and supply-chain checks.

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Security reports: [SECURITY.md](./SECURITY.md).
Conduct: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

## License

[MIT](./LICENSE) — Copyright (c) 2025 Garret Patten
