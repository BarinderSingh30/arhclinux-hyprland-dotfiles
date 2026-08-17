# 20-keys.zsh -- keybindings.
#
# Emacs keymap, which is the one whose bindings match every other text field
# on the system: Ctrl+A start of line, Ctrl+E end, Ctrl+K kill to end,
# Ctrl+W delete word back, Ctrl+U clear line.
bindkey -e

# --- Arrow-key history search ---------------------------------------------
# The single most useful binding here. Type a prefix, press Up, and you cycle
# only through past commands STARTING WITH THAT PREFIX -- `git<Up>` walks your
# git commands, not everything you have ever run. With an empty line it
# behaves exactly like plain history, so nothing is lost.
#
# up-line-or-beginning-search also does the right thing inside a multi-line
# command: Up moves between lines first, and only reaches for history at the
# top. These ship with zsh (/usr/share/zsh/functions/Zle) -- no plugin needed.
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search

# --- Navigation keys ------------------------------------------------------
# Home / End / Delete / arrows are the keys most likely to "do nothing" in a
# hand-rolled zsh config, and the reason is worth writing down.
#
# A terminal sends ONE sequence for Up in its normal state (^[[A) and a
# DIFFERENT one while an application has asked for "application keypad mode"
# (^[OA). zle asks for that mode while it is editing a line. terminfo reports
# only the application-mode form -- verified here: on xterm-kitty,
# terminfo[kcuu1] is ^[OA, so binding terminfo alone leaves ^[[A bound to
# zsh's default and the two disagree the moment anything toggles the mode.
#
# This bit me during Phase 5: with only the terminfo binding in place, Up was
# still running plain up-line-or-history.
#
# So bind BOTH forms. Duplicate bindings to the same widget are harmless, and
# the result survives kitty, a plain TTY, ssh, and tmux without special cases.
_bindkeys() {
    local widget=$1; shift
    local seq
    for seq in "$@"; do
        [[ -n $seq ]] && bindkey "$seq" "$widget"
    done
}

_bindkeys up-line-or-beginning-search   "${terminfo[kcuu1]}" '^[[A' '^[OA'
_bindkeys down-line-or-beginning-search "${terminfo[kcud1]}" '^[[B' '^[OB'
_bindkeys backward-char                 "${terminfo[kcub1]}" '^[[D' '^[OD'
_bindkeys forward-char                  "${terminfo[kcuf1]}" '^[[C' '^[OC'
_bindkeys beginning-of-line             "${terminfo[khome]}" '^[[H' '^[OH' '^[[1~' '^[[7~'
_bindkeys end-of-line                   "${terminfo[kend]}"  '^[[F' '^[OF' '^[[4~' '^[[8~'
_bindkeys delete-char                   "${terminfo[kdch1]}" '^[[3~'
_bindkeys overwrite-mode                "${terminfo[kich1]}" '^[[2~'
_bindkeys backward-delete-char          "${terminfo[kbs]}"   '^?' '^H'

unset -f _bindkeys

# terminfo describes the terminal in its NON-application mode, but zle puts
# the terminal into application mode while it is reading a line -- and in that
# mode some keys emit different sequences. Toggling explicitly on each line
# edit keeps what terminfo reported and what the terminal actually sends in
# agreement. Without this, arrow keys work until zle-line-init and then stop.
if (( ${+terminfo[smkx]} && ${+terminfo[rmkx]} )); then
    autoload -Uz add-zle-hook-widget
    function _zle_application_mode_on()  { echoti smkx }
    function _zle_application_mode_off() { echoti rmkx }
    add-zle-hook-widget -Uz line-init   _zle_application_mode_on
    add-zle-hook-widget -Uz line-finish _zle_application_mode_off
fi

# --- Word boundaries ------------------------------------------------------
# By default zsh treats `/` as part of a word, so Ctrl+W on a path deletes the
# entire path. Removing the path characters from WORDCHARS makes Ctrl+W delete
# one path segment at a time, which is almost always what you meant.
WORDCHARS='*?_-.[]~&!#$%^(){}<>'

# Ctrl+Left / Ctrl+Right jump a word.
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# Shift+Tab walks the completion menu backwards.
[[ -n ${terminfo[kcbt]} ]] && bindkey "${terminfo[kcbt]}" reverse-menu-complete

# Ctrl+Z again to RESUME the job you just suspended. Normally Ctrl+Z suspends
# and then you have to type `fg`; this makes the same key toggle both ways.
function _resume_job {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER='fg'
        zle accept-line
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N _resume_job
bindkey '^Z' _resume_job
