---
name: install-script-consistency
overview: Standardise apt usage, add lightweight version checks, fix two latent bugs (packer keyring, cuda apt-key under set -e), tidy a few small drifts, and update the docs that govern these conventions.
todos:
  - id: rules-and-docs
    content: Update CONTRIBUTING.md and .cursor/rules/bash-component-patterns.mdc with the four apt rules and the no-ellipsis extension.
    status: pending
  - id: system
    content: "system/: add apt update where needed, add -y to install_x11.sh, replace sudo cat | grep with grep in install_systemd.sh and install_fstab.sh, tidy trailing whitespace."
    status: pending
  - id: dev
    content: "dev/ and dev-bash/: add apt update to dev/install_essentials.sh and dev/install_cursor.sh; add version lines in dev-bash/install_shellcheck.sh and dev-bash/install_bats.sh."
    status: pending
  - id: dev-python
    content: "dev-python/install_python3.sh: add apt update and python3/pip3 version lines."
    status: pending
  - id: dev-js
    content: "dev-js/: fix install_nvm.sh (apt update + -y + apt-get->apt); add version lines in install_angular.sh, install_vue.sh, install_express.sh; drop brittle fallback in install_react.sh."
    status: pending
  - id: db
    content: "db/: add apt update before each apt install across the four scripts."
    status: pending
  - id: devops
    content: "devops/: switch apt-get->apt across docker/terraform/kubectl; add apt update before kubectl curl install; rewrite install_packer.sh to mirror install_terraform.sh's keyring approach with -y; drop ellipses on printInfo lines."
    status: pending
  - id: devops-aws
    content: "devops-aws/install_awscli.sh: add apt update before curl/unzip install, switch apt-get->apt, drop ellipses on printInfo lines."
    status: pending
  - id: ai
    content: "ai/install_cuda124.sh: switch apt-get->apt; append || true to apt-key del so it can't abort under set -e."
    status: pending
  - id: ai-resources
    content: "ai-resources/: add -y to install_lsd.sh apt install; drop ellipses on printInfo lines across the four scripts."
    status: pending
  - id: lint
    content: Run ./test/lint.sh and fix any ShellCheck/bash -n regressions introduced by the edits.
    status: pending
isProject: false
---

# Apply Install Script Consistency Recommendations

## House rules to enshrine

These become the canonical pattern in [CONTRIBUTING.md](CONTRIBUTING.md) and [.cursor/rules/bash-component-patterns.mdc](.cursor/rules/bash-component-patterns.mdc):

