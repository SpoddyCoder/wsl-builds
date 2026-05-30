#!/usr/bin/env bash

printInfo "Installing QoL bits"

# wsl --import's start as root: https://github.com/microsoft/WSL/issues/4276
# ensure our user started by default
ensureWslConfIniLine user '[user]' "default=${LOGNAME}"

if ! grep -q '# safety aliases' ~/.bash_aliases 2>/dev/null; then
	printInfo "Adding bash safety aliases"
	{
		echo "# safety aliases"
		echo "alias rm=\"rm -i\""
		echo "alias cp=\"cp -i\""
	} >> ~/.bash_aliases
fi

ensureShellRcRegion wsl-distro-manager-home "$(cat <<'EOF'
# WSL2 Distro Manager starts in its install dir; return to $HOME for interactive shells
case "${PWD-}" in
"/mnt/c/Program Files/WSL2 Distro Manager"*)
	cd ~ || true
	;;
esac
EOF
)"

sudo install -o root -g root -m 0755 "${BUILD_DIR}/change-hostname" /usr/local/bin/change-hostname

printInfo "Installed change-hostname to /usr/local/bin (restart WSL after changing hostname)"

printInfo "QoL bits installed"
