#!/usr/bin/env bats
# Reusable workflows must load qc-*.sh helpers from this repository's
# checkout, not from the caller's workspace. PR #41 sourced them from
# .github/scripts/ in GITHUB_WORKSPACE, which only exists in
# quality-checks itself.
# shellcheck disable=SC2030,SC2031

setup() {
	load ../helpers/setup
	common_setup
	QC_WF="${REPO_ROOT}/.github/workflows/quality-checks.yaml"
	A11Y_WF="${REPO_ROOT}/.github/workflows/accessibility-checks.yaml"
	export QC_WF A11Y_WF
}

teardown() {
	common_teardown
}

@test "reusable workflows do not source qc helpers from the caller tree" {
	# Comments may mention the canonical repo path; run: bodies must not.
	run grep -nE \
		'^[[:space:]]+(source[[:space:]]+|\.[[:space:]])+\.github/scripts/qc-|^[[:space:]]+\.github/scripts/qc-' \
		"${QC_WF}" "${A11Y_WF}"
	assert_failure
	assert_output ""
}

@test "reusable workflows do not use the empty github.job_workflow_sha context" {
	run grep -n 'github.job_workflow_sha' "${QC_WF}" "${A11Y_WF}"
	assert_failure
	assert_output ""
}

@test "jobs that use helpers check out tooling at job.workflow_sha" {
	run python3 - "${QC_WF}" "${A11Y_WF}" <<'PY'
import re
import sys
from pathlib import Path

required = {
    "repository: ${{ job.workflow_repository }}",
    "ref: ${{ job.workflow_sha }}",
    "path: .qc-tooling",
    "persist-credentials: false",
    "sparse-checkout: .github/scripts",
}
checkout_sha = "3d3c42e5aac5ba805825da76410c181273ba90b1"
errors = []

for path in sys.argv[1:]:
    text = Path(path).read_text()
    m = re.search(r"^jobs:\n", text, re.M)
    if not m:
        errors.append(f"{path}: no jobs: key")
        continue
    body = text[m.end():]
    job_iter = list(re.finditer(r"^  ([A-Za-z0-9_-]+):\n", body, re.M))
    for i, match in enumerate(job_iter):
        name = match.group(1)
        start = match.start()
        end = job_iter[i + 1].start() if i + 1 < len(job_iter) else len(body)
        block = body[start:end]
        uses_helpers = "QC_SCRIPTS" in block and (
            'source "${QC_SCRIPTS}/' in block or '"${QC_SCRIPTS}/qc-' in block
        )
        if name == "stylua":
            if "Checkout quality-checks tooling" in block or "QC_SCRIPTS:" in block:
                errors.append(
                    f"{path} job {name}: stylua should not check out tooling"
                )
            continue
        if not uses_helpers:
            if "source " in block and "qc-" in block:
                errors.append(
                    f"{path} job {name}: helper source without QC_SCRIPTS"
                )
            continue
        if "Checkout quality-checks tooling" not in block:
            errors.append(f"{path} job {name}: missing tooling checkout")
            continue
        if (
            "QC_SCRIPTS: ${{ github.workspace }}/.qc-tooling/.github/scripts"
            not in block
        ):
            errors.append(f"{path} job {name}: missing QC_SCRIPTS env")
        if f"uses: actions/checkout@{checkout_sha}" not in block:
            errors.append(f"{path} job {name}: tooling checkout SHA mismatch")
        for item in required:
            if item not in block:
                errors.append(f"{path} job {name}: missing `{item}`")
        caller = block.find("- name: 'Checkout Code'")
        tooling = block.find("- name: 'Checkout quality-checks tooling'")
        first_source = block.find('source "${QC_SCRIPTS}/')
        first_exec = block.find('"${QC_SCRIPTS}/qc-')
        uses = [n for n in (first_source, first_exec) if n >= 0]
        first_use = min(uses) if uses else -1
        if caller < 0 or tooling < 0 or first_use < 0:
            errors.append(f"{path} job {name}: missing checkout or helper use")
        elif not (caller < tooling < first_use):
            errors.append(
                f"{path} job {name}: expected caller checkout, then tooling, "
                "then source"
            )

if errors:
    print("\n".join(errors))
    sys.exit(1)
print("ok")
PY
	assert_success
	assert_output "ok"
}

@test "reusable workflows keep contents: read and do not raise permissions" {
	for wf in "${QC_WF}" "${A11Y_WF}"; do
		run grep -nE '^permissions:' "${wf}"
		assert_success
		# The only top-level permission block should be contents: read.
		run awk '
			BEGIN { take=0; bad=0; out="" }
			$0 == "permissions:" && !job {
				take=1
				next
			}
			take && $0 ~ /^  [A-Za-z0-9_-]+:/ {
				print $0
				if ($0 != "  contents: read") {
					bad=1
				}
			}
			take && ($0 == "" || $0 ~ /^[^ ]/) { take=0 }
			END { exit bad+0 }
		' "${wf}"
		assert_success
		assert_output "  contents: read"
	done
}
