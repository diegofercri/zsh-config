# zsh-macos

Configuración mínima de zsh para macOS: zinit, starship, fzf y Bitwarden como agente SSH.

## Requisitos

- [Homebrew](https://brew.sh)
- Herramientas: `brew install starship eza fzf fd bat ripgrep`
- Bitwarden de escritorio con el agente SSH activado: `brew install --cask bitwarden`

## Instalación

```sh
SSH_AUTH_SOCK=~/.bitwarden-ssh-agent.sock git clone git@github.com:diegofercri/zsh-macos.git ~/Development/zsh-macos
ln -sf ~/Development/zsh-macos/.zshrc ~/.zshrc
```

Abre una terminal nueva. La primera vez, zinit se instala solo y descarga los plugins.

## Notas

- No añadas Homebrew a `~/.zprofile` aunque el instalador lo diga. El `.zshrc` ya lo carga.
- Si instalas Bitwarden desde la App Store, el socket está en otra ruta. Cambia `SSH_AUTH_SOCK` a `~/Library/Containers/com.bitwarden.desktop/Data/.bitwarden-ssh-agent.sock`.
- `cheatsheet` muestra todos los alias y funciones.
