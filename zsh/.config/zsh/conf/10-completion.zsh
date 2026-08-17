# 10-completion.zsh -- Tab completion.
#
# This is the single biggest practical difference between bash and zsh. Tab
# completes not just filenames but command options, git branches, systemd unit
# names, pacman packages, ssh hosts -- and shows a menu you can arrow through.

# zsh-completions installs ~180 extra completion definitions to
# /usr/share/zsh/site-functions, which is already on the default $fpath
# (verified with `zsh -f -c 'print -l $fpath'`), so no fpath edit is needed.

autoload -Uz compinit

# The dump file is a cache of every completion definition found on $fpath.
# Building it takes a noticeable fraction of a second, so:
#   - once a day, run the full compinit and rebuild
#   - otherwise use -C, which trusts the existing dump and skips the scan
#
# (#qN.mh+24) is a glob qualifier, not a filename: N = ignore if absent,
# . = regular files only, mh+24 = modified more than 24 hours ago. So the
# glob matches only when the cache is stale, and the full path runs then.
#
# If a newly installed package's completions don't show up, delete this file
# or run `compinit` by hand -- that is the cost of the cache.
#
# The :- fallback is not decoration. XDG_CACHE_HOME is normally set by
# ~/.zshenv, but if this file is ever sourced without it -- ZDOTDIR overridden
# on the command line, .zshrc sourced by hand -- the path becomes "/zsh/..."
# which cannot be created, and compinit then silently rebuilds from scratch on
# EVERY shell. Measured: 8ms cached versus ~150ms uncached. Worth a fallback.
_zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump"
[[ -d ${_zcompdump:h} ]] || mkdir -p ${_zcompdump:h}

# Rebuild when the dump is MISSING or stale; trust it otherwise.
# The missing case matters: (#qN.mh+24) matches nothing when the file does not
# exist, so testing that glob alone would send a first-ever run down the -C
# "trust the cache" path with no cache to trust, and zcompile would never run.
if [[ ! -f $_zcompdump || -n $_zcompdump(#qN.mh+24) ]]; then
    compinit -d "$_zcompdump"
    # Precompile to bytecode. zsh prefers the .zwc over the plain file and
    # parses it substantially faster. &! detaches it so startup does not wait.
    { zcompile -R -- "$_zcompdump" } &!
else
    compinit -C -d "$_zcompdump"
fi
unset _zcompdump

# --- Behaviour ------------------------------------------------------------
# A real menu you arrow through, rather than a static list printed once.
zstyle ':completion:*' menu select

# Case-insensitive, then partial-word. Typing `dow<Tab>` finds `Downloads`,
# and `f-b<Tab>` finds `foo-bar`. The list is tried in order, so an exact
# match always wins before the fuzzier rules are considered.
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' 'r:|[._-]=* r:|=*'

# Colour completion entries the same way ls colours files, so directories and
# executables are distinguishable in the menu.
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# Group results by what they are and label each group, so `git <Tab>` shows
# "commands" and "aliases" as separate captioned sections instead of one
# undifferentiated wall of words.
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:warnings'     format '%F{red}-- no matches --%f'

# Cache the slow completions (pacman's package list is the main one).
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Don't offer the current directory back when completing `cd ..`.
zstyle ':completion:*:cd:*' ignore-parents parent pwd

# Show a process list when completing kill, so you pick a name not a number.
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'
