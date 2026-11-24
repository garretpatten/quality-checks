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
    Linters turn themselves on from the pull-request diff. Accessibility
    Audits run axe-core and Lighthouse CI against deployed URLs and/or local
    HTML — tuned for fast, actionable feedback in pull requests.
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
        src="https://img.shields.io/badge/Linters-10b981?style=flat-square&logo=githubactions&logoColor=white"
        alt="Linters"
    />
    <img
        src="https://img.shields.io/badge/Accessibility%20Audits-7c3aed?style=flat-square&logo=lighthouse&logoColor=white"
        alt="Accessibility Audits"
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
    ✓ Auto-detected linters &nbsp;
    ✓ Changed-files only &nbsp;
    ✓ One required check &nbsp;
    ✓ axe-core + Lighthouse &nbsp;
    ✓ MIT licensed
</p>

---

## Overview

**Quality Checks** provides two [reusable
workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
for pull requests:

| Workflow                 | Reusable workflow                                                            | Purpose                                      |
| ------------------------ | ---------------------------------------------------------------------------- | -------------------------------------------- |
| **Linters**              | [`quality-checks.yaml`](./.github/workflows/quality-checks.yaml)             | Language and config linters on the PR diff   |
| **Accessibility Audits** | [`accessibility-checks.yaml`](./.github/workflows/accessibility-checks.yaml) | axe-core and Lighthouse accessibility audits |

A `detect` job classifies the pull-request diff, and each tool job turns
itself on when its files changed. Branch protection only needs one required
check per workflow: the stable **`checks`** summary job.

## Quick start

### Linters

```yaml
name: 'Quality Checks'

on: pull_request

jobs:
  linters:
    name: 'Linters'
    uses: garretpatten/quality-checks/.github/workflows/quality-checks.yaml@v2
    with:
      diff_base: ${{ github.event.pull_request.base.sha }}
```

### Accessibility Audits

```yaml
name: 'Accessibility Checks'

on: pull_request

jobs:
  accessibility:
    name: 'Accessibility Audits'
    uses: garretpatten/quality-checks/.github/workflows/accessibility-checks.yaml@v2
    with:
      urls: |
        https://your-preview.example.com/
      local_html_paths: |
        docs/index.html
      lighthouse_min_accessibility: '0.9'
```

**Pin a commit SHA** instead of a tag for supply-chain control:

```yaml
uses: garretpatten/quality-checks/.github/workflows/quality-checks.yaml@<full-commit-sha>
```

No secrets are needed. The workflows never accept `secrets: inherit`; they
run with the automatically generated read-only `github.token` scope.

The reusable workflows also check out this repository at
`job.workflow_sha` into `.qc-tooling` so the helper scripts under
`.github/scripts/` are available when the caller is a different
repository. Callers do not need to vendor those scripts. The ref you pin
(a commit SHA or `@v2`) selects both the workflow and the matching
helpers.

### One required check

Require a single context per workflow in branch protection — the names are
stable even as tools are added or removed. The prefix is the calling job's
display name; in this fleet that is:

- **`Linters / checks`**
- **`Accessibility Audits / checks`** (optional)

The summary jobs always run (so the context is reported even when tool jobs
were skipped) and fail explicitly when any needed job failed or the run was
cancelled.

### Comparing against the correct base commit

By default the workflows auto-detect the default branch of `origin` (any
name, not just `main`/`master`) and diff the merge base. For pull requests,
pin the merge base explicitly:

```yaml
with:
  diff_base: ${{ github.event.pull_request.base.sha }}
```

When auto-detection fails, the workflow falls back to `origin/main`, then
`origin/master`, then `HEAD~1`, emitting a `::warning::` annotation so
under-linting is never silent.

## How tools turn on

The `detect` job diffs the pull request (added/copied/modified/renamed
files, vendor and build-output paths excluded) and classifies each path:

| Changed files                                               | Jobs started                  |
| ----------------------------------------------------------- | ----------------------------- |
| `.js` `.jsx` `.ts` `.tsx` `.mjs` `.cjs` `.mts` `.cts`       | ESLint, Prettier              |
| `.json`                                                     | Prettier, jq                  |
| `.md` `.markdown`                                           | Prettier, markdownlint, typos |
| `.css` `.scss`                                              | Prettier                      |
| `.yaml` `.yml`                                              | yamllint                      |
| `.sh` `.bash` `.zsh`, shebang-detected extensionless        | ShellCheck, shfmt             |
| `.py` `.pyw`                                                | Ruff                          |
| `.toml`                                                     | Taplo                         |
| `Dockerfile`, `*.dockerfile`                                | Hadolint                      |
| `.go`                                                       | golangci-lint                 |
| `.github/workflows/*.yaml`                                  | actionlint                    |
| `.lua`                                                      | StyLua                        |
| `.txt` `.rst` `.adoc` `.html`, `LICENSE`/`COPYING`/`NOTICE` | typos                         |
| any changed file                                            | EditorConfig                  |

A PR touching only `init.lua` runs exactly two tool jobs (StyLua,
EditorConfig) plus `detect` and `checks`; a PR touching nothing relevant
runs `detect` and `checks` only.

## Linter inputs

| Parameter   | Type   | Default   | Description                                                    |
| ----------- | ------ | --------- | -------------------------------------------------------------- |
| `diff_base` | string | _(empty)_ | Git ref to diff against; empty auto-detects the default branch |

Tool versions are pinned in the workflow file (one `QC_*_VERSION` env
block) and updated deliberately via PRs — consumer runs are reproducible
and cannot break overnight from an upstream release.

### Repo-local tool resolution

Node-based jobs prefer the repository's own pinned tools: when
`node_modules` contains the tool after dependency install, the job runs
`npx --no-install <tool>`; otherwise it falls back to the pinned global.
Dependencies are installed with `npm ci` when a lockfile exists, with
`npm install --no-save` otherwise, and skipped without `package.json`.

## Accessibility inputs

| Parameter                             | Type    | Default   | Description                                              |
| ------------------------------------- | ------- | --------- | -------------------------------------------------------- |
| `diff_base`                           | string  | _(empty)_ | Git ref for changed `.html` detection                    |
| `urls`                                | string  | _(empty)_ | URLs to audit (one per line; required for Lighthouse)    |
| `local_html_paths`                    | string  | _(empty)_ | Newline-separated repo HTML paths served locally for axe |
| `lighthouse_min_accessibility`        | string  | `0.9`     | Minimum Lighthouse accessibility score (0–1)             |
| `lighthouse_temporary_public_storage` | boolean | `false`   | Upload the Lighthouse report to public temporary storage |

axe-core runs when the PR changes HTML or `local_html_paths` is set;
Lighthouse runs when `urls` is set. The Lighthouse report is always saved
as a private workflow-run artifact. `lighthouse_temporary_public_storage`
additionally uploads it to publicly readable temporary storage; opt in
only when the audited pages are public.

If the consumer repo already has `lighthouserc.json` or `lighthouserc.js`,
that config is used instead of the generated accessibility-only defaults.

## Supported linters

| Tool              | Files                             | Notes                                             |
| ----------------- | --------------------------------- | ------------------------------------------------- |
| **EditorConfig**  | Changed text files                | Uses `ec`; respects `.editorconfig`               |
| **actionlint**    | `.github/workflows/*.yaml`        | GitHub Actions schema and expression checks       |
| **ESLint**        | `.js`, `.mjs`, `.cjs`, `.ts`, …   | Prefers the repo's local install, then pinned 10  |
| **golangci-lint** | Go packages                       | `--new-from-rev` on PR diff                       |
| **Hadolint**      | `Dockerfile`, `*.dockerfile`      | Dockerfile best practices                         |
| **jq**            | `.json`                           | Syntax validation (`jq empty`)                    |
| **Markdownlint**  | `.md`, `.markdown`                | markdownlint-cli2                                 |
| **Prettier**      | JS/TS, JSON, CSS, MD              | Format check; honors `.prettierignore` (not YAML) |
| **Ruff**          | `.py`, `.pyw`                     | Python lint                                       |
| **ShellCheck**    | `.sh`, `.bash`, `.zsh`, shebangs  | Shell analysis (runner image binary)              |
| **shfmt**         | `.sh`, `.bash`, `.zsh`, shebangs  | Shell formatting (`-d`)                           |
| **StyLua**        | `.lua` in the diff                | `--check` on changed files only                   |
| **Taplo**         | `.toml`                           | TOML lint                                         |
| **typos**         | `.md`, `.txt`, `.rst`, `.html`, … | Prose spell check; uses your repo’s `typos.toml`  |
| **Yamllint**      | `.yml`, `.yaml`                   | General YAML lint                                 |

### typos.toml in consumer repositories

The typos job checks out **your** repository and runs `typos` from its
root. Your `typos.toml` (or `_typos.toml` / `.typos.toml`) is loaded
automatically so you can allow names, product terms, and other valid
words:

```toml
[default.extend-words]
Patten = "Patten"
MyProduct = "MyProduct"
```

Copy [docs/typos.toml.example](./docs/typos.toml.example) as a starting
point.

### Intentional overlap (not redundant)

- **jq** validates JSON syntax; **Prettier** enforces formatting — enable both for JSON-heavy repos.
- **Markdownlint** enforces Markdown style; **Prettier** formats Markdown — complementary.
- **Yamllint** owns YAML formatting and lint; **Prettier** does not format `.yml`/`.yaml`
  in this workflow (they conflict on quote style and wrapping).
- **ShellCheck** finds shell bugs; **shfmt** enforces layout — complementary.

### What we deliberately omit

Tools that duplicate Ruff/ESLint/Prettier for the same languages (e.g. Flake8, Black,
Biome-as-full-replacement) or need heavy language SDKs (RuboCop, Clippy, `terraform validate`)
are out of scope so the workflow stays maintainable. Open an issue if you need a
narrow, high-signal addition.

## Self-test fixtures

`docs/fixtures/lint-samples/` contains clean sample files (JS, Python,
shell, Dockerfile, TOML, Lua, JSON, Markdown, workflow YAML). A PR that
touches the fixture directory forces every linter's **real** path in this
repo's own CI. A weekly scheduled self-test lints the diff against the
pre-fixtures commit, so the fixture coverage runs even when no PR touches
the directory.

## Migration from v1

- The 14 `*_run` boolean inputs (`eslint_run`, `markdownlint_run`, …) are
  no longer accepted — tools auto-enable from the diff, which is the
  point. Remove them from your `with:` block.
- `typos_config`, `stylua_args`, `stylua_version`, `go_version`,
  `node_version`, and `static_server_port` inputs were removed; sensible
  pinned defaults are built in.
- The optional `token` secret was removed — StyLua is now a pinned binary
  download, so the workflows need no secrets at all.
- `urls` no longer accepts comma-separated values — one URL per line only
  (matching `local_html_paths`).
- Require the single **`Linters / checks`** context in branch
  protection instead of the individual job names.

## Accessibility

| Job            | Tool                                                           | When to use                                                     |
| -------------- | -------------------------------------------------------------- | --------------------------------------------------------------- |
| **axe-core**   | [@axe-core/cli](https://www.npmjs.com/package/@axe-core/cli)   | WCAG checks; CI syncs ChromeDriver via `browser-driver-manager` |
| **Lighthouse** | [Lighthouse CI](https://github.com/GoogleChrome/lighthouse-ci) | Accessibility category score gate on deployed URLs              |

### Typical patterns

- **Static site / docs**: rely on changed `.html` plus optional
  `local_html_paths`.
- **Web app with preview**: pass the preview URL in `urls` for both axe and
  Lighthouse.
- **Production smoke**: `urls` only, on a schedule or after deploy (call the
  reusable workflow from `workflow_dispatch` or `deployment_status`).

## Related projects

- [Security Guardrails](https://github.com/garretpatten/security-guardrails) —
  companion repo for SAST, secrets, and supply-chain checks.

## Testing

Helper scripts used by the reusable workflows and by `scripts/lint-changed.sh`
are covered by [bats-core](https://github.com/bats-core/bats-core) unit tests
under `tests/`. Each test runs in a sandbox and stubs network-facing commands,
so the suite does not need network access.

Install bats-core 1.14.0 plus `bats-support`, `bats-assert`, and `bats-file`
from release tarballs (once per clone):

```bash
./scripts/install-bats.sh
npm run test:shell
```

`install-bats.sh` writes them under `.tools/` (gitignored). If you already have
bats and the libraries installed (Homebrew, a distro package, or
`~/.local`), you can skip the installer and run `npm run test:shell` or
`bats --recursive tests`.

The `unit-tests` job in `.github/workflows/test-workflow.yaml` runs ShellCheck
on `tests/` and then `bats --recursive tests/` on every push and pull request
to `master`.

```text
tests/
├── scripts/*.bats          # scripts/lint-changed.sh
├── github-scripts/*.bats   # .github/scripts/qc-*.sh
├── workflows/*.bats        # reusable workflow helper-path contract
├── helpers/setup.bash      # sandbox, stubs, fixture git repos
├── stubs/                  # fake npm, npx, shfmt, curl, …
└── fixtures/               # changed-path lists, typo config, sample YAML
```

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). Security reports: [SECURITY.md](./SECURITY.md).
Conduct: [CODE_OF_CONDUCT.md](./CODE_OF_CONDUCT.md).

## License

[MIT](./LICENSE) — Copyright (c) 2025 Garret Patten
