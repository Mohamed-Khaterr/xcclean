#!/usr/bin/env bash
# install.sh — Installer for xcclean
# Usage: bash install.sh [--uninstall] [--dir /custom/path]

set -euo pipefail

# ── Config ───────────────────────────────────────────────────────────────────

TOOL_NAME="xcclean"
REPO_URL="https://raw.githubusercontent.com/Mohamed-Khaterr/xcclean/main/xcclean.sh"
DEFAULT_INSTALL_DIR="/usr/local/bin"
INSTALL_DIR="${DEFAULT_INSTALL_DIR}"

# ── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# ── Helpers ──────────────────────────────────────────────────────────────────

info()    { printf "  ${CYAN}i${RESET}  %s\n" "$*"; }
success() { printf "  ${GREEN}✓${RESET}  %s\n" "$*"; }
warn()    { printf "  ${YELLOW}!${RESET}  %s\n" "$*"; }
error()   { printf "  ${RED}x${RESET}  %s\n" "$*" >&2; }
die()     { error "$*"; exit 1; }

print_banner() {
  printf "${CYAN}"
  printf ' ██╗  ██╗ ██████╗ ██████╗██╗     ███████╗ █████╗ ███╗   ██╗\n'
  printf ' ╚██╗██╔╝██╔════╝██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║\n'
  printf '  ╚███╔╝ ██║     ██║     ██║     █████╗  ███████║██╔██╗ ██║\n'
  printf '  ██╔██╗ ██║     ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║\n'
  printf ' ██╔╝ ██╗╚██████╗╚██████╗███████╗███████╗██║  ██║██║ ╚████║\n'
  printf ' ╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝\n'
  printf "${RESET}\n"
  printf "  ${BOLD}Xcode DerivedData Manager — Installer${RESET}\n\n"
}

# ── Checks ───────────────────────────────────────────────────────────────────

check_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    die "xcclean is macOS only. Detected OS: $(uname)"
  fi
}

check_xcode() {
  if ! xcode-select -p &>/dev/null; then
    warn "Xcode command line tools not found. xcclean may not work correctly."
    warn "Install them with: xcode-select --install"
  fi
}

check_install_dir() {
  # Create the directory if it doesn't exist
  if [[ ! -d "$INSTALL_DIR" ]]; then
    info "Directory $INSTALL_DIR does not exist. Creating it..."
    if ! mkdir -p "$INSTALL_DIR" 2>/dev/null; then
      info "Permission denied — retrying with sudo..."
      sudo mkdir -p "$INSTALL_DIR" || die "Failed to create $INSTALL_DIR even with sudo."
    fi
  fi

  # If not writable, re-exec the whole script with sudo automatically
  if [[ ! -w "$INSTALL_DIR" ]]; then
    warn "$INSTALL_DIR requires elevated permissions."
    info "Re-running installer with sudo..."
    echo ""
    exec sudo bash "$0" "$@"
  fi
}

check_already_installed() {
  if command -v "$TOOL_NAME" &>/dev/null; then
    local existing; existing=$(command -v "$TOOL_NAME")
    warn "$TOOL_NAME is already installed at $existing"
    read -rp "  Overwrite? [y/N]: " overwrite
    [[ "$overwrite" =~ ^[Yy]$ ]] || { info "Installation cancelled."; exit 0; }
  fi
}

# ── Install ──────────────────────────────────────────────────────────────────

download_or_copy() {
  local dest="${INSTALL_DIR}/${TOOL_NAME}"

  # If xcclean.sh is in the same directory as this installer, copy it directly
  local script_dir; script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local local_script="${script_dir}/xcclean.sh"

  if [[ -f "$local_script" ]]; then
    info "Found local xcclean.sh — copying..."
    cp "$local_script" "$dest"
  elif command -v curl &>/dev/null; then
    info "Downloading xcclean from GitHub..."
    curl -fsSL "$REPO_URL" -o "$dest" \
      || die "Download failed. Check your connection or the URL: $REPO_URL"
  elif command -v wget &>/dev/null; then
    info "Downloading xcclean via wget..."
    wget -qO "$dest" "$REPO_URL" \
      || die "Download failed. Check your connection or the URL: $REPO_URL"
  else
    die "Neither curl nor wget found. Place xcclean.sh next to install.sh and re-run."
  fi

  chmod +x "$dest"
}

verify_install() {
  if command -v "$TOOL_NAME" &>/dev/null; then
    success "$TOOL_NAME installed at $(command -v "$TOOL_NAME")"
  else
    warn "$TOOL_NAME copied to $INSTALL_DIR but is not in your PATH."
    warn "Add this to your ~/.zshrc or ~/.bashrc:"
    printf "\n    export PATH=\"%s:\$PATH\"\n\n" "$INSTALL_DIR"
  fi
}

# ── Uninstall ────────────────────────────────────────────────────────────────

uninstall() {
  local target="${INSTALL_DIR}/${TOOL_NAME}"

  if [[ ! -f "$target" ]]; then
    local found; found=$(command -v "$TOOL_NAME" 2>/dev/null || true)
    if [[ -n "$found" ]]; then
      target="$found"
    else
      die "$TOOL_NAME is not installed at $INSTALL_DIR or in PATH."
    fi
  fi

  warn "This will remove $target"
  read -rp "  Continue? [y/N]: " confirm
  [[ "$confirm" =~ ^[Yy]$ ]] || { info "Uninstall cancelled."; exit 0; }

  if [[ ! -w "$(dirname "$target")" ]]; then
    info "Permission denied — retrying with sudo..."
    sudo rm -f "$target"
  else
    rm -f "$target"
  fi

  success "$TOOL_NAME removed from $target"
}

# ── Argument parsing ─────────────────────────────────────────────────────────

UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --uninstall|-u)
      UNINSTALL=true
      shift
      ;;
    --dir|-d)
      INSTALL_DIR="${2:?--dir requires a path argument}"
      shift 2
      ;;
    --help|-h)
      printf "Usage: bash install.sh [options]\n\n"
      printf "Options:\n"
      printf "  --uninstall, -u        Remove xcclean\n"
      printf "  --dir, -d <path>       Install to a custom directory (default: /usr/local/bin)\n"
      printf "  --help, -h             Show this help\n"
      exit 0
      ;;
    *)
      die "Unknown option: $1. Run with --help for usage."
      ;;
  esac
done

# ── Entry point ──────────────────────────────────────────────────────────────

print_banner
check_macos

if [[ "$UNINSTALL" == true ]]; then
  uninstall
  exit 0
fi

check_xcode
check_install_dir "$@"
check_already_installed
download_or_copy
verify_install

printf "\n"
info "Run 'xcclean help' to get started."
printf "\n"