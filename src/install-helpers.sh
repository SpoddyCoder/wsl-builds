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
# $3 - download directory (optional, defaults to /tmp)
# $4 - result variable name (required)
# sets the result variable to the full path of the downloaded file
getFile() {
    local filename="$1"
    local url="$2" 
    local download_dir="${3:-/tmp}"  # default to /tmp
    local result_var="$4"
    
    # Validate required parameters
    if [[ -z "$filename" || -z "$url" || -z "$result_var" ]]; then
        printError "getFile: Missing required parameters (filename, url, result_var)"
        return 1
    fi
    
    # Create nameref to the result variable
    declare -n result_ref="$result_var"
    
    printInfo "Getting file: $filename"
    
    # Create download directory if it doesn't exist
    mkdir -p "$download_dir"
    
    local cache_file="${CACHE_DIR}/$filename"
    local target_file="$download_dir/$filename"
    
    if [ -f "$cache_file" ]; then
        printInfo "Using locally cached version"
        if ! cp "$cache_file" "$target_file"; then
            printError "Failed to copy cached file to $target_file"
            return 1
        fi
    else
        printInfo "Downloading and caching"
        # Download directly to target location
        if ! wget "$url" -O "$target_file"; then
            printError "Failed to download $filename from $url"
            return 1
        fi
        
        # Cache the file
        if ! cp "$target_file" "$cache_file"; then
            printWarning "Failed to cache file, continuing anyway"
        fi
    fi
    
    # Verify the target file exists
    if [ ! -f "$target_file" ]; then
        printError "Target file $target_file does not exist after processing"
        return 1
    fi
    
    # Always track files for potential cleanup
    echo "$target_file" >> "/tmp/.getfile_cleanup_$$"
    
    # Set the result variable to the file path
    result_ref="$target_file"
    
    return 0
}

# inline command
# cleans up files tracked by getFile with cleanup flag
cleanupGetFiles() {
    local cleanup_file="/tmp/.getfile_cleanup_$$"
    if [ -f "$cleanup_file" ]; then
        printInfo "Cleaning up downloaded files"
        while IFS= read -r file; do
            if [ -f "$file" ]; then
                rm "$file"
                printInfo "Removed: $file"
            fi
        done < "$cleanup_file"
        rm "$cleanup_file"
    fi
}