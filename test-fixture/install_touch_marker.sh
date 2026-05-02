# Harness-only component (automated testing): writes a marker file under HOME.
# shellcheck shell=bash

printInfo "Installing touch-marker"

printInfo "Creating marker file at ${HOME}/.wsl-builds-test-fixture-touch-marker"

if ! touch "${HOME}/.wsl-builds-test-fixture-touch-marker"; then
	printError "Failed to create marker file"
	exit 1
fi

printInfo "touch-marker installed"
