---
name: review-wsl-build-component
description: Review an existing wsl-builds install component against current official install instructions and repository conventions. Use when the user asks to review, audit, refresh, modernize, or check whether a build component needs updating.
---

# Review WSL Build Component

Use this skill to review an existing component and report whether it should be updated. Do not edit files unless the user explicitly asks for implementation after reviewing the summary.

## Workflow

1. Identify the target build directory and component. Build directories contain `conf.sh` and `install.sh`; components usually live in `install_<component>.sh`.
2. Read the target build's `conf.sh`, `install.sh`, `install_<component>.sh`, and nearby README entries.
3. Confirm the component is declared in `VALID_INSTALL_COMPONENTS` and dispatched from `install.sh` using the local pattern.
4. Inspect current official install instructions for the component. Prefer vendor documentation over blogs, package mirrors, or stale examples.
5. Compare the local script with current guidance, focusing on meaningful differences:
   - package repositories, signing keys, keyring locations, and apt source formats
   - package names, version pins, install channels, and architecture handling
   - prerequisite packages and cleanup steps
   - WSL-specific requirements or warnings
   - deprecated commands such as `apt-key`
6. Check repository conventions:
   - use `printInfo`, `printWarning`, and `printError` for output
   - use `getFile` for downloaded installers or binaries when caching is useful
   - call `cleanupGetFiles` after installer downloads when appropriate
   - rely on `build.sh` error handling instead of broad error swallowing
   - leave `recordComponentSuccess` in the dispatcher, not in `install_<component>.sh`

## Severity Calibration

Apply these definitions strictly. Bias toward `Low`; only escalate when the criteria are clearly met.

- **High**: software is very out of date, has substantial current security vulnerabilities, or has another alarming reason to upgrade urgently.
- **Medium**: meaningful difference worth considering, such as an official deprecation, a version that is no longer supported, or a minor security fix.
- **Low**: everything else, including supported-but-older install formats, doc style drift, optional cleanup or verification steps, and cosmetic convention nits.

Do not promote a finding to medium just because vendor docs prefer a newer equivalent format. If the existing approach is still officially supported and produces a working install, it is `Low`.

## Review Output

Default output must be brief enough for quick human review.

- Maximum 8 lines by default. If the review cannot fit, omit low-impact detail rather than expand the summary.
- Exactly one `Recommendation` sentence and one `Reason` sentence.
- At most 3 `Important differences` bullets, high or medium severity only.
- No command snippets, long explanations, or per-source analysis by default.
- Low severity items are hidden detail: show only a count and offer details on request.
- If there are no high or medium findings, write `Important differences: None at high/medium severity.`

Use this template:

```markdown
## Review Summary
Component: `<build-dir>/<component>`
Verdict: Up to date | Update recommended | Needs investigation | Do not update

Recommendation: <one sentence saying what to do next>
Reason: <one supporting reason>

Important differences:
- <High or medium severity difference; or "None at high/medium severity.">

Low severity: <N item(s), details available on request>
Sources checked: <official docs or local files checked, concise>
```

Use `Up to date` when the script remains functional, supported, and convention-compliant, even if low severity improvements exist. Do not recommend churn for cosmetic differences that do not improve correctness, security, maintainability, or compatibility.

## Verification Guidance

When the user asks to implement recommended updates, use the `add-wsl-build-component` skill. After editing shell files, run targeted syntax checks with `bash -n` for the touched build files and any relevant helpers.
