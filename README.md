# dotfiles

Arch + Hyprland config, managed with GNU Stow.

## Layout

Each top-level directory is a **stow package** whose internal structure mirrors `$HOME`:

```
hypr/.config/hypr/      → ~/.config/hypr/
waybar/.config/waybar/  → ~/.config/waybar/   (config.jsonc only; style.css is generated)
kitty/.config/kitty/    → ~/.config/kitty/
rofi/.config/rofi/      → ~/.config/rofi/
zsh/.zshenv             → ~/.zshenv           (bootstrap; see below)
zsh/.config/zsh/        → ~/.config/zsh/      (.zshrc + conf/*.zsh)
cliphist/.config/cliphist/ → ~/.config/cliphist/
scripts/.local/bin/     → ~/.local/bin/
```

`zsh/.zshenv` is the one file that has to sit directly in `$HOME`. zsh reads its startup files
from `$ZDOTDIR`, falling back to `$HOME` when that is unset — so the variable must be set somewhere
zsh looks *before* it knows about it. The only two candidates are `/etc/zsh/zshenv` (root-owned, and
not shipped on this install) and `~/.zshenv`. That file sets `ZDOTDIR`, and everything else lives
under `~/.config/zsh`.

`~/.config/zsh/.zshrc` is a loader only; the content is in `conf/*.zsh`, sourced in numeric order,
the same shape as `hyprland.lua`. The order matters — `90-plugins.zsh` is numbered 90 because
zsh-syntax-highlighting wraps every ZLE widget that exists when it loads, so anything sourced after
it silently loses highlighting.

There is no `mako` package: mako's config has no useful non-color content, so the whole file is
generated (see below).

`system/` is **not** a stow package either — it holds root-owned config that lives outside `$HOME`
and is installed explicitly:

```sh
sudo install -Dm644 ~/dotfiles/system/greetd/config.toml /etc/greetd/config.toml
```

## Usage

```sh
cd ~/dotfiles
mkdir -p ~/.config/{waybar,rofi,kitty,mako,theme,gtk-3.0,gtk-4.0,bat,cliphist} ~/.config/qt6ct/colors
stow --no-folding -t ~ hypr waybar kitty rofi zsh cliphist scripts
stow -D hypr                                   # unlink one package (rollback)
stow -R hypr                                   # re-link after adding files
```

`--no-folding` and the `mkdir` matter: without a real directory already present, stow symlinks the
whole directory into this repo, and generated files would then be written *into* the repo.

## theme-src/ — not a stow package

`theme-src/` is the **source** for the theming system, not something that gets symlinked.

- `palettes/*.env` — the only place colors are defined. One file per theme.
- `templates/*.in`  — per-app templates. Substitution is literal `@KEY@`, not `$VAR`, because CSS,
  rasi and shell all use `$` themselves.

```sh
theme-set              # re-render the active palette (use after editing a template)
theme-set gruvbox      # switch
theme-set --list       # show palettes, * marks active
theme-set --dry-run    # diff what would change, install nothing
```

A template that needs a key its palette doesn't define makes theme-set **fail** rather than write a
literal `@ACCENT@` into a live config. Palettes are parsed, never sourced, so switching a theme
cannot execute anything.

### Where the generated files go

