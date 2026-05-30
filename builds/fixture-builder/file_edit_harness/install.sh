# Harness-only component: exercises ensureShellRcRegion, ensureWslConfIniLine, and ensureWslConfSectionLine.
# shellcheck shell=bash

printInfo "Installing file-edit-harness"

ensureShellRcRegion fixture-builder-file-harness "$(cat <<'EOF'
export WSL_BUILDS_FIXTURE_BUILDER_HARNESS=1
EOF
)"

ensureWslConfIniLine wsl-builds-fixture-builder "fixture = true" "fixture = true"
ensureWslConfSectionLine wsl-builds-fixture-automount "enabled = false" "enabled = false"
ensureWslConfSectionLine wsl-builds-fixture-interop "enabled = false" "enabled = false"

printInfo "file-edit-harness installed"
