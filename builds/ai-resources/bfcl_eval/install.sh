#!/usr/bin/env bash

printInfo "Installing BFCL eval"

_conda_sh="${HOME}/anaconda3/etc/profile.d/conda.sh"
if [[ ! -f "${_conda_sh}" ]]; then
    printError "Anaconda conda not found; run: ./wsl-builder.sh dev-python conda"
    exit 1
fi
# shellcheck source=/dev/null # conda.sh is provided by Anaconda at runtime
source "${_conda_sh}"

_gorilla_dir="${PROJECT_DIR}/gorilla"
_bfcl_pkg_dir="${_gorilla_dir}/berkeley-function-call-leaderboard"

mkdir -p "${PROJECT_DIR}"

if [[ -d "${_gorilla_dir}/.git" ]]; then
    printInfo "Updating gorilla source tree"
    git -C "${_gorilla_dir}" pull --ff-only
else
    printInfo "Cloning gorilla repo"
    git clone https://github.com/ShishirPatil/gorilla.git "${_gorilla_dir}"
fi

if ! conda env list | grep -qE '^\s*bfcl-eval\s'; then
    printInfo "Creating bfcl-eval conda environment"
    conda create --name bfcl-eval python=3.10 -y
fi

printInfo "Activating bfcl-eval conda environment"
conda activate bfcl-eval

printInfo "Installing BFCL eval package (editable)"
cd "${_bfcl_pkg_dir}" || exit
pip install -e .

_bfcl_project_root="${BFCL_PROJECT_ROOT:-${_bfcl_pkg_dir}}"

if [[ -n "${BFCL_PROJECT_ROOT:-}" ]]; then
    printInfo "Configuring BFCL project root from wsl-builds.conf: ${BFCL_PROJECT_ROOT}"
    _bfcl_owner="${SUDO_USER:-$USER}"
    _bfcl_group="$(id -gn "${_bfcl_owner}")"
    sudo install -d -m 0755 "${BFCL_PROJECT_ROOT}"
    sudo chown "${_bfcl_owner}:${_bfcl_group}" "${BFCL_PROJECT_ROOT}"

    _bfcl_profile="/etc/profile.d/wsl-builds-bfcl-project-root.sh"
    printf 'export BFCL_PROJECT_ROOT=%q\n' "${BFCL_PROJECT_ROOT}" | sudo tee "${_bfcl_profile}" >/dev/null
    sudo chmod 0644 "${_bfcl_profile}"

    conda env config vars set BFCL_PROJECT_ROOT="${BFCL_PROJECT_ROOT}" -n bfcl-eval
fi

_env_example="${_bfcl_pkg_dir}/bfcl_eval/.env.example"
_env_file="${_bfcl_project_root}/.env"
if [[ ! -f "${_env_file}" ]] && [[ -f "${_env_example}" ]]; then
    printInfo "Creating .env from example at ${_bfcl_project_root}"
    cp "${_env_example}" "${_env_file}"
fi

if command -v bfcl >/dev/null 2>&1; then
    printInfo "BFCL eval version: $(bfcl --version 2>&1 | head -n1)"
else
    printInfo "BFCL eval version: $(python -c "from importlib.metadata import version; print(version('bfcl_eval'))" 2>&1)"
fi

printInfo "Note: to use BFCL eval:"
printInfo "    conda activate bfcl-eval"
printInfo "    edit ${_bfcl_project_root}/.env (API keys and config)"
printInfo "    bfcl generate --model MODEL_NAME --test-category TEST_CATEGORY"
printInfo "Optional: pip install -e .[oss_eval_vllm] or -e .[oss_eval_sglang] for self-hosted models"

printInfo "BFCL eval installed"
