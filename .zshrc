# ============================================================================
# ZSH CONFIGURATION - Minimalist Setup
# ============================================================================

# ----------------------------------------------------------------------------
# CORE INITIALIZATION
# ----------------------------------------------------------------------------

# Zinit - Plugin manager
ZINIT_HOME="${HOME}/.local/share/zinit/zinit.git"
if [[ ! -f $ZINIT_HOME/zinit.zsh ]]; then
    print -P "%F{33}Installing zinit...%f"
    mkdir -p "$(dirname $ZINIT_HOME)"
    git clone https://github.com/zdharma-continuum/zinit "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# Homebrew integration (macOS)
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

# Zinit annexes
zinit light-mode for \
    zdharma-continuum/zinit-annex-as-monitor \
    zdharma-continuum/zinit-annex-bin-gem-node \
    zdharma-continuum/zinit-annex-patch-dl

# ----------------------------------------------------------------------------
# ENVIRONMENT VARIABLES
# ----------------------------------------------------------------------------

# macOS only: SSH agent (Bitwarden desktop) and Homebrew Ruby
if [[ $OSTYPE == darwin* ]]; then
    export SSH_AUTH_SOCK="$HOME/.bitwarden-ssh-agent.sock"
    export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
fi

# Local binaries (e.g. Claude Code, fd and bat links on Debian)
export PATH="$HOME/.local/bin:$PATH"

# Default applications
#export EDITOR='nvim'
#export VISUAL='nvim'
export PAGER='less'

# History
HISTFILE="${HOME}/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000

# ----------------------------------------------------------------------------
# SHELL OPTIONS
# ----------------------------------------------------------------------------

# History behavior
setopt EXTENDED_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS

# ----------------------------------------------------------------------------
# OH-MY-ZSH SNIPPETS
# ----------------------------------------------------------------------------

zinit snippet OMZL::git.zsh
zinit snippet OMZL::history.zsh
zinit snippet OMZL::key-bindings.zsh
zinit snippet OMZL::theme-and-appearance.zsh
zinit snippet OMZL::completion.zsh
zinit snippet OMZL::directories.zsh

# ----------------------------------------------------------------------------
# PROMPT
# ----------------------------------------------------------------------------

eval "$(starship init zsh)"

# ----------------------------------------------------------------------------
# PLUGINS
# ----------------------------------------------------------------------------

# Syntax highlighting and autosuggestions
zinit wait lucid for \
    atinit"ZINIT[COMPINIT_OPTS]=-C; zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"!_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions

# Productivity plugins
zinit wait lucid for \
    agkozak/zsh-z \
    MichaelAquilina/zsh-you-should-use \
    paulirish/git-open \
    Aloxaf/fzf-tab

# Enhanced completions
zinit wait lucid for \
    blockf atpull'zinit creinstall -q .' \
        zsh-users/zsh-completions

# ----------------------------------------------------------------------------
# COMPLETION SYSTEM
# ----------------------------------------------------------------------------

autoload -Uz compinit && compinit

# Completion styles
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' verbose yes
zstyle ':completion:*:*:*:*:descriptions' format '%F{green}-- %d --%f'
zstyle ':completion:*:*:*:*:corrections' format '%F{yellow}!- %d (errors: %e) -!%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':fzf-tab:complete:*' fzf-preview 'bat --color=always --line-range :50 {}'

# ----------------------------------------------------------------------------
# FZF INTEGRATION
# ----------------------------------------------------------------------------

if command -v fzf &>/dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --exclude .git'
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --preview-window=right:60%'
fi

# ----------------------------------------------------------------------------
# FUNCTIONS
# ----------------------------------------------------------------------------

# Fuzzy directory navigation
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git . "${1:-.}" | 
        fzf --preview 'eza --tree --level=1 --color=always {}' --preview-window=right:50%) &&
        cd "$dir"
}

# Find in files and edit
ff() {
    local file line
    read -r file line < <(rg --line-number --no-heading --color=always --smart-case "${*:-}" |
        fzf --ansi --delimiter : \
            --preview 'bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window 'up,60%,border-bottom,+{2}+3/3,~3' |
        awk -F: '{print $1, $2}')
    if [[ -n "$file" ]]; then
        ${EDITOR:-vim} "$file" +$line
    fi
}

# Universal file extractor
extract() {
    [[ -n $1 && -f $1 ]] || {
        print -u2 -- "extract: '$1' is not a valid file"
        return 1
    }

    local archive=$1
    [[ $archive == -* ]] && archive="./$archive"

    case $archive in
        *.tar.bz2|*.tbz2) tar xjf "$archive" ;;
        *.tar.gz|*.tgz)   tar xzf "$archive" ;;
        *.tar.xz)         tar xJf "$archive" ;;
        *.tar)            tar xf "$archive"  ;;
        *.bz2)            bunzip2 "$archive" ;;
        *.gz|*.Z)         gunzip "$archive"  ;;
        *.zip)            unzip "$archive"   ;;
        *.rar|*.7z)       unar "$archive"    ;;
        *)
            print -u2 -- "extract: '$1' has an unsupported format"
            return 1
            ;;
    esac
}

