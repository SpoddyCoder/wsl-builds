#!/usr/bin/env bash

printInfo "Installing QoL bits"

# wsl --import's start as root: https://github.com/microsoft/WSL/issues/4276
# ensure our user started by default
ensureWslConfIniLine user '[user]' "default=${LOGNAME}"

if [ ! -L "${WIN_HOME_SYMLINK}" ] && [ -n "${WIN_HOME_TARGET}" ]; then
    printInfo "Creating win home symlink"
    ln -s "${WIN_HOME_TARGET}" "${WIN_HOME_SYMLINK}"
fi

if ! grep -q '# safety aliases' ~/.bash_aliases 2>/dev/null; then
    printInfo "Adding bash safety aliases"
    {
        echo "# safety aliases"
        echo "alias rm=\"rm -i\""
        echo "alias cp=\"cp -i\""
    } >> ~/.bash_aliases
fi

ensureShellRcRegion qol-change-hostname "$(cat <<'EOF'

# Change WSL hostname - added by wsl-builds system qol
change-hostname() {
    if [ -z "$1" ]; then
        echo "Usage: change-hostname <new-hostname>"
        echo
        echo "Updates /etc/wsl.conf and /etc/hosts with the new hostname."
        echo "Requires a restart for changes to take effect."
        echo
        echo "Example:"
        echo "  change-hostname my-dev-box"
        return 1
    fi

    local new_hostname="$1"
    echo "Updating hostname to: $new_hostname"

    # Update or add hostname to /etc/wsl.conf
    if ! cat /etc/wsl.conf | grep -q 'hostname ='; then
        sudo tee -a /etc/wsl.conf > /dev/null <<WSLEOF
[network]
hostname = $new_hostname
generateHosts = false
WSLEOF
    else
        sudo sed -i "/^\[network\]/,/^\[/ {/^hostname\s*=/ s/=.*/= $new_hostname/;}" /etc/wsl.conf
    fi

    # Update or add hostname to /etc/hosts
    if ! cat /etc/hosts | grep -q '# wsl instance name'; then
        sudo tee -a /etc/hosts > /dev/null <<HOSTSEOF
# wsl instance name
127.0.0.1       $new_hostname
HOSTSEOF
    else
        sudo sed -i "/# wsl instance name/{n;s/127.0.0.1\s\+.*/127.0.0.1       $new_hostname/;}" /etc/hosts
    fi

    echo "Hostname updated successfully!"
    echo "This requires a restart for changes to take effect."
}
EOF
)"

printInfo "change-hostname <new-hostname> to change WSL hostname (restart WSL afterward)"

printInfo "QoL bits installed"
