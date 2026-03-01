#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- Colors & Symbols ---
if [ -t 1 ]; then
  BOLD="\033[1m"
  DIM="\033[2m"
  RED="\033[31m"
  GREEN="\033[32m"
  YELLOW="\033[33m"
  BLUE="\033[34m"
  MAGENTA="\033[35m"
  CYAN="\033[36m"
  RESET="\033[0m"
else
  BOLD="" DIM="" RED="" GREEN="" YELLOW="" BLUE="" MAGENTA="" CYAN="" RESET=""
fi

ARROW="${CYAN}==>${RESET}"
CHECK="${GREEN}✓${RESET}"
SKIP="${YELLOW}⏭${RESET}"
GEAR="${BLUE}⚙${RESET}"

info()  { printf "${ARROW} ${BOLD}%s${RESET}\n" "$1"; }
ok()    { printf "  ${CHECK}  %s\n" "$1"; }
skip()  { printf "  ${SKIP}  ${DIM}%s${RESET}\n" "$1"; }
warn()  { printf "  ${YELLOW}!  %s${RESET}\n" "$1"; }
step()  { printf "  ${GEAR}  %s\n" "$1"; }

# --- Banner ---
printf "\n"
printf "${MAGENTA}${BOLD}"
printf "  ╔══════════════════════════════════════╗\n"
printf "  ║         nix-setup bootstrap          ║\n"
printf "  ╚══════════════════════════════════════╝\n"
printf "${RESET}"
printf "${DIM}  %s @ %s${RESET}\n" "$(whoami)" "$(hostname)"
printf "${DIM}  %s %s${RESET}\n" "$(uname -s)" "$(uname -m)"
printf "\n"

# --- Homebrew ---
info "Homebrew"
if command -v brew >/dev/null 2>&1; then
  skip "Already installed ($(brew --version | head -1))"
else
  step "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  if [ "$(uname -m)" = "arm64" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
fi

# --- Brewfile ---
info "Brewfile dependencies"
step "Running brew bundle..."
brew bundle --file="$SCRIPT_DIR/Brewfile"
ok "All formulae and casks installed"

# --- Submodules ---
info "Submodules"
step "Updating dotfiles submodule..."
git -C "$SCRIPT_DIR" submodule update --init --recursive
ok "Submodules up to date"

# --- chezmoi ---
info "chezmoi"
step "Initializing (this will prompt for config values)..."
printf "\n"
chezmoi init "$SCRIPT_DIR/dotfiles"
ok "chezmoi initialized"

step "Previewing changes..."
printf "\n"
if [ -n "$(chezmoi status)" ]; then
  chezmoi diff
  printf "\n"
  printf "  ${YELLOW}${BOLD}Apply these changes? [y/N]${RESET} "
  read -r answer
  case "$answer" in
    [yY]|[yY][eE][sS])
      step "Applying dotfiles..."
      chezmoi apply
      ok "Dotfiles applied"
      ;;
    *)
      warn "Aborted. Run 'chezmoi apply' manually when ready."
      ;;
  esac
fi

# --- mise ---
info "mise"
step "Installing tool versions..."
mise install
ok "All tools installed"

# --- Done ---
printf "\n"
printf "${GREEN}${BOLD}"
printf "  ╔══════════════════════════════════════╗\n"
printf "  ║         Bootstrap complete!          ║\n"
printf "  ╚══════════════════════════════════════╝\n"
printf "${RESET}"
printf "\n"
printf "  Restart your shell or run: ${CYAN}exec \$SHELL${RESET}\n"
printf "\n"
