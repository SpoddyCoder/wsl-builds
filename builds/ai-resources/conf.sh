# TODO: sg2
registerBuildMetadata "ai-resources" "1.1.0" "sg3,lsd,spleeter,rudalle" 0
# Optional AI_RESOURCES_PROJECT_DIR in wsl-builds.conf; consumed by per-component install.sh under this build
# shellcheck disable=SC2034
PROJECT_DIR="${AI_RESOURCES_PROJECT_DIR:-$HOME/ai-resources}"
