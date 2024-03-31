#!/usr/bin/env bash
# helper functions for build installers

# inline command
# $1 - new hostname
# adds to or updates /etc/hosts & /etc/wsl.conf
updateHostname() {
    printInfo "Updating hostname to: $1"
    if ! cat /etc/wsl.conf | grep -q 'hostname ='; then
        sudo tee -a /etc/wsl.conf > /dev/null <<EOF
[network]
hostname = $1
generateHosts = false
EOF
    else
        sudo sed -i "/^\[network\]/,/^\[/ {/^hostname\s*=/ s/=.*/= $1/;}" /etc/wsl.conf
    fi
    if ! cat /etc/hosts | grep -q '# wsl instance name'; then
        sudo tee -a /etc/hosts > /dev/null <<EOF
# wsl instance name
127.0.0.1       $1
EOF
    else
        sudo sed -i "/# wsl instance name/{n;s/127.0.0.1\s\+.*/127.0.0.1       $1/;}" /etc/hosts
    fi
    printInfo "This requires a restart for changes to take effect"
}

# inline command
# $1 - filename
# $2 - url
# retrieves filename from local cache or download from url & cache
getFile() {
    printInfo "Getting file: $1"
    cache_file="${CACHE_DIR}/$1"
    if [ -f $cache_file ]; then
        printInfo "Using locally cached version"
        cp $cache_file ./   # use cached version if it exists
    else
        printInfo "Downloading and caching"
        wget $2             # download & cache
        cp $1 $cache_file
    fi
}