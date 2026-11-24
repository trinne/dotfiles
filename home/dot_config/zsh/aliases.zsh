# Aliases. Ported from the old ~/.config/personal/alias and extended.

alias vim="nvim"
alias vi="nvim"

if command -v eza >/dev/null; then
  alias ls="eza --group-directories-first"
  alias ll="eza -l --git --group-directories-first"
  alias la="eza -la --git --group-directories-first"
  alias lt="eza --tree --level=2"
else
  alias ll="ls -lh"
  alias la="ls -lah"
fi

command -v bat     >/dev/null && alias cat="bat --paging=never"
command -v lazygit >/dev/null && alias lg="lazygit"

alias g="git"
alias k="kubectl"
alias dc="docker compose"
alias reload="exec zsh"
alias cz="chezmoi"
