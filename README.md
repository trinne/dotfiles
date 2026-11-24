# dotfiles

Uusi kone käyttökuntoon yhdellä komennolla. Kehitys tapahtuu kontissa, jossa on sama shell ja editori kuin hostilla.

- **[chezmoi](https://chezmoi.io)** hallitsee konfiguraatiotiedostot (`home/`). Templatet erottavat macOS:n, WSL:n ja kontin.
- **[mise](https://mise.jdx.dev)** asentaa työkalut samalla tavalla kaikkialla: perustyökalut kaikille koneille, kielet ja kehitystyökalut projektikohtaisesti.
- **Homebrew** vain macOS:n GUI-sovelluksiin (`home/dot_config/homebrew/Brewfile.tmpl`).
- **devbox** on samoista dotfileistä rakennettu kontti-image. Se rakennetaan jokaisella koneella paikallisesti, eikä rekisteriä tarvita. Se toimii sekä Podmanilla että Dockerilla.

## Asennus

### macOS
```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/trinne/dotfiles/main/install.sh)"
```
Asentaa Xcode CLT:n (jos se puuttuu, aja komento uudelleen dialogin jälkeen), Homebrew'n, Brewfilen sovellukset, valitun konttimoottorin, perustyökalut ja macOS-asetukset sekä rakentaa devbox-imagen. Kysyy ensimmäisellä kerralla:

| Kysymys | Oletus |
|---|---|
| Git `user.name` / `user.email` | – |
| Hostille globaalisti asennettavat toolsetit | ei mitään |
| Konttimoottori (`podman` / `docker`) | `podman` |

Vastaukset tallentuvat tiedostoon `~/.config/chezmoi/chezmoi.toml`. Niitä voi muuttaa myöhemmin komennolla `chezmoi init --prompt && chezmoi apply`.

### Windows (WSL)
1. PowerShell: `wsl --install -d Ubuntu`
2. Ubuntussa sama komento kuin yllä.

Asentaa apt-perustyökalut, valitun konttimoottorin suoraan WSL:ään (Podman tai Docker Engine, ei Docker Desktopia) ja perustyökalut. Lopuksi aja `wsl --shutdown`, jotta oletusshell ja ryhmäjäsenyydet tulevat voimaan. Jos devbox-imagen build ohitettiin, koska moottori ei ollut vielä käytettävissä (esim. Dockerin ryhmäjäsenyys), se rakentuu ensimmäisellä `devbox`-ajolla.

## Mitä asennetaan missä

| | Host (mac / WSL) | devbox-kontti |
|---|---|---|
| **Perusta**: zsh, starship, fzf, zoxide, git, chezmoi, mise, tmux, Neovim, rg, fd, bat, eza, jq, yq, gh, lazygit, delta | ✓ | ✓ (imagessa) |
| **Konttimoottori**: Podman tai Docker/OrbStack | ✓ | – |
| **Toolsetit**: node, python, java, clojure, k8s, aws, shell | vain valitut | projektin `mise.toml`:n mukaan |

- Perusta määritellään tiedostossa `home/dot_config/mise/config.toml`.
- Toolsetit määritellään tiedostossa `home/.chezmoidata/toolsets.toml`. Lisää uusi toolset sinne, niin se on käytettävissä sekä `toolset`-komennolla että hostin valinnoissa.

### Toolsetit projektissa
```sh
cd ~/projects/foo
toolset list               # näytä saatavilla olevat
toolset add node clojure   # kirjoittaa ./mise.toml:n ja asentaa työkalut
```
`toolset add` on lyhenne komennolle `mise use`. Versioita voi muokata suoraan `mise.toml`:ssa, tai lisätä minkä tahansa muun työkalun komennolla `mise use <tool>@<versio>`.

## Kehitys kontissa

### devbox (komentorivi)
`devbox` avaa nykyisen hakemiston kontissa polussa `/workspace`. Kontissa on sama zsh, tmux ja nvim kuin hostilla. Projektin `mise.toml`:n työkalut asennetaan ensimmäisellä käynnistyksellä.
```sh
cd ~/projects/foo && devbox          # interaktiivinen zsh
devbox lein test                     # yksittäinen komento projektin työkaluilla
DEVBOX_ARGS="-p 3000:3000" devbox    # julkaise portti dev-palvelimelle
DEVBOX_DOCKER=1 devbox               # hostin kontti-API mukaan (Testcontainers)
devbox build                         # rakenna image uudelleen (--pull: myös uusi Debian-pohja)
```

| Volume | Sisältö |
|---|---|
| `devbox-mise` | projektien työkalut, yhteinen kaikille projekteille (esim. Java ladataan kerran) |
| `devbox-nvim` | Lazy-pluginit ja mason-LSP:t |
| `devbox-history` | zsh-historia |

Perustyökalut ovat imagessa järjestelmätasolla (`/usr/local/share/mise`), joten volume ei peitä niitä, ja uusi image tuo aina uudet perustyökalut.

### Image rakennetaan paikallisesti
Imagea ei julkaista mihinkään rekisteriin. Jokainen kone rakentaa sen itse dotfiles-checkoutista `~/.local/share/chezmoi` nimellä `localhost/devbox:latest`:
- **Bootstrap** (`install.sh`) rakentaa imagen, jos konttimoottori on jo käytettävissä.
- **`devbox`** rakentaa imagen automaattisesti, jos sitä ei vielä ole.
- **`chezmoi update`** rakentaa imagen uudelleen, jos imageen päätyvät tiedostot (`home/`, `container/`, `install.sh`) muuttuivat.
- **`devbox build --pull`** rakentaa sen käsin. Aja se esimerkiksi silloin, kun haluat perustyökaluista uusimmat versiot.

Paikallisesti muokatut, vielä pushaamattomat dotfilet tulevat mukaan heti, kun ajat `devbox build`.

Git-identiteetti välitetään hostilta. SSH-agentti välitetään Linuxilla/WSL:ssä ja macOSilla Dockerin/OrbStackin kanssa.

### VS Code / JetBrains (Dev Containers)
Kopioi `container/devcontainer/devcontainer.json` projektin `.devcontainer/`-hakemistoon. Se käyttää samaa paikallista imagea (`localhost/devbox:latest`; aja `devbox build`, jos sitä ei vielä ole) ja samoja volumeja, ja `postCreateCommand` asentaa projektin `mise.toml`:n työkalut. Podmanin kanssa VS Code tarvitsee asetuksen `"dev.containers.dockerPath": "podman"`.

## Konttimoottori: Podman vai Docker

Moottori valitaan `chezmoi init`:ssä, ja `devbox` käyttää sitä automaattisesti (`DEVBOX_ENGINE=docker devbox` vaihtaa kertaluonteisesti).

| | Podman (oletus) | Docker |
|---|---|---|
| macOS | `podman` + Podman Desktop, VM `podman machine`:lla | OrbStack |
| WSL / Linux | apt `podman`, rootless, ei daemonia | Docker Engine (get.docker.com) |
| Tiedostojen omistajuus `/workspace`:ssa | säilyy (`--userns=keep-id`) | kontin `dev` = uid 1000, toimii kun host-käyttäjäkin on 1000 (WSL:n oletus) |
| SSH-agentti macOSilla | ei välity: käytä HTTPS + `gh auth login` kontissa | välittyy |
| Docker-API (Testcontainers, compose) | `DOCKER_HOST` asetetaan Podmanin socketiin, `docker` on alias `podman`ille | natiivi |

**Docker Sandboxes** (`sbx`) on standalone, eikä se tarvitse Docker Desktopia eikä Docker Engineä, koska se ajaa sandboxit omissa microVM:issään. Siksi se toimii Podmanin rinnalla.

## Neovim

- **Asennus:** mise asentaa sen perustyökaluna (`neovim` tiedostossa `home/dot_config/mise/config.toml`).
- **Config:** ei ole tässä repossa, vaan omassa repossaan [`trinne/nvim`](https://github.com/trinne/nvim). chezmoi kloonaa sen hakemistoon `~/.config/nvim` (`home/.chezmoiexternal.toml.tmpl`) ja päivittää sen `chezmoi update`:lla viikon välein.
- **Muokkaus:** `~/.config/nvim` on tavallinen git-repo. Muokkaa siellä, commitoi ja pushaa `trinne/nvim`:iin.
- **Pluginit ja LSP:t:** Lazy ja mason asentavat ne ensimmäisellä käynnistyksellä. Kontissa ne tallentuvat `devbox-nvim`-volumeen.
- **Huom:** masonin npm-pohjaiset palvelimet (ts_ls, eslint, prettier…) tarvitsevat Noden. Hostilla Nodea ei ole, ellei `node`-toolsetia ole valittu.

## Päivittäinen käyttö

| Mitä | Komento |
|---|---|
| Muokkaa tiedostoa | `chezmoi edit ~/.zshrc` (tai muokkaa repossa ja `chezmoi apply`) |
| Hae ja aja muutokset | `chezmoi update` |
| Näytä erot | `chezmoi diff` |
| Muuta toolset- tai moottorivalintaa | `chezmoi init --prompt && chezmoi apply` |
| Päivitä työkalut | `mise upgrade` |
| Poista käyttämättömät työkaluversiot | `mise prune` |

Koneelle omat, ei-versioidut asetukset: `~/.config/zsh/local.zsh.local` ja `~/.config/git/local`.

## Rakenne

```
install.sh                    bootstrap (mise → chezmoi init --apply)
home/                         chezmoi-lähde (.chezmoiroot)
  .chezmoi.toml.tmpl          ympäristön tunnistus, git-identiteetti, toolset- ja moottorivalinta
  .chezmoidata/toolsets.toml  toolset-määrittelyt
  .chezmoiexternal.toml.tmpl  zsh-pluginit, tpm, nvim-config (trinne/nvim), alacritty-teemat
  .chezmoiscripts/            paketit, brew bundle, mise install, chsh, konttimoottori, macOS-asetukset
  dot_local/bin/              devbox, devbox-init (kontin entrypoint), toolset
  dot_zshrc.tmpl, dot_zshenv, dot_config/...
container/Dockerfile          devbox-image
container/devcontainer/       devcontainer.json-malli
.github/workflows/test.yml    testit (kontti, Linux-host, macOS, devbox-build × podman/docker), myös viikoittain
```

Imagen voi rakentaa myös toisesta checkoutista, esimerkiksi tätä repoa kehittäessä:
```sh
DEVBOX_SOURCE=~/projects/dotfiles devbox build
```
