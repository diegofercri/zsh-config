#!/usr/bin/env bash
# Removes what install.sh set up. Packages, the font and personal files stay.
set -euo pipefail

readonly HOME_ZSHRC="$HOME/.zshrc"
readonly DOWNLOAD_DIR="$HOME/.config/zsh-config"
readonly ZINIT_DIR="$HOME/.local/share/zinit"
readonly COMPLETION_CACHE_DIR="$HOME/.zsh/cache"
readonly BIN_DIR="$HOME/.local/bin"

main() {
    local config_dir
    config_dir=$(installed_config_dir)
    [[ -n $config_dir ]] || die "zsh-config is not installed: $HOME_ZSHRC does not point to it"

    rm -- "$HOME_ZSHRC"
    restore_previous_zshrc
    rm -rf -- "$ZINIT_DIR" "$COMPLETION_CACHE_DIR"
    remove_debian_links
    use_bash_as_login_shell
    remove_downloaded_repository "$config_dir"
    print_what_is_left
}

# Prints the repository ~/.zshrc links to, or nothing when the link is not ours.
installed_config_dir() {
    [[ -L $HOME_ZSHRC ]] || return 0

    local dir
    dir=$(dirname -- "$(readlink "$HOME_ZSHRC")")
    if [[ -f $dir/install.sh && -f $dir/.zshrc ]]; then
        echo "$dir"
    fi
}

restore_previous_zshrc() {
    # The backup names end in a date, so the last match is the newest.
    local backups=("$HOME_ZSHRC".bak-*)
    local newest=${backups[${#backups[@]} - 1]}
    if [[ -e $newest ]]; then
        mv -- "$newest" "$HOME_ZSHRC"
        echo "Restored $newest as $HOME_ZSHRC"
    fi
}

remove_debian_links() {
    local link
    for link in "$BIN_DIR/fd" "$BIN_DIR/bat"; do
        if [[ -L $link ]]; then
            rm -- "$link"
        fi
    done
}

use_bash_as_login_shell() {
    # install.sh only changes the shell on Linux, and does not record the old
    # one: bash is the default there.
    [[ $(uname -s) == Linux ]] || return 0

    local bash_path user login_shell
    bash_path=$(command -v bash)
    user=$(id -un)
    login_shell=$(getent passwd "$user" | cut -d: -f7)
    if [[ $login_shell == */zsh ]]; then
        as_root chsh -s "$bash_path" "$user" ||
            echo "Could not change the shell. Run: chsh -s $bash_path"
    fi
}

# A clone made by hand is the user's own copy and stays.
remove_downloaded_repository() {
    local config_dir=$1
    if [[ $config_dir == "$DOWNLOAD_DIR" ]]; then
        rm -rf -- "$DOWNLOAD_DIR"
    fi
}

print_what_is_left() {
    echo "Done. Log out and back in to leave this shell."
    echo "Left in place: the installed packages, ~/.zshrc.local and the shell history."
    if [[ $(uname -s) == Darwin ]]; then
        echo "To remove the packages: brew uninstall starship eza fzf fd bat ripgrep unar"
        echo "To remove the font: brew uninstall --cask font-jetbrains-mono-nerd-font"
    else
        echo "To remove the packages: apt remove zsh starship eza fzf fd-find bat ripgrep unar"
    fi
    if [[ -x /usr/local/bin/starship ]]; then
        echo "Starship came from its own installer: rm /usr/local/bin/starship"
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
    printf 'uninstall.sh: %s\n' "$*" >&2
    exit 1
}

# Called on the last line so that `curl ... | bash` reads the whole script
# before running any of it.
main "$@"
