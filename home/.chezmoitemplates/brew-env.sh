# Homebrew on PATH (scripts may run before any shell has picked it up)
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
