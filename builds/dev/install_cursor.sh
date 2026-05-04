#!/usr/bin/env bash

printInfo "Installing Cursor"
sudo apt update
sudo apt install -y \
    tree

ensureShellRcRegion cursor-alias "$(cat <<'EOF'
alias code='cursor'
EOF
)"

printInfo "Launching Cursor (first run may install extensions)"
cursor .

printInfo "Cursor installed"
