# dotfiles

Uusi kone käyttökuntoon yhdellä komennolla, ja sama ympäristö myös kehityskonttiin.

- **[chezmoi](https://chezmoi.io)** hallitsee konfiguraatiotiedostot (`home/`), templatet erottavat macOS:n, WSL:n ja kontin.
- **[mise](https://mise.jdx.dev)** asentaa kielet (Node, Python, Java, Clojure) ja CLI-työkalut samalla tavalla kaikkialla (`home/dot_config/mise/config.toml`).
- **Homebrew** vain macOS:n GUI-sovelluksiin (`home/dot_config/homebrew/Brewfile`).
- **devbox** on samoista dotfileistä rakennettu Docker-image (`ghcr.io/trinne/devbox`).

## Asennus

### macOS
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/trinne/dotfiles/main/install.sh)"
```
Asentaa Xcode CLT:n (jos puuttuu, aja komento uudelleen dialogin jälkeen), Homebrew'n, Brewfilen sovellukset (mm. OrbStack Docker-moottoriksi), mise-työkalut ja macOS-asetukset. Kysyy gitin nimen ja emailin.

### Windows (WSL)
1. PowerShell: `wsl --install -d Ubuntu`
2. Ubuntussa sama komento kuin yllä.

Asentaa apt-perustyökalut, Docker Enginen suoraan WSL:ään (ei Docker Desktopia) ja mise-työkalut. Lopuksi `wsl --shutdown`, jotta docker-ryhmä ja oletusshell tulevat voimaan.

## Kehitys kontissa

**Komentoriviltä:** `devbox` avaa nykyisen hakemiston kontissa (`/workspace`), jossa on sama zsh, tmux, nvim ja työkalut kuin hostilla. Git-identiteetti ja SSH-agentti välitetään hostilta.
```sh
cd ~/projects/foo && devbox          # interaktiivinen zsh
devbox lein test                     # yksittäinen komento
DEVBOX_DOCKER=1 devbox               # hostin Docker-socket mukaan
```

**VS Code / JetBrains:** kopioi `container/devcontainer/devcontainer.json` projektin `.devcontainer/`-hakemistoon. Projektin omat työkaluversiot tulevat sen `mise.toml`:sta.

Image rakennetaan GitHub Actionsissa (amd64 + arm64) jokaisesta pushista ja viikoittain. Paikallisesti:
```sh
docker build -f container/Dockerfile -t devbox .
DEVBOX_IMAGE=devbox devbox
```

## Päivittäinen käyttö

| Mitä | Komento |
|---|---|
| Muokkaa tiedostoa | `chezmoi edit ~/.zshrc` (tai muokkaa repossa ja `chezmoi apply`) |
| Hae ja aja muutokset | `chezmoi update` |
| Näytä erot | `chezmoi diff` |
| Lisää uusi työkalu | lisää `~/.config/mise/config.toml`:iin → `chezmoi re-add` tai muokkaa repossa |
| Päivitä työkalut | `mise upgrade` |

Koneelle omat, ei-versioidut asetukset: `~/.config/zsh/local.zsh.local` ja `~/.config/git/local`.

## Rakenne

```
install.sh                  bootstrap (mise → chezmoi init --apply)
home/                       chezmoi-lähde (.chezmoiroot)
  .chezmoi.toml.tmpl        ympäristön tunnistus (isMac / isWSL / isContainer) ja git-identiteetti
  .chezmoiexternal.toml.tmpl  zsh-pluginit, tpm, nvim-config (trinne/nvim), alacritty-teemat
  .chezmoiscripts/          paketit, brew bundle, mise install, chsh, WSL Docker, macOS-asetukset
  dot_zshrc.tmpl, dot_zshenv, dot_config/...
container/Dockerfile        devbox-image
container/devcontainer/     devcontainer.json-malli
.github/workflows/          testit (Linux + macOS) ja imagen julkaisu
```
