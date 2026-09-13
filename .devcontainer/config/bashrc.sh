# ============================================================================
# ESP-IDF environment
# ============================================================================
export PROJECT_WORKSPACE="${PROJECT_WORKSPACE:-/app}"

if ! command -v idf.py >/dev/null 2>&1; then
  if [[ -n "${IDF_PATH:-}" && -f "${IDF_PATH}/export.sh" ]]; then
    if ! source "${IDF_PATH}/export.sh" >/dev/null 2>&1; then
      printf 'Warning: failed to initialize ESP-IDF environment.\n' >&2
    fi
  fi
fi


# ============================================================================
# Development commands
# ============================================================================
alias esp-info='bash "${PROJECT_WORKSPACE}/.devcontainer/project-info.sh"'
alias esp-init='bash "${PROJECT_WORKSPACE}/.devcontainer/init-project.sh"'
alias esp-setup='bash "${PROJECT_WORKSPACE}/.devcontainer/setup-dev-env.sh"'
