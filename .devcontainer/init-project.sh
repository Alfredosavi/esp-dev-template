#!/usr/bin/env bash

set -Eeuo pipefail


# ============================================================================
# Configuration
# ============================================================================
DEFAULT_VERSION="0.1.0"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${PROJECT_WORKSPACE:-$(cd "${SCRIPT_DIR}/.." && pwd)}"

CLANG_FORMAT_FILE="${PROJECT_ROOT}/.clang-format"
SDKCONFIG_DEFAULTS_FILE="${PROJECT_ROOT}/sdkconfig.defaults"

TMP_DIR=""


# ============================================================================
# Colors
# ============================================================================
if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
  RESET="\033[0m"
  BOLD="\033[1m"

  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  CYAN="\033[36m"
  GRAY="\033[90m"
else
  RESET=""
  BOLD=""

  RED=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  GRAY=""
fi


# ============================================================================
# Visual helpers
# ============================================================================
banner()
{
  printf '\n'
  printf "${CYAN}${BOLD}"
  printf '╔══════════════════════════════════════════════════════════════╗\n'
  printf '║                  ESP-IDF Project Setup                       ║\n'
  printf '╚══════════════════════════════════════════════════════════════╝\n'
  printf "${RESET}\n"
}

step()
{
  printf "\n${BLUE}${BOLD}▶ %s${RESET}\n" "$1"
}

success()
{
  printf "${GREEN}✔${RESET} %s\n" "$1"
}

warning()
{
  printf "${YELLOW}⚠${RESET} %s\n" "$1"
}

die()
{
  printf "\n${RED}✘ Error:${RESET} %s\n\n" "$*" >&2
  exit 1
}

info()
{
  printf "  ${GRAY}%-22s${RESET} %s\n" "$1" "$2"
}


# ============================================================================
# Helpers
# ============================================================================
cleanup()
{
  if [[ -n "${TMP_DIR}" && -d "${TMP_DIR}" ]]; then
    rm -rf "${TMP_DIR}"
  fi
}

set_default_target()
{
  local defaults_file="$1"
  local target="$2"

  if [[ -f "${defaults_file}" ]] && grep -q '^CONFIG_IDF_TARGET=' "${defaults_file}"; then
    sed -i \
      "s/^CONFIG_IDF_TARGET=.*/CONFIG_IDF_TARGET=\"${target}\"/" \
      "${defaults_file}"
    return
  fi

  if [[ -s "${defaults_file}" ]]; then
    printf '\n' >> "${defaults_file}"
  fi

  printf 'CONFIG_IDF_TARGET="%s"\n' "${target}" >> "${defaults_file}"
}

trap cleanup EXIT


# ============================================================================
# Usage
# ============================================================================
usage()
{
  printf 'Usage:\n'
  printf '  %s <project_name> <target> [version]\n\n' "$0"

  printf 'Arguments:\n'
  printf '  project_name    ESP-IDF project name\n'
  printf '  target          ESP-IDF target, e.g. esp32, esp32s3, esp32c6\n'
  printf '  version         Firmware version (default: %s)\n\n' "${DEFAULT_VERSION}"

  printf 'Examples:\n'
  printf '  %s my_firmware esp32\n' "$0"
  printf '  %s my_firmware esp32s3 1.2.3\n' "$0"
}


# ============================================================================
# Arguments
# ============================================================================
banner

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 || $# -gt 3 ]]; then
  usage
  exit 1
fi

PROJECT_NAME="$1"
TARGET="$2"
PROJECT_VERSION="${3:-${DEFAULT_VERSION}}"

