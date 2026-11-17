#!/usr/bin/env bash
# Universal installer for macOS (Homebrew) and Debian/Proxmox (apt).
set -euo pipefail

REPO_URL="https://github.com/diegofercri/zsh-config.git"
CONFIG_DIR="$HOME/.config/zsh-config"

die() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 1
}

# Wrapped in a function so the whole script is read before anything runs,
# which keeps `curl ... | bash` safe.
main() {
    local os
    os=$(uname -s)

    case $os in
        Darwin)
            command -v brew >/dev/null || die "install Homebrew first: https://brew.sh"
            brew install git starship eza fzf fd bat ripgrep unar
            brew install --cask font-jetbrains-mono-nerd-font
            ;;
        Linux)
            command -v apt-get >/dev/null || die "only Debian-based systems are supported"
            local sudo=""
            if ((EUID != 0)); then
                command -v sudo >/dev/null || die "run as root or install sudo"
                sudo=sudo
            fi
            # Proxmox without a subscription fails on its enterprise repository.
            $sudo apt-get update || true
            $sudo apt-get install -y zsh git curl unzip unar fzf fd-find bat ripgrep
            # eza and starship are only packaged from Debian 13 / Proxmox 9.
            $sudo apt-get install -y eza || echo "eza is not available: plain ls will be used"
            $sudo apt-get install -y starship ||
                curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
            # Debian ships fd and bat under different names.
            mkdir -p "$HOME/.local/bin"
            ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
            ln -sf "$(command -v batcat)" "$HOME/.local/bin/bat"
            ;;
        *)
            die "unsupported system: $os"
            ;;
    esac

    # Use this clone when run from one; otherwise clone or update the repository.
    local source_file=${BASH_SOURCE[0]:-} source_dir=""
    [[ -f $source_file ]] && source_dir=$(cd -- "$(dirname -- "$source_file")" && pwd -P)
    if [[ -n $source_dir && -d $source_dir/.git && -f $source_dir/.zshrc ]]; then
        CONFIG_DIR=$source_dir
    elif [[ -d $CONFIG_DIR/.git ]]; then
        git -C "$CONFIG_DIR" pull --ff-only
    else
        mkdir -p "$(dirname -- "$CONFIG_DIR")"
        git clone "$REPO_URL" "$CONFIG_DIR"
    fi

    if [[ ! $HOME/.zshrc -ef $CONFIG_DIR/.zshrc ]]; then
        if [[ -e $HOME/.zshrc || -L $HOME/.zshrc ]]; then
            local backup
            backup="$HOME/.zshrc.bak-$(date +%Y%m%d%H%M%S)"
            mv -- "$HOME/.zshrc" "$backup"
            echo "Previous .zshrc saved as $backup"
        fi
        ln -s "$CONFIG_DIR/.zshrc" "$HOME/.zshrc"
    fi

    if [[ $os == Linux ]]; then
        local zsh_path user
        zsh_path=$(command -v zsh)
        user=$(id -un)
        if [[ $(getent passwd "$user" | cut -d: -f7) != "$zsh_path" ]]; then
            $sudo chsh -s "$zsh_path" "$user" ||
                echo "Could not change the shell. Run: chsh -s $zsh_path"
        fi
    fi

    echo "Done. Open a new terminal or run: exec zsh"
}

main "$@"
