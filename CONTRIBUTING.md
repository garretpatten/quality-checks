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

```bash
npm install
npm run lint
```

Or step by step:

```bash
npx prettier --check .
npx markdownlint-cli2 "**/*.md" "#node_modules"
yamllint .github .yamllint .markdownlint.yaml
actionlint
```

Install **actionlint** and **yamllint** locally if missing (`brew install actionlint`, `pip install yamllint`). **`npm run lint`** mirrors CI **Suite 1 — Linters** for this repository.

Documentation-only changes still need **Prettier** and **Markdownlint** on touched Markdown files.
