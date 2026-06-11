#!/usr/bin/env bash
# xcclean — Xcode DerivedData Manager
# Usage:
#   xcclean             List projects & total size
#   xcclean ls          List all DerivedData projects
#   xcclean size        Show total disk usage
#   xcclean clean       Clean ALL DerivedData (with confirmation)
#   xcclean clean <name> Clean a specific project by name (partial match)
#   xcclean path        Print DerivedData path
#   xcclean help        Show this help

DD=$(defaults read com.apple.dt.Xcode IDECustomDerivedDataLocation 2>/dev/null \ || echo "$HOME/Library/Developer/Xcode/DerivedData")

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
BOLD='\033[1m'
RESET='\033[0m'
NC='\e[0m'

cmd_banner() {
cat << "EOF"

██╗  ██╗ ██████╗ ██████╗██╗     ███████╗ █████╗ ███╗   ██╗
╚██╗██╔╝██╔════╝██╔════╝██║     ██╔════╝██╔══██╗████╗  ██║
 ╚███╔╝ ██║     ██║     ██║     █████╗  ███████║██╔██╗ ██║
 ██╔██╗ ██║     ██║     ██║     ██╔══╝  ██╔══██║██║╚██╗██║
██╔╝ ██╗╚██████╗╚██████╗███████╗███████╗██║  ██║██║ ╚████║
╚═╝  ╚═╝ ╚═════╝ ╚═════╝╚══════╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝

EOF
echo -e "${BOLD}${CYAN}xcclean${RESET} — Xcode DerivedData Manager v1.0.0\n"
}

_size() {
  du -sh "$1" 2>/dev/null | cut -f1
}

_total_size() {
  du -sh "$DD" 2>/dev/null | cut -f1
}

_ensure_dd() {
  if [[ ! -d "$DD" ]]; then
    echo -e "${YELLOW}DerivedData folder not found at:${RESET} $DD"
    exit 0
  fi
}

cmd_help() {
  cmd_banner
  echo -e "  ${GREEN}xcclean help${RESET}         Show this help"
  echo -e "  ${GREEN}xcclean ls${RESET}           List all DerivedData projects"
  echo -e "  ${GREEN}xcclean path${RESET}         Print DerivedData path"
  echo -e "  ${GREEN}xcclean size${RESET}         Show total disk usage"
  echo -e "  ${GREEN}xcclean clean${RESET}        Clean ALL DerivedData (with confirmation)"
  echo -e "  ${GREEN}xcclean clean <name>${RESET} Clean a specific project by partial name"
  echo -e "\n"
}

cmd_path() {
  echo -e "${CYAN}$DD${RESET}"
}

cmd_ls() {
  _ensure_dd
  local count=0
  echo -e "\n${BOLD}DerivedData projects:${RESET}\n"
  printf "  %-48s %8s   %s\n" "Project" "Size" "Modified"
  printf "  %-48s %8s   %s\n" "$(printf '%0.s─' {1..48})" "────────" "────────────"
  for dir in "$DD"/*/; do
    [[ -d "$dir" ]] || continue
    local name; name=$(basename "$dir")
    local size; size=$(_size "$dir")
    local mod; mod=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$dir" 2>/dev/null || date -r "$dir" "+%Y-%m-%d %H:%M" 2>/dev/null)
    printf "  ${BLUE}%-48s${RESET} ${YELLOW}%8s${RESET}   ${GRAY}%s${RESET}\n" "$name" "$size" "$mod"
    ((count++))
  done
  echo ""
  echo -e "  ${BOLD}Total: $(_total_size)${RESET} across $count projects\n"
}

cmd_size() {
  echo -e "${BOLD}DerivedData path:${RESET} ${CYAN}$(cmd_path)${RESET}"
  echo -e "${BOLD}DerivedData disk usage:${RESET} ${YELLOW}$(_total_size)${RESET}"
}

cmd_clean_all() {
  _ensure_dd
  local total; total=$(_total_size)
  echo -e "\n${YELLOW}⚠  This will delete ALL DerivedData ($total).${RESET}"
  echo -e "   Xcode will rebuild indexes on next open.\n"
  read -rp "   Continue? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "${DD:?}"/*
    echo -e "\n${GREEN}✓ DerivedData cleaned ($total freed).${RESET}\n"
  else
    echo -e "\n${GRAY}Aborted.${RESET}\n"
  fi
}

cmd_clean_project() {
  _ensure_dd
  local query="$1"
  local matches=()
  for dir in "$DD"/*/; do
    local name; name=$(basename "$dir")
    if [[ "$name" == *"$query"* ]]; then
      matches+=("$name")
    fi
  done

  if [[ ${#matches[@]} -eq 0 ]]; then
    echo -e "\n${RED}✗  No project matching \"$query\" found.${RESET}"
    echo -e "   Run ${CYAN}xcclean ls${RESET} to see all projects.\n"
    exit 1
  fi

  if [[ ${#matches[@]} -gt 1 ]]; then
    echo -e "\n${YELLOW}Multiple matches found:${RESET}"
    for m in "${matches[@]}"; do
      echo -e "  $m"
    done
    echo -e "\nBe more specific and re-run.\n"
    exit 1
  fi

  local target="${matches[0]}"
  local size; size=$(_size "$DD/$target")
  echo -e "\n${YELLOW}⚠  Removing: $target ($size)${RESET}"
  read -rp "   Continue? [y/N]: " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    rm -rf "$DD/$target"
    echo -e "\n${GREEN}✓ Cleaned $target ($size freed).${RESET}\n"
  else
    echo -e "\n${GRAY}Aborted.${RESET}\n"
  fi
}

# ── Entry point ─────────────────────────────────────────────────────────────

case "${1:-}" in
  ""|help|-h|--help) cmd_help ;;
  ls      ) cmd_ls ;;
  size    ) cmd_size ;;
  path    ) cmd_path ;;
  clean   )
    if [[ -n "${2:-}" ]]; then
      cmd_clean_project "$2"
    else
      cmd_clean_all
    fi
    ;;
  *       )
    echo -e "${RED}xcclean: unknown command '$1'${RESET}"
    echo -e "Run ${CYAN}xcclean help${RESET} for usage.\n"
    exit 1
    ;;
esac
