# AGENTS.md

Guide for AI agents working in this repository.

## What it is

A personal zsh configuration with a single installer. Supported systems:

- macOS with Homebrew (Apple Silicon).
- Debian and Proxmox servers, with no graphical interface. Proxmox is used as root and has no `sudo`.

## Files

- `.zshrc`: the whole configuration. `~/.zshrc` is a symlink to it.
- `starship.toml`: prompt settings. `.zshrc` points `STARSHIP_CONFIG` at it, so it needs no symlink and `~/.config/starship.toml` is ignored.
- `install.sh`: installs the dependencies and creates the symlink. It covers macOS and Debian/Proxmox.
- `README.md`: instructions for a person. Keep it short.
- `AGENTS.md`: this file.

## Rules

- Keep it minimal. One `.zshrc` for every system: no modules, no profiles and no per-system files.
- Anything that applies to one system only goes behind a check, such as `[[ $OSTYPE == darwin* ]]` or `command -v eza`.
- Anything that applies to one machine only (SDK paths, personal aliases) stays out of the repository. It goes in `~/.zshrc.local`, which `.zshrc` loads last when it exists.
- When you add, change or remove an alias or a function, update the `cheatsheet` function in `.zshrc` as well.
- Do not add a dependency when an installed one already does the job. This is why `extract` uses `unar` for `.rar` and `.7z`, and `gunzip` for `.Z`.
- Everything is written in English: code comments, script messages, `README.md` and this file.

## What `.zshrc` does

- Installs zinit on the first start if it is missing, and loads the plugins with it.
- Starship prompt. Completion with fzf-tab.
- Aliases for navigation, `ls` (with eza when installed) and git.
- The theme is Dracula. The prompt gets it from the palette in `starship.toml`; `bat`, `fzf`, fzf-tab and the autosuggestions get it from the THEME section of `.zshrc`. eza, git and syntax highlighting use the terminal's own palette, so they are not themed here.
- The editor is `nano`: macOS ships it and the installer adds it on Debian/Proxmox.
- Functions: `fcd`, `ff`, `extract`, `update` and `cheatsheet`.
- The `up` alias upgrades the system packages: `brew update && brew upgrade` on macOS and `apt update && apt full-upgrade` on Debian/Proxmox. It uses `full-upgrade` because Proxmox recommends it; it does not move to a new major release.
- `update` refreshes only what `apt` and `brew` leave out: this repository (`git pull`), zinit, its plugins and, where it was installed by its own script, starship. It must not call `apt` or `brew`.
- On macOS only: Homebrew, the Bitwarden SSH agent and the Homebrew Ruby. Servers keep their `SSH_AUTH_SOCK`, so agent forwarding still works.

## What `install.sh` does

1. Installs the dependencies.
   - macOS: packages with `brew`, plus the `font-jetbrains-mono-nerd-font` font.
   - Debian/Proxmox: packages with `apt-get`, using `sudo` only when not root. No font is installed.
2. Finds the repository: it uses the clone it runs from or, when run through `curl | bash`, clones or updates `~/.config/zsh-config`.
3. Links `~/.zshrc`. A different existing file is saved as `~/.zshrc.bak-<date>`.
4. On Linux, changes the login shell to zsh.

It must be safe to run more than once. `main` comes first and reads as the list of steps; each step is a function below it. `main` is called on the last line so that `curl | bash` reads the whole script before running any of it.

## Debian specifics

- `fd` is named `fdfind` and `bat` is named `batcat`. The installer creates links in `~/.local/bin`, which `.zshrc` adds to `PATH`.
- `eza` and `starship` are only in apt from Debian 13 / Proxmox 9. Without `eza`, `.zshrc` falls back to `ls`. Without `starship`, the installer uses its official script.
- A session can arrive without a UTF-8 locale: the server may have none as default and some SSH clients (Termius) do not send theirs. `.zshrc` then sets `LC_ALL=C.UTF-8`; without it zsh shows non-ASCII input as `<ffffffe2>` and repeats characters in pasted text.
- `apt-get update` can fail on Proxmox without a subscription because of the enterprise repository. The installer carries on anyway.

## Checking a change

```sh
zsh -n .zshrc
bash -n install.sh
zsh -ic 'type extract update fcd ff cheatsheet'
```

The Linux part has to be tested on a Debian server or container.
