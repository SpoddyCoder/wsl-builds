# Harness-only component: exercises ensureShellRcRegion and ensureWslConfIniLine.
# shellcheck shell=bash

printInfo "Installing file-edit-harness"

ensureShellRcRegion test-fixture-file-harness "$(cat <<'EOF'
export WSL_BUILDS_TEST_FIXTURE_HARNESS=1
EOF
)"

ensureWslConfIniLine wsl-builds-test "fixture = true" "fixture = true"

printInfo "file-edit-harness installed"
