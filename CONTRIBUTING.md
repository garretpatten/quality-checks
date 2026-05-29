# Contributing

Participants are expected to follow the [Code of Conduct](./CODE_OF_CONDUCT.md).

## Issues

Security vulnerabilities are **not** tracked in public issues until addressed; see **[SECURITY.md](./SECURITY.md)**.

Use [GitHub Issues](https://github.com/garretpatten/quality-checks/issues) with the **Bug report** or **Feature request** form. Include the consumer workflow snippet, failing job logs (redacted), and the pinned workflow ref you use.

## Pull requests

- Branch from **`master`**, focused scope per PR.
- Pin third-party actions to full commit SHAs; let Dependabot propose bumps.
- Keep linters **PR-scoped** and opt-in via `*_run` inputs; document breaking workflow input changes in the README.
- When adding a linter, follow the existing changed-files pattern and update the README tables.

### Checks (from repo root)

Agents and contributors should run linters on **changed files** before opening or
updating a PR. See **[AGENTS.md](./AGENTS.md)** for the full matrix.

```bash
npm install
npm run lint:changed
```

For a full-repo pass (or when many areas changed):

```bash
npm run lint
```

Install optional tools listed in **AGENTS.md** when `lint-changed` reports a skip.
**`npm run lint`** mirrors CI **Suite 1 — Linters**; Suite 2 (accessibility) runs in
CI via `test-workflow.yaml`.

Shell script changes require **shfmt** and **shellcheck** (`brew install shfmt shellcheck`,
or `npm run lint:shell` after installing shfmt).

Documentation-only changes still need **Prettier** and **Markdownlint** on touched
Markdown files.
