Maintainer notes for advisory review (human prose only).

- Primary install path is Debian/Ubuntu apt package `shellcheck` (installed version comes from `dpkg`, not a repo-pinned tarball).
- For measurement only, the audit also fetches the latest GitHub release tag for `koalaman/shellcheck` from the public releases API; that tag is not what apt installs.
- Semver compare of the CLI to the GitHub tag is off by default (`compare_cli_to_github_semver: false`) because distro packages usually lag upstream releases.
- Required check ids match `requiredCheckIdsJson` in `shellcheck/audit.sh`: `cli-reported-version`, `deb-installed-version`, `installer-validated-staleness`, `upstream-exact-match`.
- Runner computes concerns (`security`, `freshness`, `skipped`, `incomplete`) via `emitConcernsFromChecks`; audits emit measurement JSON only with an empty optional `custom_issue_policy`.
- A required check may have outcome `skipped` without forcing incomplete; `inconclusive` on a required id does force incomplete.
- `http-json-upstream-version` always runs but is not required; fetch/parse `inconclusive` there alone does not make the story incomplete.
- `upstream-semver-drift` runs only when `compare_cli_to_github_semver` is true; when false the audit emits a skipped row so `concerns.skipped` reflects that.
- Empty `last_known_upstream` makes `upstream-exact-match` skipped (set a deb version in `last_known_upstream` to enable exact-match).
- `installer-validated-staleness` compares `installer_validated` to `installer_staleness_max_days` and skips if `installer_validated` is empty.
- Six v1 audit-check modules compose in `shellcheck/audit.sh` under `src/review/audit-checks/`.
