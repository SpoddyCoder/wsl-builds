# Harness-only component: exercises ensureShellRcRegion and ensureWslConfIniLine.
# shellcheck shell=bash

printInfo "Installing file-edit-harness"

ensureShellRcRegion fixture-builder-file-harness "$(cat <<'EOF'
export WSL_BUILDS_FIXTURE_BUILDER_HARNESS=1
EOF
)"

ensureWslConfIniLine wsl-builds-fixture-builder "fixture = true" "fixture = true"

printInfo "file-edit-harness installed"
