#!/usr/bin/env bash

set -u


# ============================================================================
# Paths
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_WORKSPACE:-$(cd "${SCRIPT_DIR}/.." && pwd)}"


# ============================================================================
# Colors
# ============================================================================
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET="\033[0m"
  BOLD="\033[1m"

  GREEN="\033[32m"
  YELLOW="\033[33m"
  CYAN="\033[36m"
  GRAY="\033[90m"
else
  RESET=""
  BOLD=""

  GREEN=""
  YELLOW=""
  CYAN=""
  GRAY=""
fi


# ============================================================================
# Visual helpers
# ============================================================================
info()
{
  printf "  ${GRAY}%-22s${RESET} %s\n" "$1" "$2"
}


# ============================================================================
# Banner
# ============================================================================
printf '\n'
printf "${CYAN}${BOLD}"
printf '╔══════════════════════════════════════════════════════════════╗\n'
printf '║                    ESP-IDF Dev Container                     ║\n'
printf '╚══════════════════════════════════════════════════════════════╝\n'
printf "${RESET}\n"


# ============================================================================
# Environment information
# ============================================================================
IDF_VERSION="$(idf.py --version 2>/dev/null || true)"

if [[ -z "${IDF_VERSION}" ]]; then
  IDF_VERSION="Not found"
fi

info "ESP-IDF:" "${IDF_VERSION}"
info "IDF Path:" "${IDF_PATH:-Not defined}"
info "Container IDF:" "${DEVCONTAINER_IDF_VERSION:-Not defined}"
info "ccache:" "${IDF_CCACHE_ENABLE:-Not defined}"

printf '\n'


# ============================================================================
# Project status
# ============================================================================
if [[ -f "${PROJECT_ROOT}/CMakeLists.txt" ]]; then
  printf "${GREEN}✔${RESET} Project initialized.\n\n"

  # --------------------------------------------------------------------------
  # Project name
  # --------------------------------------------------------------------------
  PROJECT_NAME="$(basename "${PROJECT_ROOT}")"

  CMAKE_PROJECT_NAME="$(
    sed -nE \
      's/^[[:space:]]*project[[:space:]]*\([[:space:]]*([^[:space:])]+).*/\1/p' \
      "${PROJECT_ROOT}/CMakeLists.txt" |
      head -n 1
  )"

  if [[ -n "${CMAKE_PROJECT_NAME}" ]]; then
    PROJECT_NAME="${CMAKE_PROJECT_NAME}"
  fi

  info "Project Name:" "${PROJECT_NAME}"

  # --------------------------------------------------------------------------
  # Target
  # --------------------------------------------------------------------------
  TARGET="Not configured"

  for config_file in \
    "${PROJECT_ROOT}/sdkconfig" \
    "${PROJECT_ROOT}/sdkconfig.defaults"; do

    if [[ -f "${config_file}" ]]; then
      DETECTED_TARGET="$(
        grep '^CONFIG_IDF_TARGET=' "${config_file}" 2>/dev/null |
          head -n 1 |
          cut -d'"' -f2 ||
          true
      )"

      if [[ -n "${DETECTED_TARGET}" ]]; then
        TARGET="${DETECTED_TARGET}"
        break
      fi
    fi
  done

  info "Target:" "${TARGET}"

  # --------------------------------------------------------------------------
  # Firmware version
  # --------------------------------------------------------------------------
  FIRMWARE_VERSION="Not defined"

  if [[ -f "${PROJECT_ROOT}/version.txt" ]]; then
    DETECTED_VERSION="$(<"${PROJECT_ROOT}/version.txt")"

    if [[ -n "${DETECTED_VERSION}" ]]; then
      FIRMWARE_VERSION="${DETECTED_VERSION}"
    fi
  fi

  info "Firmware Version:" "${FIRMWARE_VERSION}"

  # --------------------------------------------------------------------------
  # Useful commands
  # --------------------------------------------------------------------------
  printf '\n'
  printf "${CYAN}${BOLD}Useful Commands:${RESET}\n\n"

  printf '  idf.py build\n'
  printf '  idf.py menuconfig\n'
  printf '  idf.py flash\n'
  printf '  idf.py monitor\n'
  printf '  idf.py flash monitor\n'
else
  printf "${YELLOW}⚠${RESET} Project not initialized.\n\n"

  printf 'Create a project with:\n\n'
  printf "  ${BOLD}esp-init <project_name> <target> [version]${RESET}\n\n"

  printf 'For more information:\n\n'
  printf "  ${BOLD}esp-init --help${RESET}\n"
fi

printf '\n'