- **`apt update` first.** Always run `sudo apt update` before any `sudo apt install` that pulls from a repo. Skip it for local `.deb` installs (the apt index isn't queried).
- **`-y` always.** Every `sudo apt install` passes `-y`.
- **`apt`, not `apt-get`.** Pick the majority style; convert the few `apt-get` users.
- **No ellipses in `printInfo` lines.** Extends the existing closing-line rule to in-progress lines for one consistent rule everywhere.
- **Verification is optional but applied uniformly.** If the component installs a binary with a natural version command, end with one `printInfo "<Name> version: $(cmd …)"` line before the closing `printInfo "<Name> installed"`. No fallbacks like `2>/dev/null || echo …`.
- **No per-script error handling.** `set -e` in [build.sh](build.sh) remains the contract; `cd … || exit` is the only allowed guard.

The "house pattern" snippet for an apt-only component:

```bash
#!/usr/bin/env bash

printInfo "Installing <Name>"
sudo apt update
sudo apt install -y <packages>

printInfo "<Name> version: $(<cmd> --version | head -n1)"
printInfo "<Name> installed"
```

Repo-adding flow already mirrored cleanly by [devops/install_terraform.sh](devops/install_terraform.sh); `getFile` flow already mirrored cleanly by [dev-js/install_node.sh](dev-js/install_node.sh).

## Per-script changes

Grouped by the rule that applies. Each bullet calls out the file and the exact tweak.

### Add `apt update` before `apt install` (no other change)

- [system/install_essentials.sh](system/install_essentials.sh)
- [system/install_smb.sh](system/install_smb.sh)
- [system/install_nfs.sh](system/install_nfs.sh)
- [system/install_systemd.sh](system/install_systemd.sh)
- [dev/install_essentials.sh](dev/install_essentials.sh)
- [dev/install_cursor.sh](dev/install_cursor.sh)
- [db/install_postgres_server.sh](db/install_postgres_server.sh)
- [db/install_postgres_client.sh](db/install_postgres_client.sh)
- [db/install_mysql_server.sh](db/install_mysql_server.sh)
- [db/install_mysql_client.sh](db/install_mysql_client.sh)
- [devops/install_kubectl.sh](devops/install_kubectl.sh) (before the `apt install -y curl` step)
- [devops-aws/install_awscli.sh](devops-aws/install_awscli.sh) (before the `apt install -y curl unzip` step)

### Add `apt update` *and* `-y`

- [system/install_x11.sh](system/install_x11.sh) — currently `sudo apt install x11-apps`
- [dev-js/install_nvm.sh](dev-js/install_nvm.sh) — currently `sudo apt-get install libatomic1`; also switch to `apt`
- [ai-resources/install_lsd.sh](ai-resources/install_lsd.sh) — already has `apt update`; only missing `-y` on `sudo apt install libx264-dev ffmpeg`

### `apt-get` → `apt` (devops sweep)

- [devops/install_docker.sh](devops/install_docker.sh)
- [devops/install_terraform.sh](devops/install_terraform.sh)
- [devops/install_kubectl.sh](devops/install_kubectl.sh)
- [devops-aws/install_awscli.sh](devops-aws/install_awscli.sh)
- [ai/install_cuda124.sh](ai/install_cuda124.sh)

### Add a version-check line before the closing line

- [dev-bash/install_shellcheck.sh](dev-bash/install_shellcheck.sh) — `printInfo "shellcheck version: $(shellcheck --version | sed -n 's/^version: //p')"`
- [dev-bash/install_bats.sh](dev-bash/install_bats.sh) — `printInfo "bats version: $(bats --version)"`
- [dev-python/install_python3.sh](dev-python/install_python3.sh) — `python3 --version` and `pip3 --version` lines
- [dev-js/install_angular.sh](dev-js/install_angular.sh) — `printInfo "Angular CLI: $(which ng)"` (matches the React DevTools `which` style; `ng version` is multi-line)
- [dev-js/install_vue.sh](dev-js/install_vue.sh) — `printInfo "create-vue version: $(create-vue --version)"`
- [dev-js/install_express.sh](dev-js/install_express.sh) — `printInfo "express version: $(express --version)"`

### Drop brittle fallback in version line

- [dev-js/install_react.sh](dev-js/install_react.sh) — remove the `create-vite --version 2>/dev/null || echo …` line; keep the existing `which react-devtools` line.

### Replace `sudo cat … | grep -q` with plain `grep -q … /etc/wsl.conf`

- [system/install_systemd.sh](system/install_systemd.sh) (two occurrences)
- [system/install_fstab.sh](system/install_fstab.sh) (two occurrences)

### Bug fixes (not just consistency)

- [devops/install_packer.sh](devops/install_packer.sh) — rewrite to mirror [devops/install_terraform.sh](devops/install_terraform.sh): use `gpg --dearmor` to write `/usr/share/keyrings/hashicorp-archive-keyring.gpg` (the file the existing `signed-by=…` line references), drop the deprecated `apt-key add -`, add `-y`, switch to `apt`. Today's script writes the wrong keyring source and is missing `-y`.
- [ai/install_cuda124.sh](ai/install_cuda124.sh) — append `|| true` to `sudo apt-key del 7fa2af80` so its deprecation warning / non-zero exit can't abort the build under `set -e`. Migration to a keyring-based approach is intentionally out of scope.

### Cosmetic: no ellipses in `printInfo` lines

Sweep `printInfo "X..."` → `printInfo "X"` in:

- [devops/install_docker.sh](devops/install_docker.sh)
- [devops/install_terraform.sh](devops/install_terraform.sh)
- [devops/install_kubectl.sh](devops/install_kubectl.sh)
- [devops/install_k9s.sh](devops/install_k9s.sh)
- [devops-aws/install_awscli.sh](devops-aws/install_awscli.sh)
- [ai-resources/install_spleeter.sh](ai-resources/install_spleeter.sh)
- [ai-resources/install_sg3.sh](ai-resources/install_sg3.sh)
- [ai-resources/install_rudalle.sh](ai-resources/install_rudalle.sh)
- [ai-resources/install_lsd.sh](ai-resources/install_lsd.sh)

(I'll only touch ellipses on `printInfo` lines; `echo` strings inside heredocs/usage messages are left alone.)

### Cosmetic: trailing whitespace on closing `printInfo` lines

Strip the trailing space introduced by old templates. Affected files I'll fix while I'm in them:

- [system/install_update.sh](system/install_update.sh), [system/install_essentials.sh](system/install_essentials.sh), [system/install_x11.sh](system/install_x11.sh), [system/install_wslu.sh](system/install_wslu.sh), [system/install_smb.sh](system/install_smb.sh), [system/install_nfs.sh](system/install_nfs.sh), [system/install_qol.sh](system/install_qol.sh)
- [dev/install_essentials.sh](dev/install_essentials.sh), [dev/install_qol.sh](dev/install_qol.sh), [dev/install_vscode.sh](dev/install_vscode.sh), [dev/install_cursor.sh](dev/install_cursor.sh)
- [dev-js/install_yarn.sh](dev-js/install_yarn.sh), [dev-js/install_angular.sh](dev-js/install_angular.sh), [dev-js/install_vue.sh](dev-js/install_vue.sh), [dev-js/install_express.sh](dev-js/install_express.sh), [dev-js/install_nvm.sh](dev-js/install_nvm.sh)
- [dev-ssg/install_hugo.sh](dev-ssg/install_hugo.sh), [dev-ssg/install_jekyll.sh](dev-ssg/install_jekyll.sh)
- [dev-python/install_python3.sh](dev-python/install_python3.sh)

### Files left untouched

- [system/install_update.sh](system/install_update.sh) — *is* the apt update component; no behaviour change needed beyond trailing whitespace.
- [system/install_qol.sh](system/install_qol.sh), [dev/install_qol.sh](dev/install_qol.sh), [dev/install_vscode.sh](dev/install_vscode.sh), [devops-aws/install_qol.sh](devops-aws/install_qol.sh), [devops/install_docker_desktop.sh](devops/install_docker_desktop.sh), [system/install_fstab.sh](system/install_fstab.sh) — no apt install or no binary; only the trailing-whitespace / `sudo cat | grep` tidies above.
- [dev-python/install_conda.sh](dev-python/install_conda.sh), [ai-resources/install_spleeter.sh](ai-resources/install_spleeter.sh), [ai-resources/install_sg3.sh](ai-resources/install_sg3.sh), [ai-resources/install_rudalle.sh](ai-resources/install_rudalle.sh) — installer flows where a `--version` line wouldn't be reliable; only the ellipsis sweep above.
- [test-fixture/install_*.sh](test-fixture/) — test-only no-op fixtures; out of scope.
- All `dev-js` scripts that already follow the pattern: [install_node.sh](dev-js/install_node.sh) (golden example), [install_nextjs.sh](dev-js/install_nextjs.sh), [install_yarn.sh](dev-js/install_yarn.sh), [install_essentials.sh](dev-js/install_essentials.sh).

## Documentation updates

- [CONTRIBUTING.md](CONTRIBUTING.md) — add an "apt conventions" bullet list under **Components** (the four rules above) and reference the house-pattern snippet. Keep the existing **Component messaging** section; just append "no ellipsis" to in-progress lines too.
- [.cursor/rules/bash-component-patterns.mdc](.cursor/rules/bash-component-patterns.mdc) — mirror the same compressed bullets so the agent rule stays accurate.

The README's user-facing build list doesn't change.

## Verification

- Run `./test/lint.sh` (ShellCheck + `bash -n` over all `*/install*.sh`, configured at [test/lint.sh](test/lint.sh)).
- Spot-check that `bats version: $(bats --version)`-style commands print sensibly on Ubuntu 22.04 (no install run; just inspecting the substitutions).
- Skip `./test/run-tests.sh` (Docker/Bats) — none of these changes affect dispatch, metadata, or the `BUILD_UPDATED`/`recordComponentSuccess` contract that the harness covers.

## Out of scope (flagged in the earlier review, not changed here)

- Migrating [ai/install_cuda124.sh](ai/install_cuda124.sh) off `apt-key` to a keyring-based repo (only `|| true` is added for safety).
- The `code .` / `cursor .` "first run" launch in [dev/install_vscode.sh](dev/install_vscode.sh) and [dev/install_cursor.sh](dev/install_cursor.sh).
- `apt-get` vs `apt` outside the install scripts (e.g. helper text in [test/lint.sh](test/lint.sh)).