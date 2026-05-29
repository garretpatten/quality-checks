# Agent guide — quality-checks

Reusable GitHub Actions for **Linters** and **Accessibility Audits** on pull-request
diffs. Keep workflows **opt-in**, **PR-scoped**, and **pinned to commit SHAs** for
third-party actions.

## Repository layout

| Path                                          | Purpose                                  |
| --------------------------------------------- | ---------------------------------------- |
| `.github/workflows/quality-checks.yaml`       | Reusable linter workflow                 |
| `.github/workflows/accessibility-checks.yaml` | Reusable axe + Lighthouse workflow       |
| `.github/workflows/test-workflow.yaml`        | Self-test on PRs (both workflows)        |
| `.github/scripts/qc-resolve-base.sh`          | Shared diff-base resolution for jobs     |
| `scripts/lint-changed.sh`                     | Run local linters matching changed files |
| `docs/assets/`                                | Branding (logo SVG)                      |
| `docs/fixtures/a11y-sample.html`              | axe self-test fixture                    |

## Workflow conventions

1. **Pin actions** to full commit SHAs; let Dependabot open bump PRs.
2. **Reusable workflow inputs** must stay documented in **README.md**; breaking
   renames need a migration note.
3. **Shell in workflows**: quote variables, use `env:` for `${{ inputs.* }}` in
   `run:` steps (never interpolate inputs directly into shell).
4. **Changed-files pattern**: new linter jobs should use `.github/scripts/qc-resolve-base.sh`
   and skip when no matching paths exist.
5. **Line length**: `.yamllint` max 80 columns; `# yamllint disable-line` only for
   long action SHAs.

Do not commit unless the user asks.

## Linter ownership (avoid conflicts)

These three tools are canonical; others must not fight them:

| Tool             | Owns                                   | Does not run on                                            |
| ---------------- | -------------------------------------- | ---------------------------------------------------------- |
| **Prettier**     | Markdown, JSON, HTML, JS/TS, CSS       | `*.yaml` / `*.yml` (see `.prettierignore`)                 |
| **markdownlint** | Markdown structure and semantics       | Line length, raw HTML badges (`MD013`/`MD033`/`MD041` off) |
| **yamllint**     | All YAML under `.github/`, config YAML | —                                                          |

Run **Prettier before markdownlint** on Markdown. Never run Prettier on YAML in this
repo. **typos** runs on Markdown/plain-text/docs only (not YAML, code, or JSON) and
loads the repo’s `typos.toml` when present (see `.github/scripts/qc-typos-args.sh`).
Optional tools (**editorconfig**, **shfmt**) must not rewrite Markdown or YAML.

## Verify before you finish (required)

**You must run Prettier and markdownlint on every task in this repository**, even when
you only changed workflows or scripts. Tables and README badges drift easily; CI always
checks all Markdown.

### 1. Format and lint Markdown (always)

From the repository root:

```bash
npm install
npm run fix:docs
```

`fix:docs` runs `prettier --write` on all `**/*.md`, then `markdownlint-cli2`. To check
without writing:

```bash
npm run lint:docs
```

### 2. Other linters for files you touched

```bash
./scripts/lint-changed.sh
```

Or the full Linters pass:

```bash
npm run lint
```

`lint-changed.sh` ends with the same Prettier + markdownlint gate on all Markdown.

Override the git base for changed-file detection:

```bash
LINT_BASE=origin/main ./scripts/lint-changed.sh
```

### If you edited … also run …

| Paths you changed                                                                  | Additional checks                                                       |
| ---------------------------------------------------------------------------------- | ----------------------------------------------------------------------- |
| `.github/workflows/*.yaml`, `test-workflow.yaml`                                   | `npm run lint:yaml`, `npm run lint:workflows`                           |
| `.github/ISSUE_TEMPLATE/**`, `dependabot.yaml`, `.yamllint`, `.markdownlint*.yaml` | `npm run lint:yaml`                                                     |
| `.github/scripts/*.sh`, `scripts/*.sh`                                             | `npm run lint:shell` (`shfmt` + `shellcheck -x` on all scripts)         |
| `*.html`                                                                           | axe via `lint-changed.sh` (optional locally) or CI Accessibility Audits |
| Workflow inputs / README tables                                                    | Keep **README.md** and workflow `inputs` in sync                        |

### Workflow mapping (CI vs local)

| Workflow                 | CI workflow                                   | Local equivalent                                                                                                      |
| ------------------------ | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **Linters**              | `test-workflow` → `quality-checks.yaml`       | `npm run lint` (includes `lint:docs`)                                                                                 |
| **Accessibility Audits** | `test-workflow` → `accessibility-checks.yaml` | axe on changed `.html` via `lint-changed.sh`; Lighthouse needs deployed `urls` (CI only unless you pass URLs locally) |

### Tool install (if a script reports “skipped”)

| Tool                            | Install                                                                                                     |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **actionlint**                  | `brew install actionlint` (CI uses `.github/scripts/qc-actionlint-setup.sh`, pinned `1.7.12`)               |
| **yamllint**                    | `pip install yamllint`                                                                                      |
| **shfmt**                       | `brew install shfmt`                                                                                        |
| **shellcheck**                  | `brew install shellcheck`                                                                                   |
| **typos**                       | `brew install typos-cli`                                                                                    |
| **editorconfig-checker** (`ec`) | [releases](https://github.com/editorconfig-checker/editorconfig-checker/releases) (`ec-linux-amd64` binary) |
| **axe-core CLI**                | `source .github/scripts/qc-axe-setup.sh` (syncs Chrome + ChromeDriver)                                      |

### Checklist before handoff

- [ ] **`npm run fix:docs`** exits 0 (or `npm run lint:docs` if you did not need to write)
- [ ] **`npm run lint:shell`** exits 0 when you changed `.github/scripts/*.sh` or `scripts/*.sh` (use
      `shellcheck -x` so sourced helpers are analyzed)
- [ ] **`npm run lint`** or **`./scripts/lint-changed.sh`** exits 0 when you changed workflows, shell, or config
- [ ] If workflows or inputs changed, README tables updated
- [ ] New third-party actions use full commit SHAs
- [ ] No secrets or personal data in logs or fixtures

## Making changes

| Task                              | Edit                                                      |
| --------------------------------- | --------------------------------------------------------- |
| Linter job / input                | `.github/workflows/quality-checks.yaml` + README          |
| Accessibility job / input         | `.github/workflows/accessibility-checks.yaml` + README    |
| Self-test                         | `.github/workflows/test-workflow.yaml`                    |
| Agent / contributor lint guidance | `AGENTS.md`, `CONTRIBUTING.md`, `scripts/lint-changed.sh` |
| Community files                   | `SECURITY.md`, `CODE_OF_CONDUCT.md`, issue templates      |

## License

MIT — see [LICENSE](./LICENSE).
