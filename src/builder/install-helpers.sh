#!/usr/bin/env bash
# helper functions for build installers

_helpers_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
# shellcheck source=../common/prompt-yesno.sh
source "${_helpers_dir}/../common/prompt-yesno.sh"
# shellcheck source=systemd-boot.sh
source "${_helpers_dir}/systemd-boot.sh"

# Sets nameref $1 to stale-cache threshold in whole days (default 60; WARN_IF_CACHED_FILE_OLDER_THAN must be a positive integer).
resolveGetFileStaleCacheDays() {
    local -n _getfile_stale_days_out=$1
    local raw
    raw="${WARN_IF_CACHED_FILE_OLDER_THAN-}"
    if [[ -z "${raw}" ]]; then
        _getfile_stale_days_out=60
        return 0
    fi
    if [[ "${raw}" =~ ^[1-9][0-9]*$ ]]; then
        _getfile_stale_days_out="${raw}"
        return 0
    fi
    printWarning "WARN_IF_CACHED_FILE_OLDER_THAN must be a positive integer; using 60"
    _getfile_stale_days_out=60
}

# inline command
# $1 - component name
# Records successful component installation to ~/.wsl-build.info and sets BUILD_UPDATED=true
# This ensures that even if later components fail, earlier successes are recorded
recordComponentSuccess() {
    local component="$1"
    
    # Validate required parameters
    if [[ -z "$component" ]]; then
        printError "recordComponentSuccess: Missing component name"
        return 1
    fi
    
    # Initialize build info file if it doesn't exist
    if [ ! -f "${BUILD_INFO_FILE}" ]; then
        printInfo "Creating ${BUILD_INFO_FILE}"
        base_os_id=$(awk -F= '$1=="ID" { print $2 ;}' /etc/os-release | tr -d '"')
        base_os_version="$(awk -F= '$1=="VERSION" { print $2 ;}' /etc/os-release | tr -d '"')"
        echo "${base_os_id} ${base_os_version}" >> "${BUILD_INFO_FILE}"
    fi
    
    # Record the successful component installation
    echo "${BUILD_NAME} (${component})" >> "${BUILD_INFO_FILE}"
    printInfo "$(tail -1 "${BUILD_INFO_FILE}") installed!"
    
    # Set the BUILD_UPDATED flag (consumed by wsl-builder.sh after sourcing this file)
    # shellcheck disable=SC2034
    BUILD_UPDATED=true
}

# inline command
# $1 - component name
# Prints a standard warning message for components already listed in build.info
warnComponentAlreadyInstalled() {
    local component="$1"
    
    # Validate required parameters
    if [[ -z "$component" ]]; then
        printError "warnComponentAlreadyInstalled: Missing component name"
        return 1
    fi
    
    printWarning "${BUILD_NAME} ${component} is already listed in your ~/.wsl-build.info. Use --force to override"
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
    
    mkdir -p "$download_dir"
    mkdir -p "${CACHE_DIR}"
    
    local cache_file="${CACHE_DIR}/$filename"
    local target_file="$download_dir/$filename"
    local threshold
    resolveGetFileStaleCacheDays threshold
    
    if [ -f "$cache_file" ]; then
        local mtime now age_days use_cache=true
        mtime=$(stat -c %Y "$cache_file")
        now=$(date +%s)
        age_days=$(( (now - mtime) / 86400 ))
        
        if (( age_days > threshold )); then
            printWarning "Cached ${filename} is about ${age_days} days old (stale after ${threshold} days)"
            if ! promptYesNoDefaultYesOnEof "Use cached file anyway?"; then
                use_cache=false
            fi
        fi
        
        if [[ "${use_cache}" == true ]]; then
            printInfo "Using locally cached version"
            if ! cp "$cache_file" "$target_file"; then
                printError "Failed to copy cached file to $target_file"
                return 1
            fi
        else
            printInfo "Downloading fresh copy"
            local tmp="${cache_file}.part.$$"
            if ! wget "$url" -O "$tmp"; then
                printError "Failed to download $filename from $url"
                rm -f "$tmp"
                return 1
            fi
            if ! mv -f "$tmp" "$cache_file"; then
                printError "Failed to replace cache for $filename"
                rm -f "$tmp"
                return 1
            fi
            if ! cp "$cache_file" "$target_file"; then
                printError "Failed to copy refreshed cache to $target_file"
                return 1
            fi
        fi
    else
        printInfo "Downloading and caching"
        if ! wget "$url" -O "$target_file"; then
            printError "Failed to download $filename from $url"
            return 1
        fi
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
    
    # Set the result variable to the file path (nameref writes back to caller)
    # shellcheck disable=SC2034
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

# inline command
# $1 - component name
# $2... - arguments passed to build (to check for --force flag)
# Checks if a component is already installed by looking in ~/.wsl-build.info
# Returns 0 if component is already installed (and --force not used), 1 if should install
# This provides consistent checking logic across all components
isComponentInstalled() {
    local component="$1"
    shift  # Remove component name, leaving build arguments
    
    # Validate required parameters
    if [[ -z "$component" ]]; then
        printError "isComponentInstalled: Missing component name"
        return 1  # Error case - should not install
    fi
    
    # If --force flag is present, always install (return 1 = should install)
    if (isBuildForced "$@"); then
        return 1
    fi
    
    # If build info file doesn't exist, component is not installed
    if [ ! -f "${BUILD_INFO_FILE}" ]; then
        return 1  # Should install
    fi
    
    # Check if this hostname has this component installed
    # Pattern matches: "hostname v*.*.* (component)"
    local pattern="${BUILD_DIR_NAME} v.* (${component})"
    if grep -q "^${pattern}$" "${BUILD_INFO_FILE}"; then
        return 0  # Already installed, don't install
    else
        return 1  # Not installed, should install
    fi
}