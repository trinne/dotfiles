# syntax=docker/dockerfile:1
# devbox: personal development image built from these dotfiles.
# Build from the repo root:  docker build -f container/Dockerfile -t devbox .
FROM debian:trixie-slim

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DEVBOX=1 \
    SHELL=/bin/zsh

# Same package set as home/.chezmoiscripts/run_onchange_before_10-install-packages.sh.tmpl,
# installed here so it is cached in its own layer.
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      sudo zsh git curl ca-certificates unzip xz-utils build-essential tmux less \
      locales openssh-client gnupg procps file \
 && sed -i 's/^# *en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen \
 && rm -rf /var/lib/apt/lists/*

# Non-root user whose login shell is zsh (replaces chsh on hosts)
RUN groupadd --gid "$USER_GID" "$USERNAME" \
 && useradd --uid "$USER_UID" --gid "$USER_GID" --create-home --shell /bin/zsh "$USERNAME" \
 && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USERNAME" \
 && chmod 0440 "/etc/sudoers.d/$USERNAME" \
 && mkdir -p /workspace && chown "$USERNAME:$USERNAME" /workspace

USER $USERNAME
ENV PATH=/home/$USERNAME/.local/bin:$PATH
WORKDIR /home/$USERNAME

COPY --chown=$USERNAME:$USERNAME . /home/$USERNAME/.local/share/chezmoi

# Optional build secret avoids GitHub API rate limits while mise downloads tools:
#   docker build --secret id=github_token,env=GITHUB_TOKEN ...
RUN --mount=type=secret,id=github_token,uid=${USER_UID} \
    if [ -f /run/secrets/github_token ]; then export GITHUB_TOKEN="$(cat /run/secrets/github_token)"; fi \
 && DOTFILES_SOURCE="$HOME/.local/share/chezmoi" sh "$HOME/.local/share/chezmoi/install.sh" \
 && { mise cache clear --yes || true; } \
 && rm -rf "$HOME/.local/share/mise/installs" && mise reshim \
 && mkdir -p "$HOME/.local/share/mise" "$HOME/.local/share/nvim" "$HOME/.local/state/zsh"

# Fail the build if the base toolchain is not usable. Base tools live in
# /usr/local/share/mise; languages come per project (mise.toml) at runtime.
RUN zsh -lic 'nvim --version | head -1 && starship --version && rg --version | head -1 && chezmoi --version' \
 && test -d /usr/local/share/mise/installs/neovim \
 && ! zsh -lc 'command -v node' >/dev/null

WORKDIR /workspace
# Installs the project's mise tools into the devbox-mise volume, then runs the command
ENTRYPOINT ["/home/dev/.local/bin/devbox-init"]
CMD ["zsh", "-l"]
