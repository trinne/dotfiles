#!/bin/sh
# Bootstrap a new machine (macOS, WSL/Linux or a container): mise -> chezmoi -> everything else.
#   sh -c "$(curl -fsSL https://raw.githubusercontent.com/trinne/dotfiles/main/install.sh)"
#
# Env:
#   DOTFILES_REPO    GitHub repo to init from (default: trinne/dotfiles)
#   DOTFILES_SOURCE  use an existing local checkout instead of cloning
set -eu

REPO="${DOTFILES_REPO:-trinne/dotfiles}"
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
export PATH="$BIN:$PATH"

# Minimal prerequisites for chezmoi itself on fresh Debian/Ubuntu (incl. WSL)
if [ "$(uname -s)" = "Linux" ] && ! command -v git >/dev/null 2>&1; then
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo"
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends git curl ca-certificates
fi

if ! command -v mise >/dev/null 2>&1; then
  echo "==> Installing mise"
  tmp="$(mktemp)"
  curl -fsSL https://mise.run -o "$tmp"   # fail here (set -e) instead of running an empty script
  MISE_QUIET=1 sh "$tmp"
  rm -f "$tmp"
fi

# chezmoi comes from mise too (it is also listed in ~/.config/mise/config.toml)
if [ -n "${DOTFILES_SOURCE:-}" ]; then
  mise exec chezmoi@latest -- chezmoi init --apply --source "$DOTFILES_SOURCE"
else
  mise exec chezmoi@latest -- chezmoi init --apply "$REPO"
fi

echo
echo "==> Done. Start a new shell: exec zsh -l"
