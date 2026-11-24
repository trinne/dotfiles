# dotfiles

A new machine ready with one command. Development happens in a container that has the same shell and editor as the host.

- **[chezmoi](https://chezmoi.io)** manages the config files (`home/`). Templates handle the differences between macOS, WSL and the container.
- **[mise](https://mise.jdx.dev)** installs tools the same way everywhere: base tools on every machine, languages and dev tools per project.
- **Homebrew** is used only for macOS GUI apps (`home/dot_config/homebrew/Brewfile.tmpl`).
- **devbox** is a container image built from these same dotfiles. Every machine builds it locally, so no registry is needed. It works with both Podman and Docker.

## Installation

### macOS
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/trinne/dotfiles/main/install.sh)"
```
Installs the Xcode Command Line Tools (if they are missing, run the command again after the dialog), Homebrew, the Brewfile apps, the selected container engine, the base tools and the macOS defaults, and builds the devbox image. On the first run it asks:

| Question | Default |
|---|---|
| Git `user.name` / `user.email` | – |
| Toolsets to install globally on the host | none |
| Container engine (`podman` / `docker`) | `podman` |

The answers are stored in `~/.config/chezmoi/chezmoi.toml`. Change them later with `chezmoi init --prompt && chezmoi apply`.

### Windows (WSL)
1. In PowerShell: `wsl --install -d Ubuntu`
2. In Ubuntu, run the same command as above.

Installs the base apt packages, the selected container engine directly inside WSL (Podman or Docker Engine, no Docker Desktop) and the base tools. Finally run `wsl --shutdown` so that the default shell and group memberships take effect. If the devbox image build was skipped because the engine was not usable yet (e.g. the Docker group membership), the image is built on the first `devbox` run.

## What is installed where

| | Host (mac / WSL) | devbox container |
|---|---|---|
| **Base**: zsh, starship, fzf, zoxide, git, chezmoi, mise, tmux, Neovim, rg, fd, bat, eza, jq, yq, gh, lazygit, delta | ✓ | ✓ (in the image) |
| **Container engine**: Podman or Docker/OrbStack | ✓ | – |
| **Toolsets**: node, python, java, clojure, k8s, aws, shell | only the selected ones | from the project's `mise.toml` |

- The base tools are defined in `home/dot_config/mise/config.toml`.
- Toolsets are defined in `home/.chezmoidata/toolsets.toml`. A toolset added there is available both to the `toolset` command and as a host option.

### Toolsets in a project
```sh
cd ~/projects/foo
toolset list               # show the available toolsets
toolset add node clojure   # writes ./mise.toml and installs the tools
```
`toolset add` is a shortcut for `mise use`. Edit versions directly in `mise.toml`, or add any other tool with `mise use <tool>@<version>`.

## Developing in a container

### devbox (command line)
`devbox` opens the current directory in a container at `/workspace`. The container has the same zsh, tmux and nvim as the host. The tools from the project's `mise.toml` are installed on first start.
```sh
cd ~/projects/foo && devbox          # interactive zsh
devbox lein test                     # a single command with the project's tools
DEVBOX_ARGS="-p 3000:3000" devbox    # publish a port for a dev server
DEVBOX_DOCKER=1 devbox               # expose the host container API (Testcontainers)
devbox build                         # rebuild the image (--pull: also a fresh Debian base)
```

| Volume | Contents |
|---|---|
| `devbox-mise` | project tools, shared by all projects (e.g. Java is downloaded once) |
| `devbox-nvim` | Lazy plugins and mason LSPs |
| `devbox-history` | zsh history |

The base tools live system-wide in the image (`/usr/local/share/mise`), so the volume never hides them and a new image always brings new base tools.

### The image is built locally
The image is not published to any registry. Each machine builds it from its dotfiles checkout `~/.local/share/chezmoi` as `localhost/devbox:latest`:
- **Bootstrap** (`install.sh`) builds the image if the container engine is already usable.
- **`devbox`** builds the image automatically if it does not exist yet.
- **`chezmoi update`** rebuilds the image when the files that go into it (`home/`, `container/`, `packages/`, `install.sh`) have changed.
- **`devbox build --pull`** builds it manually. Run it, for example, when you want the latest versions of the base tools.

Local, not yet pushed dotfiles changes are included as soon as you run `devbox build`.

The git identity is passed in from the host. The SSH agent is forwarded on Linux/WSL, and on macOS with Docker/OrbStack.

### VS Code / JetBrains (Dev Containers)
Copy `container/devcontainer/devcontainer.json` to the project's `.devcontainer/` directory. It uses the same local image (`localhost/devbox:latest`; run `devbox build` if it does not exist yet) and the same volumes, and `postCreateCommand` installs the tools from the project's `mise.toml`. With Podman, VS Code needs the setting `"dev.containers.dockerPath": "podman"`.

## Container engine: Podman or Docker

The engine is chosen in `chezmoi init`, and `devbox` uses it automatically (`DEVBOX_ENGINE=docker devbox` switches for a single run).

| | Podman (default) | Docker |
|---|---|---|
| macOS | `podman` + Podman Desktop, VM via `podman machine` | OrbStack |
| WSL / Linux | apt `podman`, rootless, no daemon | Docker Engine (get.docker.com) |
| File ownership in `/workspace` | preserved (`--userns=keep-id`) | the container's `dev` is uid 1000; works when the host user is also 1000 (the WSL default) |
| SSH agent on macOS | not forwarded: use HTTPS + `gh auth login` in the container | forwarded |
| Docker API (Testcontainers, compose) | `DOCKER_HOST` points to Podman's socket, `docker` is an alias for `podman`, `docker-compose` (via mise) serves `podman compose` | native |

**Docker Sandboxes** (`sbx`) is standalone and needs neither Docker Desktop nor Docker Engine, because it runs sandboxes in its own microVMs. It therefore works alongside Podman.

## Neovim

- **Installation:** mise installs it as a base tool (`neovim` in `home/dot_config/mise/config.toml`).
- **Config:** not in this repo but in its own repo, [`trinne/nvim`](https://github.com/trinne/nvim). chezmoi clones it to `~/.config/nvim` (`home/.chezmoiexternal.toml.tmpl`) and `chezmoi update` refreshes it weekly.
- **Editing:** `~/.config/nvim` is a regular git repo. Edit it there, commit and push to `trinne/nvim`.
- **Plugins and LSPs:** Lazy and mason install them on first start. In the container they are stored in the `devbox-nvim` volume.
- **Note:** mason's npm-based servers (ts_ls, eslint, prettier…) need Node. The host has no Node unless the `node` toolset is selected.

## Everyday use

| What | Command |
|---|---|
| Edit a file | `chezmoi edit ~/.zshrc` (or edit in the repo and `chezmoi apply`) |
| Pull and apply changes | `chezmoi update` |
| Show the differences | `chezmoi diff` |
| Change the toolset or engine choice | `chezmoi init --prompt && chezmoi apply` |
| Upgrade tools | `mise upgrade` |
| Remove unused tool versions | `mise prune` |

Machine-specific, unversioned settings: `~/.config/zsh/local.zsh.local` and `~/.config/git/local`.

## Layout

```
install.sh                    bootstrap (mise → chezmoi init --apply)
packages/apt.txt              Debian/Ubuntu packages for hosts and the image
home/                         chezmoi source (.chezmoiroot)
  .chezmoi.toml.tmpl          environment detection, git identity, toolset and engine choice
  .chezmoidata/toolsets.toml  toolset definitions
  .chezmoiexternal.toml.tmpl  zsh plugins, tpm, nvim config (trinne/nvim), alacritty themes
  .chezmoiscripts/            packages, brew bundle, mise install, chsh, container engine, macOS defaults, image build
  .chezmoitemplates/          shell snippets shared by the scripts
  dot_local/bin/              devbox, devbox-init (container entrypoint), toolset
  dot_zshenv.tmpl, dot_zprofile.tmpl, dot_zshrc.tmpl, dot_config/...
container/Dockerfile          devbox image
container/devcontainer/       devcontainer.json template
.github/workflows/test.yml    tests (container, Linux host, macOS, devbox build × podman/docker), also weekly
```

The image can also be built from another checkout, e.g. while developing this repo:
```sh
DEVBOX_SOURCE=~/projects/dotfiles devbox build
```