| Destination | Why there |
|---|---|
| `~/.config/theme/{kitty.conf,rofi.rasi}` | the app supports `include`/`@import`, so its hand-written config pulls colors in and layout stays separate |
| `~/.config/{waybar/style.css,mako/config,gtk-3.0,gtk-4.0,qt6ct}` | no include mechanism (GTK, qt6ct, mako) or a symlink-fragile one (waybar's GTK CSS needs an absolute `file://`). Whole file generated; the template is the source of truth |
| `hypr/.config/hypr/conf/theme.lua` — **in this repo** | a bare clone + stow must boot a working compositor before theme-set has ever run. A broken `hyprland.lua` means no desktop |
| `~/.config/hypr/hyprpaper.conf` | hyprpaper doesn't expand `~`, so the absolute path is substituted in |
| `~/.config/hypr/hyprlock.conf` | no include mechanism, and the lock screen should follow the palette |
| `~/.config/theme/wallpaper.jpg` | the palette's `WALLPAPER` image, downscaled to 1920x1080 — hyprpaper decodes to an uncompressed surface, so a 4K source would cost ~32 MB of RAM per output |
| `~/.config/theme/fzf.conf` | fzf's own `FZF_DEFAULT_OPTS_FILE` mechanism is an include, so colors stay separate from behaviour. `conf/40-tools.zsh` exports the path |
| `~/.config/starship.toml` | starship has no include directive, so the whole prompt config is generated. Validate edits with `starship print-config` |
| `~/.config/bat/config` | no include mechanism. Note bat's themes are `.tmTheme` XML, so the palette names a **built-in** theme via `BAT_THEME` rather than generating colors |

Everything except `conf/theme.lua` is build product and is not tracked here.

## scripts/

| Script | What it does |
|---|---|
| `theme-set` | render every config from one palette (see above) |
| `clip-menu` | clipboard history in rofi — `--delete` removes one entry, `--wipe` erases all |
| `cheatsheet` | menu of reference sheets in rofi — `cheatsheet <sheet>` opens one, `--print` for plain stdout |

### cheatsheet

`SUPER + /`. A menu of three sheets; Escape inside a sheet goes back to the menu, Escape at the menu
quits. **Every sheet is generated from the thing it documents** — none is hand-written, so none can
drift when the config changes:

| Sheet | Source | Cost |
|---|---|---|
| hyprland | `hyprctl binds -j` — the compositor's live bind table | 11 ms |
| zsh | `zsh -i -c 'bindkey; alias'` — a real interactive shell | 32 ms |
| yazi | the preset keymap embedded in `/usr/bin/yazi` | 19 ms |

Notes on each, in the order they will bite someone editing this:

- **hyprland** — a bind appears only if it was given a `desc` in `conf/binds.lua`. `modmask` is a
  bitmask (`1` SHIFT, `4` CTRL, `8` ALT, `64` SUPER), confirmed against this config's own binds.
- **zsh** — filtered, because a raw `bindkey` dump is 146 lines. Dropped: `self-insert` and friends,
  everything under the `^X` completion-internals prefix, and `_`-prefixed widget names (except our
  own `_resume_job`). Widgets with no entry in the description table fall back to their own name
  with the dashes removed, so a newly bound widget still shows up rather than vanishing.
  Alt sequences keep their case — `^[c` and `^[C` are *different* bindings (here fzf-cd-widget and
  capitalize-word); Ctrl sequences are upper-cased because `^a` and `^A` are genuinely the same byte.
- **yazi** — yazi 26.x ships no keymap file (`pacman -Ql yazi` lists none) and has no dump command;
  the preset `keymap.toml` is compiled in with `include_str!` and sits in the binary as plain text.
  Read with `grep -a`, not `strings`: 7 ms vs 210 ms on a 23 MB binary, and grep is in `base` while
  binutils is not. Only the `[mgr]` section is shown — press `~` inside yazi for its own help.

**Window height is computed at runtime**, not fixed. A hard `lines: 24` renders a 922px window and
eDP-1 is only 864 logical pixels tall (1080 at scale 1.25), so sheets clipped off the bottom.
`window { height: 80%; }` is *not* the fix — rofi treats it as a fixed height, so the 3-row menu
would also render 696px tall with a large empty box. `max_lines()` instead sizes by row count, which
keeps rofi's shrink-to-fit, using a measured model:

```
window height = 36px per row + 58px chrome     (measured: 24 rows→922px, 18 rows→706px)
lines         = (logical_screen_height * 88% - 58) / 36
```

88% leaves margin, and is the safety net if the font in `config.rasi` changes and 36px stops being
right. eDP-1 gets 19 rows (742px), HDMI-A-1 gets 20 (778px). Verify a change with:

```sh
hyprctl layers -j | jq -r '..|objects|select(.namespace?=="rofi")|"\(.w)x\(.h)"'
```

Two things to know before editing the script: the awk programs live inside single-quoted shell
strings, so **they cannot contain an apostrophe even in a comment** (this cost a debugging round);
and the hyprland `jq` program is in a quoted heredoc for exactly that reason — its key table has to
contain a literal `'`.

**Binds must call these by absolute path.** Hyprland does not spawn commands through a login shell,
so `~/.zshenv` never runs and `~/.local/bin` is *not* on the PATH:

```sh
tr '\0' '\n' < /proc/$(pgrep -x waybar)/environ | grep ^PATH=
# PATH=/usr/local/sbin:/usr/local/bin:/usr/bin:...
```

A bare `clip-menu` in a bind fails silently — the key just does nothing. `conf/binds.lua` prefixes
them with a `bin` local for this reason.

### Clipboard history and passwords

`cliphist` records **everything** copied, including passwords pasted out of a password manager, in
plaintext at `~/.cache/cliphist/db`. Version 0.7.0 has no support for the
`x-kde-passwordManagerHint` MIME hint that would let a manager opt out — verified by inspecting the
binary. The file is mode 644, but `~/.cache` and `~/.cache/cliphist` are both 700, so no other local
user can reach it. To clear it: `clip-menu --wipe`, or `cliphist delete-query <text>` for one thing.

`~/.config/cliphist/config` uses `key value` lines with **no leading dash** — this is undocumented
and was determined by experiment. `-max-items 200` and `max-items=200` both parse as nothing and are
silently ignored, so if a setting appears to do nothing, suspect the syntax first.

## System notes

- Hyprland config is **Lua** (hyprlang deprecated since 0.55). API reference for the installed
  version lives on disk at `/usr/share/hypr/stubs/hl.meta.lua`.
- `hyprctl dispatch` also takes **Lua** now, not the old string form. Dispatchers live under
  `hl.dsp`, so testing an autostart entry by hand is:
  ```sh
  hyprctl dispatch 'hl.dsp.exec_cmd("wl-paste --type text --watch cliphist store")'
  ```
  The bare `hyprctl dispatch exec "..."` form fails with a Lua parse error.
- Piping `hyprshot` into another command **hangs**. It copies to the clipboard via `wl-copy`, which
  must stay resident to serve the clipboard offer, and that daemonized process inherits stdout and
  holds the pipe open. Harmless from a keybind, where there is no pipe.
- **Do not set `drun-use-desktop-cache` in rofi.** It caches the `.desktop` scan and never
  invalidates it — invalidation is a *separate* option, `drun-reload-desktop-cache`. With only the
  first one set, the cache is written once and trusted forever, so newly installed applications
  never appear in the launcher and rebooting does not help. Symptom seen here: the cache was frozen
  at 2026-08-17 16:31 and Spotify and Zen, installed later, were simply absent. Rofi rescans on
  every launch without it, which at 43 `.desktop` files costs nothing measurable.
  Frecency is unaffected — launch counts live in `~/.cache/rofi3.druncache` and are driven by
  `sort: true`, not by the desktop cache.
- `hyprland.lua.stock-0.56.2` is the untouched autogenerated config, kept for reference.
