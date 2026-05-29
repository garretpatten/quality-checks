# Agent guide — quality-checks

Reusable GitHub Actions for **Suite 1 (linters)** and **Suite 2 (accessibility)** on
pull-request diffs. Keep workflows **opt-in**, **PR-scoped**, and **pinned to commit
SHAs** for third-party actions.

## Repository layout

| Path                                          | Purpose                                      |
| --------------------------------------------- | -------------------------------------------- |
| `.github/workflows/quality-checks.yaml`       | Reusable linter workflow (Suite 1)           |
| `.github/workflows/accessibility-checks.yaml` | Reusable axe + Lighthouse workflow (Suite 2) |
| `.github/workflows/test-workflow.yaml`        | Self-test on PRs (both suites)               |
| `.github/scripts/qc-resolve-base.sh`          | Shared diff-base resolution for jobs         |
| `scripts/lint-changed.sh`                     | Run local linters matching changed files     |
| `docs/assets/`                                | Branding (logo SVG)                          |
| `docs/fixtures/a11y-sample.html`              | axe self-test fixture                        |

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

**You must run linters that apply to every file you changed before finalizing work**
(summary, handoff, or commit). Do not skip this step.

### Preferred: changed-files script

From the repository root:

```bash
npm install
./scripts/lint-changed.sh
```

This runs only the checks relevant to your diff (vs `origin/master` / `origin/main`,
plus unstaged and staged changes). Override the base ref:

```bash
LINT_BASE=origin/main ./scripts/lint-changed.sh
```

Or via npm:

```bash
npm run lint:changed
```

### Full repo lint (when unsure or many file types changed)

```bash
npm install
npm run lint
```

### If you edited … run …

| Paths you changed                                                                  | Required local checks                                                     |
| ---------------------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Any `*.md`                                                                         | `npx prettier --check <files>` then `npm run lint:md` (or `npm run lint`) |
| `.github/workflows/*.yaml`, `test-workflow.yaml`                                   | `npm run lint:yaml`, `npm run lint:workflows`                             |
| `.github/ISSUE_TEMPLATE/**`, `dependabot.yaml`, `.yamllint`, `.markdownlint*.yaml` | `npm run lint:yaml`                                                       |
| `.github/scripts/*.sh`, `scripts/*.sh`                                             | `npm run lint:shell`, `shellcheck <files>`                                |
| `*.html`                                                                           | `./scripts/lint-changed.sh` (axe if CLI installed) or rely on CI Suite 2  |
| `package.json`, `package-lock.json`                                                | `npm run lint`                                                            |
| Workflow inputs / README tables                                                    | Keep **README.md** and workflow `inputs` in sync; run `npm run lint`      |

### Suite mapping (CI vs local)

| Suite                 | CI workflow                                   | Local equivalent                                                                                                      |
| --------------------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| **1 — Linters**       | `test-workflow` → `quality-checks.yaml`       | `npm run lint`, `./scripts/lint-changed.sh`                                                                           |
| **2 — Accessibility** | `test-workflow` → `accessibility-checks.yaml` | axe on changed `.html` via `lint-changed.sh`; Lighthouse needs deployed `urls` (CI only unless you pass URLs locally) |

### Tool install (if a script reports “skipped”)

| Tool                            | Install                                                                                                     |
| ------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **actionlint**                  | `brew install actionlint`                                                                                   |
| **yamllint**                    | `pip install yamllint`                                                                                      |
| **shfmt**                       | `brew install shfmt`                                                                                        |
| **shellcheck**                  | `brew install shellcheck`                                                                                   |
| **typos**                       | `brew install typos-cli`                                                                                    |
| **editorconfig-checker** (`ec`) | [releases](https://github.com/editorconfig-checker/editorconfig-checker/releases) (`ec-linux-amd64` binary) |
| **axe-core CLI**                | `source .github/scripts/qc-axe-setup.sh` (syncs Chrome + ChromeDriver)                                      |

### Checklist before handoff

- [ ] `./scripts/lint-changed.sh` (or `npm run lint:changed`) exits 0
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
