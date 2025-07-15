#!/usr/bin/env bash

printInfo "Installing QoL bits"

# wsl --import's start as root: https://github.com/microsoft/WSL/issues/4276
# ensure our user started by default
if ! cat /etc/wsl.conf | grep -q "\[user\]"; then
    printInfo "Setting WSL default username: $LOGNAME"
    sudo tee -a /etc/wsl.conf > /dev/null <<EOF
[user]
default=$LOGNAME
EOF
fi

if [ ! -L ${WIN_HOME_SYMLINK} ] && [ ! -z ${WIN_HOME_TARGET} ]; then
    printInfo "Creating win home symlink"
    ln -s ${WIN_HOME_TARGET} ${WIN_HOME_SYMLINK}
fi

if ! (cat ~/.bash_aliases | grep -q '# safety aliases') > /dev/null 2>&1; then
    printInfo "Adding bash safety aliases"
    echo "# safety aliases" >> ~/.bash_aliases
    echo "alias rm=\"rm -i\"" >> ~/.bash_aliases
    echo "alias cp=\"cp -i\"" >> ~/.bash_aliases
fi

# Add change-hostname function to .bashrc if it doesn't exist
if ! grep -q "change-hostname()" ~/.bashrc; then
    printInfo "Adding change-hostname to .bashrc"
    
    cat >> ~/.bashrc << 'EOF'

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
    
    printInfo "change-hostname added to .bashrc"
    printInfo "    change-hostname <new-hostname>    to change WSL hostname"
    
else
    printInfo "change-hostname function already exists in .bashrc"
fi

printInfo "QoL bits installation complete" 