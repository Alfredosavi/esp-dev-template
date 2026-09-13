#!/usr/bin/env bash

set -Eeuo pipefail


# ============================================================================
# Paths
# ============================================================================
PROJECT_ROOT="${PROJECT_WORKSPACE:-/app}"

BASH_CONFIG="${PROJECT_ROOT}/.devcontainer/config/bashrc.sh"
USER_BASHRC="${HOME}/.bashrc"


# ============================================================================
# Bash environment
# ============================================================================
if [[ ! -f "${BASH_CONFIG}" ]]; then
  printf 'Error: bash configuration not found: %s\n' "${BASH_CONFIG}" >&2
  exit 1
fi

BEGIN_MARKER="# >>> ESP-IDF Dev Container >>>"
END_MARKER="# <<< ESP-IDF Dev Container <<<"

# Keep the managed block idempotent and replaceable on future template updates.
touch "${USER_BASHRC}"

sed -i \
  "/^${BEGIN_MARKER//\//\\/}$/,/^${END_MARKER//\//\\/}$/d" \
  "${USER_BASHRC}"

{
  printf '\n%s\n' "${BEGIN_MARKER}"
  printf '[ -f "%s" ] && source "%s"\n' "${BASH_CONFIG}" "${BASH_CONFIG}"
  printf '%s\n' "${END_MARKER}"
} >> "${USER_BASHRC}"

# Activate ESP-IDF for this setup process as well.
source "${BASH_CONFIG}"


# ============================================================================
# Git safe directories
# ============================================================================
add_safe_directory()
{
  local directory="$1"

  if ! git config --global --get-all safe.directory 2>/dev/null |
       grep -Fxq -- "${directory}"; then
    git config --global --add safe.directory "${directory}"
  fi
}

if [[ -n "${IDF_PATH:-}" && -d "${IDF_PATH}" ]]; then
  # ESP-IDF repository itself.
  add_safe_directory "${IDF_PATH}"

  # Git repositories/submodules shipped inside this ESP-IDF version.
  while IFS= read -r -d '' git_marker; do
    add_safe_directory "$(dirname "${git_marker}")"
  done < <(
    find "${IDF_PATH}" \
      -name .git \
      \( -type d -o -type f \) \
      -print0
  )
fi


# ============================================================================
# ccache
# ============================================================================
if command -v ccache >/dev/null 2>&1; then
  CCACHE_DIR="${CCACHE_DIR:-${HOME}/.cache/ccache}"

  sudo mkdir -p "${CCACHE_DIR}"
  sudo chown "$(id -u):$(id -g)" "${CCACHE_DIR}"

  if [[ -n "${CCACHE_MAXSIZE:-}" ]]; then
    ccache --max-size "${CCACHE_MAXSIZE}" >/dev/null
  fi
fi


# ============================================================================
# Result
# ============================================================================
printf 'ESP-IDF development environment configured.\n'
