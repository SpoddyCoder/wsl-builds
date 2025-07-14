#!/usr/bin/env bash

printInfo "Installing quality of life bits..."

# Add aws-profile function to .bashrc if it doesn't exist
if ! grep -q "aws-profile()" ~/.bashrc; then
    printInfo "Adding aws-profile to .bashrc"
    
    cat >> ~/.bashrc << 'EOF'

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

    printInfo "aws-profile added to .bashrc"
    printInfo "    aws-profile <profile-name>    to switch AWS profiles"
    printInfo "    aws-profile' (no args)        to see current profile"
    printInfo "Tab completion will work for AWS profile names"
else
    printInfo "aws-profile function already exists in .bashrc"
fi 