# Update what apt and brew leave out: this config, zinit and its plugins
update() {
    local config_dir=${${:-$HOME/.zshrc}:A:h}

    print -- "[*] Updating zsh config..."
    git -C "$config_dir" pull --ff-only || {
        print -u2 -- "update: could not update $config_dir"
        return 1
    }

    print -- "[*] Updating zinit and plugins..."
    # -q keeps zinit from opening its changelog in a pager
    zinit self-update -q || return 1
    zinit update -q --all --parallel || return 1
    zinit cclear

    # Only when starship came from its own installer instead of apt or brew
    if [[ $(command -v starship) == /usr/local/bin/starship ]]; then
        print -- "[*] Updating starship..."
        curl -fsSL https://starship.rs/install.sh | sh -s -- --yes || return 1
    fi

    exec zsh
}

# ----------------------------------------------------------------------------
# ALIASES - SYSTEM
# ----------------------------------------------------------------------------

alias c='clear'
alias reload='source ~/.zshrc'
alias ..='cd ..'
alias ...='cd ../..'
alias .3='cd ../../..'
alias .4='cd ../../../..'
alias mkdir='mkdir -p'

# ----------------------------------------------------------------------------
# ALIASES - FILE LISTING
# ----------------------------------------------------------------------------

if command -v eza &>/dev/null; then
    alias ls='eza --icons=auto --group-directories-first'
    alias l='eza -l --icons=auto --group-directories-first'
    alias ll='eza -la --icons=auto --sort=name --group-directories-first'
    alias lt='eza --tree --level=2 --icons=auto'
    alias ld='eza -lD --icons=auto'
else
    if [[ $OSTYPE == darwin* ]]; then
        alias ls='ls -G'
    else
        alias ls='ls --color=auto'
    fi
    alias l='ls -lh'
    alias ll='ls -lha'
    alias ld='ls -lhd */'
fi

# ----------------------------------------------------------------------------
# ALIASES - GIT
# ----------------------------------------------------------------------------

alias gs='git status'
alias ga='git add'
alias gc='git commit'
alias gcm='git commit -m'
alias gl='git log --graph --oneline --decorate'
alias gd='git diff'
alias gp='git push'
alias gpl='git pull'
alias gco='git checkout'
alias gb='git branch'
alias gba='git branch -a'
alias gcl='git clone'
alias gst='git stash'
alias gstp='git stash pop'
alias gundo='git reset --soft HEAD~1'

# ----------------------------------------------------------------------------
# CHEAT SHEET
# ----------------------------------------------------------------------------

cheatsheet() {
    cat << 'EOF'
┌─────────────────────────────────────────────────────────────────────────────┐
│                        ZSH CONFIGURATION CHEATSHEET                         │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ CUSTOM FUNCTIONS ──────────────────────────────────────────────────────────┐
│                                                                             │
│  fcd [path]               Fuzzy directory navigation with preview           │
│  ff <pattern>             Find in files and open in editor                  │
│  extract <file>           Extract tar, gz, bz2, xz, zip, rar or 7z          │
│  cheatsheet               Display this cheatsheet                           │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ NAVIGATION ────────────────────────────────────────────────────────────────┐
│                                                                             │
│  ..                       Go up one directory                               │
│  ...                      Go up two directories                             │
│  .3                       Go up three directories                           │
│  .4                       Go up four directories                            │
│  z <keyword>              Jump to frequently used directory                 │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ FILE OPERATIONS ───────────────────────────────────────────────────────────┐
│                                                                             │
│  ls                       List files with icons                             │
│  l                        Long format with icons                            │
│  ll                       Long format with hidden files                     │
│  lt                       Tree view (2 levels)                              │
│  ld                       List directories only                             │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ GIT SHORTCUTS ─────────────────────────────────────────────────────────────┐
│                                                                             │
│  gs                       git status                                        │
│  ga <file>                git add                                           │
│  gc                       git commit                                        │
│  gcm "msg"                git commit -m "message"                           │
│  gl                       git log (graph, oneline, decorated)               │
│  gd                       git diff                                          │
│  gp                       git push                                          │
│  gpl                      git pull                                          │
│  gco <branch>             git checkout                                      │
│  gb                       git branch                                        │
│  gba                      git branch -a (all branches)                      │
│  gcl <url>                git clone                                         │
│  gst                      git stash                                         │
│  gstp                     git stash pop                                     │
│  gundo                    Undo last commit (keep changes)                   │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ SHELL MANAGEMENT ──────────────────────────────────────────────────────────┐
│                                                                             │
│  c                        Clear screen                                      │
│  update                   Update this config, zinit and its plugins         │
│  reload                   Reload zsh configuration                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

┌─ USEFUL TIPS ───────────────────────────────────────────────────────────────┐
│                                                                             │
│  • Type part of a command and press ↑/↓ for history matching                │
│  • Auto-suggestions appear in gray - press → to accept                      │
│  • Tab completion shows previews for files and directories                  │
│  • Most commands support fuzzy matching (case insensitive)                  │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘

EOF
}

# ----------------------------------------------------------------------------
# LOCAL OVERRIDES
# ----------------------------------------------------------------------------

# Machine-specific settings that do not belong in the repository
if [[ -r ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi
