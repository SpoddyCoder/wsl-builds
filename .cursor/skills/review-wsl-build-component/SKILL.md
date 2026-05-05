---
name: review-wsl-build-component
description: Review an existing wsl-builds install component against current official install instructions and repository conventions. Use when the user asks to review, audit, refresh, modernize, or check whether a build component needs updating.
---

# Review WSL Build Component

Use this skill to review an existing component and report whether it should be updated. Do not edit files unless the user explicitly asks for implementation after reviewing the summary.

## Workflow

1. Identify the target build directory and component under `builds/<name>/`. Build directories contain `conf.sh` and `install.sh`; components usually live in `install_<component>.sh`. If the scope is `builds/test-fixture` (noop harness only; see [`builds/test-fixture/README.md`](../../../builds/test-fixture/README.md)), treat as convention review only unless real install logic appeared—otherwise skip vendor/CVE deep-dives except as requested.
2. Read the target build's `conf.sh`, `install.sh`, `install_<component>.sh`, and nearby README entries.
3. Confirm the component token appears in `registerBuildMetadata`'s CSV in `conf.sh` and that `src/install-dispatch.sh` loads `install_<underscore_name>.sh` for that token (when **the builder** (`./wsl-builder.sh`) sources `install.sh`).
4. Inspect current official install instructions for the component. Prefer vendor documentation over blogs, package mirrors, or stale examples.
5. Run a security check anchored to today's date (use the date provided in the system context; confirm with `date -u +%F` if unsure). Focus on advisories from roughly the last 12 months that affect the version range the script installs:
   - vendor advisory or security page for the component (e.g. `docs.docker.com/engine/security`, `nodejs.org/en/blog/vulnerability`)
   - Ubuntu Security Notices for the underlying package: `https://ubuntu.com/security/notices.json?package=<name>`
   - OSV.dev: `POST https://api.osv.dev/v1/query` with the package and ecosystem
   - CISA Known Exploited Vulnerabilities feed: `https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json`
6. Compare the local script with current guidance, focusing on meaningful differences:
   - package repositories, signing keys, keyring locations, and apt source formats
   - package names, version pins, install channels, and architecture handling
   - prerequisite packages and cleanup steps
   - WSL-specific requirements or warnings
   - deprecated commands such as `apt-key`
7. Check repository conventions:
   - If the review proposes **rewording user-visible scripted output** (especially from `src/` or `./wsl-builder.sh`), `test/docker/*.bats` frequently matches `$output` via `[[ … =~ ]]`, `grep`, etc. Flag that `test/`, `builds/test-fixture/`, and Bats assertions should be updated **in the same implementation pass** (`./test/run-tests.sh` after substantive helper changes).
   - **Start on boot:** From the script and vendor docs, infer whether the install enables a **systemd** (or other) **start-on-boot** service. If it does and `install_<component>.sh` has no optional `promptYesNo` step to `systemctl disable --now` that unit (stop now + no boot), **ask the user** at the end of the review (after the summary) whether they want that UX added—point to `.cursor/rules/bash-component-patterns.mdc` (*Optional: disable start on boot*) and `builds/ai/install_ollama.sh` / `builds/devops/install_docker.sh`. Treat as a product/UX choice, not a severity finding unless the service is inappropriate for WSL.
   - **Component messaging:** first user status line is `printInfo "Installing …"`; the **last** user-facing status is `printInfo "<Name> installed"` (same noun, past tense, no "successfully", ellipsis, or trailing period)
   - avoid `echo` for step/status lines (reserve `echo` for heredocs or file content)
   - optional version lines should go through `printInfo` (e.g. `printInfo "<Name> version: …"`), not raw `--version` as the script’s final output
   - use `printInfo`, `printWarning`, and `printError` for output
   - use `getFile` for downloaded installers or binaries when caching is useful
   - call `cleanupGetFiles` after installer downloads when appropriate
   - rely on **the builder** (`./wsl-builder.sh`) error handling instead of broad error swallowing
   - `recordComponentSuccess` stays in `src/install-dispatch.sh`, not in `install_<component>.sh`

## Security Check Execution

Use the right tool per source. The web fetch tool is GET-only and renders responses as markdown, which mangles large JSON; prefer shell `curl` plus `jq` for the JSON feeds.

- Vendor advisory or security page (HTML): use the web fetch tool.
- CISA KEV (large JSON GET): shell `curl` plus `jq`.
- Ubuntu Security Notices (JSON GET): shell `curl` plus `jq`.
- OSV.dev (JSON POST): shell `curl` plus `jq`. The web fetch tool cannot POST.

Reference snippets. Substitute `<package>`, `<vendor>`, and the OSV `ecosystem` to match the component being reviewed (e.g. `Ubuntu:24.04`, `Debian:12`, `npm`, `PyPI`, `Go`).

