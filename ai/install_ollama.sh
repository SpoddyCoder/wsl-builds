#!/usr/bin/env bash

printInfo "Installing Ollama"

ollama_install_url="https://ollama.com/install.sh"
getFile "ollama_install.sh" "${ollama_install_url}" "" ollama_install_script

printInfo "Running Ollama official install script"
# shellcheck disable=SC2154 # ollama_install_script is set by getFile via nameref
sh "$ollama_install_script"

cleanupGetFiles

if command -v systemctl >/dev/null 2>&1 && [ -f /etc/systemd/system/ollama.service ]; then
    if promptYesNo "Disable the Ollama systemd service from starting on boot"; then
        sudo systemctl disable ollama
        printInfo "Ollama will not start automatically on boot"
    fi
fi

if [ -n "${OLLAMA_MODELS:-}" ]; then
    printInfo "Configuring Ollama models directory from wsl-builds.conf: ${OLLAMA_MODELS}"
    sudo install -d -m 0755 "$OLLAMA_MODELS"
    if getent passwd ollama >/dev/null 2>&1; then
        sudo chown ollama:ollama "$OLLAMA_MODELS"
    else
        _ollama_owner="${SUDO_USER:-$USER}"
        sudo chown "${_ollama_owner}:$(id -gn "${_ollama_owner}")" "$OLLAMA_MODELS"
    fi

    ollama_systemd_env="/etc/ollama/wsl-builds.env"
    sudo install -d -m 0755 /etc/ollama
    printf 'OLLAMA_MODELS=%s\n' "$OLLAMA_MODELS" | sudo tee "$ollama_systemd_env" >/dev/null
    sudo chmod 0600 "$ollama_systemd_env"

    ollama_systemd_dropin="/etc/systemd/system/ollama.service.d/wsl-builds-models.conf"
    if [ -f /etc/systemd/system/ollama.service ]; then
        sudo install -d -m 0755 "$(dirname "$ollama_systemd_dropin")"
        printf '%s\n' '[Service]' "EnvironmentFile=${ollama_systemd_env}" | sudo tee "$ollama_systemd_dropin" >/dev/null
        if command -v systemctl >/dev/null 2>&1; then
            sudo systemctl daemon-reload
            if systemctl is-enabled ollama >/dev/null 2>&1 || systemctl is-active ollama >/dev/null 2>&1; then
                printInfo "Restarting ollama systemd unit to apply OLLAMA_MODELS"
                sudo systemctl restart ollama
            fi
        fi
    fi

    profile_snippet="/etc/profile.d/wsl-builds-ollama-models.sh"
    printf 'export OLLAMA_MODELS=%q\n' "$OLLAMA_MODELS" | sudo tee "$profile_snippet" >/dev/null
    sudo chmod 0644 "$profile_snippet"
fi

printInfo "Ollama version: $(ollama --version 2>&1 | head -n1)"

printInfo "Ollama installed"
