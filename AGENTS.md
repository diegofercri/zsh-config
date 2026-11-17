# AGENTS.md

Guía para agentes de IA que trabajen en este repositorio.

## Qué es

Configuración personal de zsh con un instalador único. Sistemas soportados:

- macOS con Homebrew (Apple Silicon).
- Debian y Proxmox como servidores, sin interfaz gráfica. En Proxmox se trabaja como root y no hay `sudo`.

## Archivos

- `.zshrc`: toda la configuración. Se enlaza desde `~/.zshrc`.
- `install.sh`: instala las dependencias y crea el enlace. Sirve para macOS y para Debian/Proxmox.
- `README.md`: instrucciones para una persona. Debe seguir siendo corto.
- `AGENTS.md`: este archivo.

## Reglas

- Mantenerlo mínimo. Un solo `.zshrc` para todos los sistemas: sin módulos, sin perfiles y sin archivos por sistema.
- Lo que solo vale para un sistema va detrás de una comprobación, por ejemplo `[[ $OSTYPE == darwin* ]]` o `command -v eza`.
- Lo que solo vale para una máquina (rutas de SDK, alias personales) no va en el repositorio. Va en `~/.zshrc.local`, que `.zshrc` carga al final si existe.
- Al añadir, cambiar o quitar un alias o una función, actualizar también la función `cheatsheet` de `.zshrc`.
- No añadir dependencias nuevas si una ya instalada sirve. `extract` usa `unar` para `.rar` y `.7z`, y `gunzip` para `.Z`, por ese motivo.
- Comentarios del código en inglés. README y este archivo en español.

## Qué hace `.zshrc`

- Instala zinit en el primer arranque si falta y carga los plugins con él.
- Prompt con starship. Completado con fzf-tab.
- Alias de navegación, de `ls` (con eza si está instalado) y de git.
- Funciones: `fcd`, `ff`, `extract` y `cheatsheet`.
- En macOS, además: Homebrew, el agente SSH de Bitwarden y el Ruby de Homebrew. En servidores no se toca `SSH_AUTH_SOCK`, para no romper el reenvío de agente.

## Qué hace `install.sh`

1. Instala las dependencias.
   - macOS: paquetes con `brew` y la fuente `font-jetbrains-mono-nerd-font`.
   - Debian/Proxmox: paquetes con `apt-get`, usando `sudo` solo si no es root. No se instala ninguna fuente.
2. Localiza el repositorio: usa el clon desde el que se ejecuta o, si llega por `curl | bash`, clona o actualiza `~/.config/zsh-config`.
3. Enlaza `~/.zshrc`. Si ya había uno distinto, lo guarda como `~/.zshrc.bak-<fecha>`.
4. En Linux, cambia la shell de inicio a zsh.

Debe poder ejecutarse varias veces sin efectos nuevos. Todo el código está dentro de `main` para que `curl | bash` lea el script completo antes de ejecutar nada.

## Particularidades de Debian

- `fd` se llama `fdfind` y `bat` se llama `batcat`. El instalador crea enlaces en `~/.local/bin`, que `.zshrc` añade al `PATH`.
- `eza` y `starship` solo están en apt desde Debian 13 / Proxmox 9. Si falta `eza`, `.zshrc` usa `ls`. Si falta `starship`, el instalador usa su script oficial.
- `apt-get update` puede fallar en Proxmox sin suscripción por el repositorio enterprise. El instalador continúa igualmente.

## Verificar un cambio

```sh
zsh -n .zshrc
bash -n install.sh
zsh -ic 'type extract fcd ff cheatsheet'
```

La parte de Linux hay que probarla en un servidor o contenedor Debian.