```bash
TODAY=$(date -u +%F)

curl -fsSL https://www.cisa.gov/sites/default/files/feeds/known_exploited_vulnerabilities.json \
  | jq --arg p "<vendor-or-product>" '
      .vulnerabilities[]
      | select((.vendorProject + " " + .product) | ascii_downcase | contains($p | ascii_downcase))
      | {cveID, dateAdded, shortDescription, knownRansomwareCampaignUse}
    '

curl -fsSL "https://ubuntu.com/security/notices.json?package=<package>&limit=20" \
  | jq '.notices[] | {id, published, cves, summary}'

curl -fsSL -X POST https://api.osv.dev/v1/query \
  -H 'Content-Type: application/json' \
  -d '{"package":{"name":"<package>","ecosystem":"Ubuntu:24.04"}}' \
  | jq '.vulns[] | {id, summary, severity, modified}'
```

Keep responses small: filter with `jq` rather than dumping raw payloads, and stop once you have enough signal to assign severity.

## Security Check Etiquette

These rules constrain how the security check is executed. They are not optional.

- **One source per command.** Run each advisory fetch as its own shell invocation. Do not chain advisory queries with `&&`, `;`, or pipelines that mix sources. After each command, evaluate the output before deciding whether to query the next source.
- **Pinned source order.** Query in this order and stop as soon as severity can be assigned:
  1. CISA KEV — small and definitive; any hit is automatically High.
  2. Vendor advisory page — usually states "fixed in version X" clearly.
  3. OSV.dev — one `package` plus `ecosystem` per call.
  4. Ubuntu Security Notices — one `package` per call.
- **Query budget: at most 4 advisory fetches by default.** If more seem necessary, summarize what was found so far and ask the user before continuing.
- **No silent permission escalation.** If a fetch is blocked, retry once with `required_permissions: ['network']`. If still blocked, stop and tell the user which host failed and why broader access would help. Never reach for `['full_network']` without explicit user approval. If the user declines, fall back to vendor HTML via the web fetch tool, or report `Security: Could not verify (network blocked)` in the summary.
- **No narration.** Do not commentate the security check ("retrying the feed", "broader access", "this confirms..."). Run the queries, then write the `Security:` line in the summary. Surface fetch failures only when they change the verdict.

## Severity Calibration

Apply these definitions strictly. Bias toward `Low`; only escalate when the criteria are clearly met.

- **High**: software is very out of date, has substantial current security vulnerabilities, or has another alarming reason to upgrade urgently. CVEs listed in CISA KEV, or unpatched advisories with CVSS >= 9.0 affecting the installed version, count as High.
- **Medium**: meaningful difference worth considering, such as an official deprecation, a version that is no longer supported, or a minor security fix. Recently patched high-severity CVEs, or a version no longer receiving security backports, count as Medium.
- **Low**: everything else, including supported-but-older install formats, doc style drift, optional cleanup or verification steps, and cosmetic convention nits.

Do not promote a finding to medium just because vendor docs prefer a newer equivalent format. If the existing approach is still officially supported and produces a working install, it is `Low`.

## Review Output

Default output must be brief enough for quick human review.

- Maximum 9 lines by default. If the review cannot fit, omit low-impact detail rather than expand the summary.
- Exactly one `Recommendation` sentence and one `Reason` sentence.
- At most 3 `Important differences` bullets, high or medium severity only.
- No command snippets, long explanations, or per-source analysis by default.
- Low severity items are hidden detail: show only a count and offer details on request.
- If there are no high or medium findings, write `Important differences: None at high/medium severity.`
- Always include a `Security` line. Use `None known as of <YYYY-MM-DD>` when the security check found nothing material; otherwise list at most 2 CVEs with severity and a 3-5 word summary each.

Use this template:

```markdown
## Review Summary
Component: `<build-dir>/<component>`
Verdict: Up to date | Update recommended | Needs investigation | Do not update

Recommendation: <one sentence saying what to do next>
Reason: <one supporting reason>

Important differences:
- <High or medium severity difference; or "None at high/medium severity.">

Security: <None known as of YYYY-MM-DD | CVE-YYYY-NNNN (severity, brief summary)>
Low severity: <N item(s), details available on request>
Sources checked: <official docs, advisory feeds, and local files checked, concise>
```

Use `Up to date` when the script remains functional, supported, and convention-compliant, even if low severity improvements exist. Do not recommend churn for cosmetic differences that do not improve correctness, security, maintainability, or compatibility.

## Verification Guidance

When the user asks to implement recommended updates, use the `add-wsl-build-component` skill. After edits, run `bash -n` on touched build files/helpers. For regressions touching shared `src/` (including `src/install-dispatch.sh`) or `test/docker/`, run `./test/run-tests.sh` (see [`test/README.md`](../../../test/README.md) and [`test/docker/Dockerfile`](../../../test/docker/Dockerfile)).
