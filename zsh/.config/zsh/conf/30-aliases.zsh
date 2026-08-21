# 30-aliases.zsh -- aliases.
#
# An alias is only a nickname for a command, and zsh expands aliases ONLY in
# interactive shells. Scripts, makefiles, git hooks and anything with a
# #!/bin/sh line are completely unaffected by everything in this file. To
# reach the real command at any time, prefix it: `command ls`, or `\ls`.

# --- Listing (eza) --------------------------------------------------------
# eza replaces `ls`. Same job, output built to be read: sizes as 3.5k rather
# than 3576, directories grouped first, an icon per file type, and a git
# column marking files you have changed but not committed.
#
# Note eza's -h is --header (a labelled column row), NOT "human readable" --
# eza is human-readable by default. The header is on for the long listings
# because the columns are otherwise unlabelled; drop -h if it gets noisy.
#
# --icons=auto rather than a bare --icons: `auto` suppresses icons when the
# output is a pipe, so `ls | wc -l` is not counting glyphs.
alias ls='eza --icons=auto --group-directories-first'
alias ll='eza -l -h --icons=auto --group-directories-first --no-user'
alias la='eza -l -a -h --icons=auto --group-directories-first --git'
alias lt='eza --tree --level=2 --icons=auto --group-directories-first'

# --no-user on `ll` drops the owner column: every file here is owned by
# barinder, so it is a column of identical text. `la` keeps it, since that is
# the one you reach for when something looks wrong.

# --- Reading files (bat) --------------------------------------------------
# bat shows a file with syntax colouring and line numbers.
#
# `cat` is deliberately NOT aliased to it. `cat > file` and `cat a b > c` are
# real, common uses that bat does not do, and a beginner following a tutorial
# should not hit a broken `cat`. Type `bat` when you want the pretty version.
alias catn='bat --style=plain --paging=never'   # colour, no line numbers/frame

# --- Searching ------------------------------------------------------------
# fd finds files by NAME, rg searches INSIDE files for text.
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'

# --- Navigation -----------------------------------------------------------
# auto_cd (set in 00-options) means a bare path also works, but these are
# shorter to type than `../../..`.
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'

# `d` prints the directory stack auto_pushd has been building; `1`, `2`, ...
# jump to an entry in it.
alias d='dirs -v | head -10'

# --- Safety ---------------------------------------------------------------
# -I (capital) prompts ONCE before removing three or more files or recursing,
# instead of -i's prompt-per-file. It catches the genuinely destructive
# mistake without training you to hammer `y`.
#
# This is a local convenience, not a guarantee: `rm` on another machine will
# not do this. Do not learn to rely on it.
alias rm='rm -I'

# -i prompts before silently destroying an existing file.
alias cp='cp -i'
alias mv='mv -i'

# --- Human-readable output ------------------------------------------------
alias df='df -h'
alias du='du -h'
alias free='free -h'
alias ip='ip -color=auto'

# --- Misc -----------------------------------------------------------------
alias mkdir='mkdir -pv'          # create parents, and say what was created
alias path='print -l $path'      # PATH, one entry per line
alias reload='exec zsh'          # re-read this config in place

# --- Postgres ---------------------------------------------------------------
# postgresql.service is disabled (no auto-start on boot) to save RAM when
# not actively developing against it. Start it only for the session you need it.
alias pg-on='sudo systemctl start postgresql'
alias pg-off='sudo systemctl stop postgresql'
alias pg-status='systemctl status postgresql'

# --- Pacman ---------------------------------------------------------------
# The four commands actually used day to day. Spelled out rather than
# abbreviated, because pacman's single-letter flags are easy to confuse and
# `-Rns` versus `-Rn` matters.
alias pi='sudo pacman -S'            # install
alias pr='sudo pacman -Rns'          # remove, with unneeded deps and configs
alias pu='sudo pacman -Syu'          # update everything
alias pss='pacman -Ss'               # search the repos
alias pq='pacman -Qi'                # info on an installed package
alias porphans='pacman -Qdtq'        # orphaned packages, safe to remove
