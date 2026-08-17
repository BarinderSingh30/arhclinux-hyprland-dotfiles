# 90-plugins.zsh -- the two zsh plugins. Numbered 90 so it loads last.
#
# ORDER INSIDE THIS FILE IS LOAD-BEARING. autosuggestions first,
# syntax-highlighting last. See the note at the bottom.

# ---------------------------------------------------------------------------
# zsh-autosuggestions
#
# As you type, it shows the rest of a matching previous command in grey ahead
# of the cursor. Press the Right arrow (or End) to accept it; keep typing to
# ignore it. It is a suggestion only -- it never runs anything on its own.
# ---------------------------------------------------------------------------
_zas=/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
if [[ -r $_zas ]]; then
    # fg=8 is ANSI "bright black", i.e. whatever the terminal's palette says
    # that is. Deliberately not a hex value: kitty's colours already come from
    # theme-set, so the suggestion tint follows a palette switch for free and
    # needs no template of its own.
    ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

    # history first, then completion: prefer something you have actually run
    # before, and fall back to what completion would have offered.
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    # Don't try to suggest against a pasted wall of text -- past this many
    # characters the search costs more than the suggestion is worth.
    ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20

    source $_zas
fi
unset _zas

# ---------------------------------------------------------------------------
# zsh-syntax-highlighting
#
# Colours the command line AS YOU TYPE: a valid command turns green, an
# unknown one stays red, quotes and paths are highlighted. The red-until-valid
# behaviour catches typos before you press Enter, which is most of its value.
#
# THIS MUST BE THE LAST THING SOURCED IN THE ENTIRE CONFIG.
#
# It works by wrapping every ZLE widget that exists at the moment it loads.
# Widgets defined after it are not wrapped, so anything sourced later -- fzf's
# key bindings, zoxide, a plugin added in future -- silently loses
# highlighting. If you add another plugin, add it ABOVE this line.
# ---------------------------------------------------------------------------
_zsh=/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
if [[ -r $_zsh ]]; then
    # main       = commands, options, quoting, paths
    # brackets   = matches (), [], {} and reddens unbalanced ones
    # These two only. `cursor` and `pattern` add per-keystroke work for very
    # little, and this is a 7.4 GB machine where the prompt should stay snappy.
    ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets)

    # Cap the work on very long lines; beyond this, stop highlighting rather
    # than lag the cursor.
    ZSH_HIGHLIGHT_MAXLENGTH=512

    source $_zsh
fi
unset _zsh
