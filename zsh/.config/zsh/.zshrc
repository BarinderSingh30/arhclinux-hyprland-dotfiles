# ~/.config/zsh/.zshrc -- interactive shell config.
#
# This file is a LOADER and nothing else, the same shape as hyprland.lua. The
# real content is in conf/*.zsh, sourced in numeric order.
#
# Order is load-bearing, not decorative:
#
#   00-options      shell behaviour and history. Sets extended_glob, which
#                   10-completion's glob qualifiers depend on.
#   10-completion   compinit. Must run before anything that adds completions.
#   20-keys         keybindings.
#   30-aliases      aliases.
#   40-tools        fzf / zoxide / starship / yazi. These define ZLE widgets
#                   and bind keys, so they come after 20-keys.
#   90-plugins      autosuggestions, then syntax-highlighting.
#                   zsh-syntax-highlighting MUST be sourced last of everything
#                   -- it wraps every ZLE widget that exists at the moment it
#                   loads, so any widget defined afterwards goes unhighlighted.
#                   That is why it is 90 and not 50.
#
# Only interactive shells read this file, so nothing here affects scripts.

for _zconf in "$ZDOTDIR"/conf/*.zsh(N); do
    source "$_zconf"
done
unset _zconf

# (N) is a glob qualifier: if conf/ is empty or missing, expand to nothing
# instead of erroring. Without it a fresh clone that has not been stowed yet
# drops you into a shell full of "no matches found" noise.