if [[ ! "${PROJECT_NAME}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
  die "Invalid project name: '${PROJECT_NAME}'. Use only letters, numbers, '_' and '-'."
fi

if [[ -z "${PROJECT_VERSION}" ]]; then
  die "Firmware version must not be empty."
fi

info "Project Name:" "${PROJECT_NAME}"
info "Target:" "${TARGET}"
info "Firmware Version:" "${PROJECT_VERSION}"


# ============================================================================
# ESP-IDF environment
# ============================================================================
step "Checking ESP-IDF environment"

command -v idf.py >/dev/null 2>&1 ||
  die "idf.py was not found in PATH. Run 'esp-setup' or open a new terminal."

[[ -n "${IDF_PATH:-}" ]] ||
  die "IDF_PATH is not defined."

[[ -d "${IDF_PATH}" ]] ||
  die "IDF_PATH points to a non-existent directory: ${IDF_PATH}"

[[ -f "${IDF_PATH}/tools/idf.py" ]] ||
  die "IDF_PATH does not appear to point to a valid ESP-IDF installation."

IDF_VERSION_OUTPUT="$(idf.py --version)"

info "idf.py:" "$(command -v idf.py)"
info "IDF_PATH:" "${IDF_PATH}"
info "ESP-IDF:" "${IDF_VERSION_OUTPUT}"
info "Container IDF:" "${DEVCONTAINER_IDF_VERSION:-Not defined}"

success "ESP-IDF environment found."


# ============================================================================
# clang-format
# ============================================================================
step "Checking clang-format"

command -v clang-format >/dev/null 2>&1 ||
  die "clang-format was not found."

CLANG_FORMAT_ENABLED=0

if [[ -f "${CLANG_FORMAT_FILE}" ]]; then
  CLANG_FORMAT_VERSION="$(clang-format --version)"

  info "Binary:" "$(command -v clang-format)"
  info "Version:" "${CLANG_FORMAT_VERSION}"

  (
    cd "${PROJECT_ROOT}"
    clang-format -style=file -dump-config >/dev/null
  ) || die "The .clang-format file contains an invalid configuration."

  CLANG_FORMAT_ENABLED=1
  success ".clang-format configuration is valid."
else
  warning ".clang-format was not found."
  warning "Initial source formatting will be skipped."
fi


# ============================================================================
# Workspace
# ============================================================================
step "Checking workspace"

[[ -w "${PROJECT_ROOT}" ]] ||
  die "No write permission for ${PROJECT_ROOT}"

if [[ "$(id -u)" -eq 0 ]]; then
  warning "The script is running as root."
  warning "Files created in the workspace may be owned by root on the host."
fi

[[ ! -e "${PROJECT_ROOT}/CMakeLists.txt" ]] ||
  die "CMakeLists.txt already exists. The project appears to be initialized."

[[ ! -e "${PROJECT_ROOT}/main" ]] ||
  die "main/ already exists. The project appears to be initialized."

[[ ! -e "${PROJECT_ROOT}/version.txt" ]] ||
  die "version.txt already exists. The project appears to be initialized."

success "Workspace is ready."


# ============================================================================
# Target
# ============================================================================
step "Validating target '${TARGET}'"

if ! idf.py --list-targets |
  sed 's/^[[:space:]]*//;s/[[:space:]]*$//' |
  grep -Fxq "${TARGET}"; then

  printf "\n${YELLOW}Available targets:${RESET}\n\n"
  idf.py --list-targets
  printf '\n'

  die "Target '${TARGET}' is not supported by this ESP-IDF version."
fi

success "Target '${TARGET}' is supported."


# ============================================================================
# Create project
# ============================================================================
step "Creating ESP-IDF project"

TMP_DIR="$(mktemp -d -t esp-idf-project.XXXXXX)"

info "Temporary Directory:" "${TMP_DIR}"

idf.py create-project \
  --path "${TMP_DIR}" \
  "${PROJECT_NAME}"

# Preserve files already provided by the template if a future ESP-IDF version
# starts generating files with the same names.
cp -a --no-clobber "${TMP_DIR}/." "${PROJECT_ROOT}/"

success "Project '${PROJECT_NAME}' created."


# ============================================================================
# Firmware version
# ============================================================================
step "Setting firmware version"

printf '%s\n' "${PROJECT_VERSION}" > "${PROJECT_ROOT}/version.txt"

info "version.txt:" "${PROJECT_VERSION}"

success "Firmware version configured."


# ============================================================================
# Persistent target default
# ============================================================================
step "Persisting target '${TARGET}'"

set_default_target "${SDKCONFIG_DEFAULTS_FILE}" "${TARGET}"

info "sdkconfig.defaults:" "CONFIG_IDF_TARGET=\"${TARGET}\""

success "Default target configured."


# ============================================================================
# Format initial source
# ============================================================================
if [[ "${CLANG_FORMAT_ENABLED}" -eq 1 ]]; then
  step "Formatting initial source code"

  if [[ -d "${PROJECT_ROOT}/main" ]]; then
    find "${PROJECT_ROOT}/main" \
      -type f \
      \( \
        -name '*.c'   -o \
        -name '*.h'   -o \
        -name '*.cpp' -o \
        -name '*.hpp' \
      \) \
      -exec clang-format -i {} +
  fi

  success "Source code formatted."
fi


# ============================================================================
# Target configuration
# ============================================================================
step "Configuring target '${TARGET}'"

cd "${PROJECT_ROOT}"

# The script argument is the authoritative target selection.
unset IDF_TARGET

idf.py set-target "${TARGET}"

success "Target '${TARGET}' configured."


# ============================================================================
# Build
# ============================================================================
step "Building project"

idf.py build

success "Build completed."


# ============================================================================
# Result
# ============================================================================
printf '\n'
printf "${GREEN}${BOLD}"
printf '╔══════════════════════════════════════════════════════════════╗\n'
printf '║                    Project Setup Complete                    ║\n'
printf '╚══════════════════════════════════════════════════════════════╝\n'
printf "${RESET}\n"

success "Project initialized successfully."

info "Project Name:" "${PROJECT_NAME}"
info "Target:" "${TARGET}"
info "Firmware Version:" "${PROJECT_VERSION}"
info "ESP-IDF:" "${IDF_VERSION_OUTPUT}"

printf '\n'
printf "${CYAN}${BOLD}Useful Commands:${RESET}\n\n"
printf '  idf.py build\n'
printf '  idf.py menuconfig\n'
printf '  idf.py flash\n'
printf '  idf.py monitor\n'
printf '  idf.py flash monitor\n'
printf '\n'
