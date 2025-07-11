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

if [ ! -L ${WIN_HOME_SYMLINK} ] && [ ! -z ${WIN_HOME} ]; then
    printInfo "Creating win home symlink"
    ln -s ${WIN_HOME} ${WIN_HOME_SYMLINK}
fi

if [ ! -L ${CODE_HOME_SYMLINK} ] && [ ! -z ${CODE_HOME} ]; then
    printInfo "Creating code home symlink"
    ln -s ${CODE_HOME} ${CODE_HOME_SYMLINK}
fi

if ! (cat ~/.bash_aliases | grep -q '# safety aliases') > /dev/null 2>&1; then
    printInfo "Adding bash safety aliases"
    echo "# safety aliases" >> ~/.bash_aliases
    echo "alias rm=\"rm -i\"" >> ~/.bash_aliases
    echo "alias cp=\"cp -i\"" >> ~/.bash_aliases
fi

printInfo "QoL bits installation complete" 