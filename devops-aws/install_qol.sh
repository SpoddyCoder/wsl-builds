#!/usr/bin/env bash

printInfo "Installing AWS QoL bits"

ensureShellRcRegion aws-profile-qol "$(cat <<'EOF'

# AWS Profile switcher - added by wsl-builds devops-aws qol
aws-profile() {
    if [ -z "$1" ]; then
        echo "Current AWS_PROFILE: ${AWS_PROFILE:-<not set>}"
        echo "Usage: aws-profile <profile-name>"
        return 1
    fi
    export AWS_PROFILE=$1
    echo "AWS_PROFILE set to: $AWS_PROFILE"
}

# Bash completion for aws-profile function
_aws_profile_complete() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local profiles=""

    # Get profiles from ~/.aws/config
    if [ -f ~/.aws/config ]; then
        profiles+=$(grep '^\[profile ' ~/.aws/config | sed 's/^\[profile \([^]]*\)\].*/\1/' | tr '\n' ' ')
    fi

    # Get profiles from ~/.aws/credentials
    if [ -f ~/.aws/credentials ]; then
        profiles+=$(grep '^\[' ~/.aws/credentials | sed 's/^\[\([^]]*\)\].*/\1/' | tr '\n' ' ')
    fi

    # Remove duplicates and generate completions
    profiles=$(echo "$profiles" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    COMPREPLY=($(compgen -W "$profiles" -- "$cur"))
}

# Register the completion function
complete -F _aws_profile_complete aws-profile
EOF
)"

printInfo "aws-profile <profile-name> to switch AWS profiles (tab completion when ~/.aws is set up)"

printInfo "AWS QoL bits installed"
