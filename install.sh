#!/usr/bin/env bash
# Universal installer for macOS (Homebrew) and Debian/Proxmox (apt).
set -euo pipefail

readonly REPO_URL="https://github.com/diegofercri/zsh-config.git"
readonly DOWNLOAD_DIR="$HOME/.config/zsh-config"
readonly STARSHIP_INSTALLER_URL="https://starship.rs/install.sh"
readonly BREW_PACKAGES=(git starship eza fzf fd bat ripgrep unar)
readonly BREW_FONT="font-jetbrains-mono-nerd-font"
readonly APT_PACKAGES=(zsh git curl nano unzip unar fzf fd-find bat ripgrep)

main() {
    install_packages

    local config_dir
    config_dir=$(running_clone_dir)
    if [[ -z $config_dir ]]; then
        config_dir=$DOWNLOAD_DIR
        download_repository "$config_dir"
    fi

    link_zshrc "$config_dir/.zshrc"
    use_zsh_as_login_shell
    echo "Done. Open a new terminal or run: exec zsh"
}

install_packages() {
    case $(uname -s) in
        Darwin) install_macos_packages ;;
        Linux) install_debian_packages ;;
        *) die "unsupported system: $(uname -s)" ;;
    esac
}

install_macos_packages() {
    command -v brew >/dev/null || die "install Homebrew first: https://brew.sh"
    brew install "${BREW_PACKAGES[@]}"
    brew install --cask "$BREW_FONT"
}

install_debian_packages() {
    command -v apt-get >/dev/null || die "only Debian-based systems are supported"
    ((EUID == 0)) || command -v sudo >/dev/null || die "run as root or install sudo"

    # Proxmox without a subscription fails on its enterprise repository.
    as_root apt-get update || true
    as_root apt-get install -y "${APT_PACKAGES[@]}"

    # eza and starship are only packaged from Debian 13 / Proxmox 9.
    as_root apt-get install -y eza || echo "eza is not available: plain ls will be used"
    as_root apt-get install -y starship ||
        curl -fsSL "$STARSHIP_INSTALLER_URL" | sh -s -- --yes

    # Debian ships fd and bat under different names.
    local bin_dir=$HOME/.local/bin
    mkdir -p "$bin_dir"
    ln -sf "$(command -v fdfind)" "$bin_dir/fd"
    ln -sf "$(command -v batcat)" "$bin_dir/bat"
}

# Prints the clone this script runs from, or nothing when it arrives through a pipe.
running_clone_dir() {
    local script=${BASH_SOURCE[0]:-} dir
    [[ -f $script ]] || return 0

    dir=$(cd -- "$(dirname -- "$script")" && pwd -P)
    if [[ -d $dir/.git && -f $dir/.zshrc ]]; then
        echo "$dir"
    fi
}

download_repository() {
    local dir=$1
    if [[ -d $dir/.git ]]; then
        git -C "$dir" pull --ff-only
    else
        mkdir -p "$(dirname -- "$dir")"
        git clone "$REPO_URL" "$dir"
    fi
}

link_zshrc() {
    local repo_zshrc=$1 home_zshrc=$HOME/.zshrc
    if [[ $home_zshrc -ef $repo_zshrc ]]; then
        return 0
    fi

    if [[ -e $home_zshrc || -L $home_zshrc ]]; then
        local backup
        backup="$home_zshrc.bak-$(date +%Y%m%d%H%M%S)"
        mv -- "$home_zshrc" "$backup"
        echo "Previous .zshrc saved as $backup"
    fi
    ln -s "$repo_zshrc" "$home_zshrc"
}

use_zsh_as_login_shell() {
    # macOS already uses zsh.
    [[ $(uname -s) == Linux ]] || return 0

    local zsh_path user login_shell
    zsh_path=$(command -v zsh)
    user=$(id -un)
    login_shell=$(getent passwd "$user" | cut -d: -f7)
    if [[ $login_shell != "$zsh_path" ]]; then
        as_root chsh -s "$zsh_path" "$user" ||
            echo "Could not change the shell. Run: chsh -s $zsh_path"
    fi
}

as_root() {
    if ((EUID == 0)); then
        "$@"
    else
        sudo "$@"
    fi
}

die() {
    printf 'install.sh: %s\n' "$*" >&2
    exit 1
}

# Called on the last line so that `curl ... | bash` reads the whole script
# before running any of it.
main "$@"
