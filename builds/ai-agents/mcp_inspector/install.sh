#!/usr/bin/env bash

printInfo "Installing MCP Inspector"

if ! command -v npm >/dev/null 2>&1; then
    printError "npm not found; run: ./wsl-builder.sh dev-js node"
    exit 1
fi

printInfo "Installing MCP Inspector globally via npm"
sudo npm install -g @modelcontextprotocol/inspector

_inspector_ver="$(npm list -g @modelcontextprotocol/inspector --depth=0 2>/dev/null | sed -n 's/.*@modelcontextprotocol\/inspector@//p')"
if [[ -n "${_inspector_ver}" ]]; then
    printInfo "MCP Inspector version: ${_inspector_ver}"
fi
printInfo "    npx @modelcontextprotocol/inspector"
printInfo "MCP Inspector installed"
