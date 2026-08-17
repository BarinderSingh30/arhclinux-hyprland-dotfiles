# ~/.zshenv -- the bootstrap, and the only zsh file that lives in $HOME.
#
# WHY THIS FILE IS IN $HOME AND NOTHING ELSE IS
#
# zsh reads its startup files from $ZDOTDIR. If ZDOTDIR is unset it falls back
# to $HOME -- so the variable has to be set somewhere zsh looks BEFORE it knows
# about it. There are exactly two such places:
#
#   /etc/zsh/zshenv     root-owned, and this Arch install does not ship one
#                       (verified: /etc/zsh contains only zprofile)
#   ~/.zshenv           this file
#
# So this stays here, sets ZDOTDIR, and every other zsh file moves under
# ~/.config/zsh. Verified working: with ZDOTDIR set here, zsh reads
# $ZDOTDIR/.zshrc and skips $ZDOTDIR/.zshenv (it had already read this one).
#
# KEEP THIS FILE SMALL. Unlike .zshrc, it is read by EVERY zsh -- including
# non-interactive ones spawned by scripts and by `zsh -c`. Anything slow here
# is paid on every single invocation, and anything that prints output will
# corrupt the stdout of scripts that expected data.

# --- XDG base directories -------------------------------------------------
# Set explicitly rather than relying on each program's built-in fallback, so
# the paths below and in conf/*.zsh have something concrete to point at.
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

export ZDOTDIR="$XDG_CONFIG_HOME/zsh"

# --- PATH -----------------------------------------------------------------
# `typeset -U path` makes the array unique-only, so re-sourcing this file (or
# nesting shells) cannot grow PATH without bound. $path and $PATH are tied
# together by zsh, so editing one edits the other.
#
# ~/.local/bin is where the stow `scripts` package lands theme-set.
typeset -U path PATH
path=("$HOME/.local/bin" $path)
export PATH

# --- Pager ----------------------------------------------------------------
# less was NOT installed on this machine until Phase 5; git, man and bat all
# silently degrade without it.
#   -R  pass through color escapes instead of printing them literally
#   -F  don't page output that fits on one screen
#   -X  don't clear the screen on exit, so short output stays visible
export PAGER=less
export LESS='-RFX'
# Keep less's history out of $HOME.
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# Deliberately NOT set here: EDITOR / VISUAL. Editor setup is owned manually
# and is out of scope for this config.
