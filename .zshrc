# ---------- History ----------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000

setopt INC_APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_SAVE_NO_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE
setopt HIST_VERIFY


# ---------- Shell behavior ----------
setopt autocd
setopt extendedglob
setopt notify
setopt nomatch


# ---------- Completion ----------
autoload -Uz compinit
compinit

zstyle ':completion:*' menu select


# ---------- Git branch in prompt ----------
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' (%b)'


# ---------- Prompt ----------
precmd() {
  vcs_info
  echo
}

setopt PROMPT_SUBST

if [[ -n "$SSH_CONNECTION" ]]; then
  HOST_INFO='%F{yellow}%m%f '
else
  HOST_INFO=''
fi

PS1='${HOST_INFO}%F{blue}%B%~%b%f%F{red}${vcs_info_msg_0_}%f
%F{magenta}❯%f '


# ---------- Editor ----------
export EDITOR='nano'


# ---------- Aliases ----------
alias cls='clear'
alias ls='command ls --color=auto --group-directories-first -F'
alias la='ls -lAh'
alias grep='grep --color=auto'
alias diff='diff --color=auto'


# ---------- Yazi cwd integration ----------
function y() {
  local tmp cwd
  tmp="$(mktemp -t "yazi-cwd.XXXXXX")"

  command yazi "$@" --cwd-file="$tmp"
  IFS= read -r -d '' cwd < "$tmp"

  [[ "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
  rm -f -- "$tmp"
}


# ---------- Keybindings ----------
cdParentKey() {
  cd ..
  zle accept-line
}

zle -N cdParentKey
bindkey '^[[1;3A' cdParentKey


# ---------- Optional plugins ----------
[[ -f "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$HOME/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] &&
  source "$HOME/.zsh/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"


# ---------- CLI integrations ----------
command -v fzf >/dev/null && source <(fzf --zsh)
command -v zoxide >/dev/null && eval "$(zoxide init --cmd cd zsh)"


# ---------- Node / NVM ----------
export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"
[[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"


# ---------- Custom ----------
alias az-agersi='export AZURE_CONFIG_DIR="$HOME/.azure-agersi"'
