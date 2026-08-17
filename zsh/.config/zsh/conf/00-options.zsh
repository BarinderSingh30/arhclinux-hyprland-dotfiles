# 00-options.zsh -- shell behaviour and history.

# --- Navigation -----------------------------------------------------------
# auto_cd: typing a bare directory name cds into it, so `~/dotfiles` works
# without the `cd`. auto_pushd keeps a stack of where you have been, which
# makes `cd -` and `cd -2` jump back. pushd_ignore_dups stops the stack
# filling with the same directory; pushd_silent stops it printing the stack
# on every cd.
setopt auto_cd auto_pushd pushd_ignore_dups pushd_silent
DIRSTACKSIZE=20

# --- Globbing -------------------------------------------------------------
# extended_glob turns on qualifiers like *(N) and *(.mh+24), used by .zshrc
# and by 10-completion. It must be set before those run.
setopt extended_glob

# Without this, a typo'd glob aborts the whole command line with
# "no matches found". Leaving it ON is the zsh default and is the safer
# behaviour -- a mistyped `rm *.txtt` should fail, not run `rm` on a literal.
setopt nomatch

# --- Quality of life ------------------------------------------------------
# Allow `# comments` when typing interactively, so a pasted command with a
# trailing comment does not error.
setopt interactive_comments

# No terminal bell on completion ambiguity.
unsetopt beep

# Ctrl+S / Ctrl+Q are legacy terminal flow control that freeze the display and
# confuse anyone who hits them by accident. Freeing them also lets Ctrl+S be
# used as a normal binding.
unsetopt flow_control

# --- History --------------------------------------------------------------
# Kept in XDG_STATE_HOME, not ~/.zsh_history: state is data that survives but
# is not config, and it does not belong in $HOME.
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
HISTSIZE=50000      # entries kept in memory this session
SAVEHIST=50000      # entries written to HISTFILE

# zsh has no default HISTFILE -- verified: it is empty in a bare `zsh -f`.
# Unset means history is silently NOT saved, so the directory must exist.
[[ -d ${HISTFILE:h} ]] || mkdir -p ${HISTFILE:h}

# Same for less: ~/.zshenv points LESSHISTFILE into XDG_STATE_HOME, and less
# just drops its history silently if the directory is not there. Done here
# rather than in .zshenv so scripts don't pay a stat on every invocation.
[[ -d ${LESSHISTFILE:h} ]] || mkdir -p ${LESSHISTFILE:h} 2>/dev/null

setopt extended_history        # record timestamp and duration per entry
setopt hist_expire_dups_first  # when trimming, drop duplicates before uniques
setopt hist_ignore_dups        # don't record a command identical to the last
setopt hist_ignore_space       # a leading space keeps a command out of history
setopt hist_reduce_blanks      # normalise whitespace before storing
setopt hist_verify             # expanding !! puts it on the line for review
                               # instead of running it immediately
setopt inc_append_history      # write as you go, not only at exit -- so a
                               # crashed or killed shell does not lose history
setopt share_history           # and read other shells' writes, so history is
                               # shared live across every open terminal
