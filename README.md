# zsh-config

My zsh configuration for macOS and Debian/Proxmox servers.

## Install

```sh
curl -fsSL https://raw.githubusercontent.com/diegofercri/zsh-config/main/install.sh | bash
```

macOS needs [Homebrew](https://brew.sh) installed first. An existing `~/.zshrc` is saved as `~/.zshrc.bak-<date>`.

## Uninstall

```sh
curl -fsSL https://raw.githubusercontent.com/diegofercri/zsh-config/main/uninstall.sh | bash
```

It restores your previous `~/.zshrc` and, on servers, bash as the login shell. The installed packages stay.

## Font

On macOS the installer adds JetBrains Mono with icons. Select it by hand in each terminal and editor: it is called `JetBrainsMono Nerd Font`.

Servers get no font: over SSH you see the font of the terminal you connect from.

## Usage

- `cheatsheet` lists every alias and function.
- Machine-specific settings go in `~/.zshrc.local`.
