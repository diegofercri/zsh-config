# zsh-config

Mi configuración de zsh para macOS y servidores Debian/Proxmox.

## Instalación

```sh
curl -fsSL https://raw.githubusercontent.com/diegofercri/zsh-config/main/install.sh | bash
```

En macOS hace falta tener [Homebrew](https://brew.sh) instalado. Si ya existe un `~/.zshrc`, se guarda como `~/.zshrc.bak-<fecha>`.

## Fuente

En macOS se instala JetBrains Mono con iconos. Hay que seleccionarla a mano en cada terminal y editor: se llama `JetBrainsMono Nerd Font`.

En los servidores no se instala ninguna fuente: la que se ve por SSH es la del terminal desde el que te conectas.

## Uso

- `cheatsheet` muestra todos los alias y funciones.
- Los ajustes propios de una máquina van en `~/.zshrc.local`.
- `update` actualiza esta configuración y sus plugins.
- `up` actualiza los paquetes del sistema con `brew` o `apt`.
