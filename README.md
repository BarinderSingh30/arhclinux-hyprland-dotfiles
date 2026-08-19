# dotfiles

Arch + Hyprland config, managed with GNU Stow.

## Start here

The desktop is **finished and working**. Treat it as a system to make small changes to, not a
project to restart. Before editing anything, know these three invariants — every design decision
below follows from them:

1. **Colors are defined in exactly one place per theme.** `theme-src/palettes/*.env`. Nothing else
   contains a hex value. If you are about to type `#1a1b26` into a config, you are doing it wrong.
2. **Configs that need colors are templates**, rendered by `theme-set`. Editing a generated file is
   pointless — the next `theme-set` overwrites it. Edit the `.in` template.
3. **The plan file is history, not instructions.** `~/.claude/plans/so-i-have-big-swift-nest.md`
   describes how this got built, phase by phase. All seven phases are done. Read it for *why* a
   decision was made; do not re-execute it.

Where to make a given change:

| I want to change… | Edit… | Then run |
|---|---|---|
| any color, or transparency | `theme-src/palettes/<name>.env` | `theme-set` |
| how an app uses those colors | `theme-src/templates/<app>.in` | `theme-set` |
| keybinds | `hypr/.config/hypr/conf/binds.lua` | `hyprctl reload` |
| gaps, borders, blur, animations | `hypr/.config/hypr/conf/{decorations,animations}.lua` | `hyprctl reload` |
| monitors, workspaces, input | `hypr/.config/hypr/conf/{monitors,workspaces,input}.lua` | `hyprctl reload` |
| what starts at login | `hypr/.config/hypr/conf/autostart.lua` | log out / in |
| which Bluetooth devices auto-connect | `gsettings set org.blueman.plugins.autoconnect services` — dconf, **not** in this repo | nothing |
| which modules are in the bar | `waybar/.config/waybar/config.jsonc` | restart waybar |
| how the bar looks | `theme-src/templates/waybar-style.css.in` | `theme-set` |
| notification behaviour, widgets | `swaync/.config/swaync/config.json` | `swaync-client -R` |
| how notifications/the panel look | `theme-src/templates/swaync-style.css.in` | `theme-set` |
| shell behaviour, aliases, keys | `zsh/.config/zsh/conf/*.zsh` | `exec zsh` |
| the launcher | `rofi/.config/rofi/config.rasi` | nothing |
| terminal behaviour (not color) | `kitty/.config/kitty/kitty.conf` | new kitty window |
| how transparent an app's window is | not the palette — see **Transparency** below | varies |
| how KDE apps look (Dolphin, Gwenview, Okular) | `theme-src/templates/kde-colors.colors.in` | `theme-set`, then reopen the app |
| how pavucontrol-qt / wifi-qt look | `theme-src/templates/qt-apps.qss.in` | `theme-set`, then reopen the app |

**Read "System notes" at the bottom before debugging anything that "should work".** Every entry
there is a trap that already cost a debugging session — Hyprland spawning commands without your
PATH, rofi caching the app list forever, a fixed-height rofi window, `hyprctl dispatch` taking Lua
now. They look like bugs in your change and are not.

Adding a new themed app, end to end: add a template to `theme-src/templates/`, add its destination
to the `targets()` heredoc in `scripts/.local/bin/theme-set`, add any new `@KEY@` to **both**
palettes, run `theme-set`. It fails loudly if a marker has no value, so a missed key cannot reach a
live config.

## Layout

Each top-level directory is a **stow package** whose internal structure mirrors `$HOME`:

```
hypr/.config/hypr/      → ~/.config/hypr/
waybar/.config/waybar/  → ~/.config/waybar/   (config.jsonc only; style.css is generated)
swaync/.config/swaync/  → ~/.config/swaync/   (config.json only; style.css is generated)
kitty/.config/kitty/    → ~/.config/kitty/
rofi/.config/rofi/      → ~/.config/rofi/
zsh/.zshenv             → ~/.zshenv           (bootstrap; see below)
zsh/.config/zsh/        → ~/.config/zsh/      (.zshrc + conf/*.zsh)
cliphist/.config/cliphist/ → ~/.config/cliphist/
scripts/.local/bin/     → ~/.local/bin/
dolphin/.local/share/applications/       → ~/.local/share/applications/
dolphin/.config/systemd/user/            → ~/.config/systemd/user/
```

`dolphin/` ships no colors. It switches Dolphin from `QT_QPA_PLATFORMTHEME=qt6ct` (the
session-wide default, set in `conf/env.lua`) to `gtk3`, for Dolphin alone, via a `.desktop`
override plus a systemd drop-in. It also needs `fileManager` in
`hypr/.config/hypr/conf/binds.lua` to agree, because a Hyprland bind execs the binary directly
and never reads a `.desktop` file — missing that is why `SUPER+E` stayed unthemed once already.

**As of 2026-08-19 this package is redundant.** KDE apps are now themed from the palette through
a real KDE color scheme (`theme-src/templates/kde-colors.colors.in`), and `KColorSchemeManager`
sets the application palette *after* the platform theme has had its say — so Dolphin renders
identically whether it starts on `gtk3` or on `qt6ct` (verified both ways, 2026-08-19). The
package is harmless and was left in place rather than removed as a side effect of a bug fix.
Removing it is `stow -D dolphin`, resetting `fileManager` to plain `"dolphin"`, then
`systemctl --user daemon-reload` and `update-desktop-database ~/.local/share/applications`.

Note the old route's limitation, which is why it is no longer the one in use: on `gtk3` Dolphin
tracked `GTK_THEME` (`adw-gtk3-dark` in *both* palettes), **not** the palette's hex values, so
`theme-set gruvbox` never recolored it. The color scheme does follow the palette.

`zsh/.zshenv` is the one file that has to sit directly in `$HOME`. zsh reads its startup files
from `$ZDOTDIR`, falling back to `$HOME` when that is unset — so the variable must be set somewhere
zsh looks *before* it knows about it. The only two candidates are `/etc/zsh/zshenv` (root-owned, and
not shipped on this install) and `~/.zshenv`. That file sets `ZDOTDIR`, and everything else lives
under `~/.config/zsh`.

`~/.config/zsh/.zshrc` is a loader only; the content is in `conf/*.zsh`, sourced in numeric order,
the same shape as `hyprland.lua`. The order matters — `90-plugins.zsh` is numbered 90 because
zsh-syntax-highlighting wraps every ZLE widget that exists when it loads, so anything sourced after
it silently loses highlighting.

`system/` is **not** a stow package either — it holds root-owned config that lives outside `$HOME`
and is installed explicitly:

```sh
sudo install -Dm644 ~/dotfiles/system/greetd/config.toml /etc/greetd/config.toml
```

## Usage

```sh
cd ~/dotfiles
mkdir -p ~/.config/{waybar,swaync,rofi,kitty,theme,gtk-3.0,gtk-4.0,bat,cliphist} ~/.config/qt6ct/colors
mkdir -p ~/.local/share/applications ~/.config/systemd/user/plasma-dolphin.service.d
mkdir -p ~/.config/wireplumber/wireplumber.conf.d
stow --no-folding -t ~ hypr waybar swaync kitty rofi zsh cliphist scripts dolphin spotify zen audio
systemctl --user daemon-reload                 # pick up dolphin/'s systemd drop-in
update-desktop-database ~/.local/share/applications
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
| `~/.config/{waybar/style.css,swaync/style.css,gtk-3.0,gtk-4.0,qt6ct}` | no include mechanism (GTK, qt6ct) or a symlink-fragile one (waybar's GTK CSS needs an absolute `file://`). swaync additionally replaces its *whole* user style.css rather than layering on the system default, so a colors-only patch isn't an option there either. Whole file generated; the template is the source of truth |
| `~/.local/share/color-schemes/Rice.colors` | KDE finds color schemes by *scanning* `<data dir>/color-schemes/*.colors` — no app names the file, the directory is the interface. Under `XDG_DATA_HOME`, not `XDG_CONFIG_HOME`. Filename fixed so `kdeglobals` never needs rewriting on a palette switch |
| `hypr/.config/hypr/conf/theme.lua` — **in this repo** | a bare clone + stow must boot a working compositor before theme-set has ever run. A broken `hyprland.lua` means no desktop |
| `~/.config/hypr/hyprpaper.conf` | hyprpaper doesn't expand `~`, so the absolute path is substituted in |
| `~/.config/hypr/hyprlock.conf` | no include mechanism, and the lock screen should follow the palette |
| `~/.config/theme/wallpaper.jpg` | the palette's `WALLPAPER` image, downscaled to 1920x1080 — hyprpaper decodes to an uncompressed surface, so a 4K source would cost ~32 MB of RAM per output |
| `~/.config/theme/fzf.conf` | fzf's own `FZF_DEFAULT_OPTS_FILE` mechanism is an include, so colors stay separate from behaviour. `conf/40-tools.zsh` exports the path |
| `~/.config/starship.toml` | starship has no include directive, so the whole prompt config is generated. Validate edits with `starship print-config` |
| `~/.config/bat/config` | no include mechanism. Note bat's themes are `.tmTheme` XML, so the palette names a **built-in** theme via `BAT_THEME` rather than generating colors |

Everything except `conf/theme.lua` is build product and is not tracked here.

### Transparency

Two palette keys, so it travels with the theme like everything else:

| Key | Applies to | Default |
|---|---|---|
| `TERM_OPACITY` | kitty `background_opacity` | `0.92` |
| `BAR_OPACITY` | waybar, via GTK `alpha(@bg-dark, …)` | `0.85` |

To change: edit the value in `theme-src/palettes/<name>.env`, run `theme-set`. The bar updates
immediately. **kitty does not** — it applies `background_opacity` at startup, and per its own docs
changing it on config reload only works if `dynamic_background_opacity` was enabled in the original
config. That option is off by default because it carries a rendering cost, and paying it permanently
on an Iris Plus G1 to avoid reopening a terminal is a bad trade. So already-open terminals keep the
old value; a newly opened one is correct.

Verify what kitty actually resolved, rather than guessing from a screenshot:

```sh
kitty +runpy 'from kitty.config import load_config; import os
print(load_config(os.path.expanduser("~/.config/kitty/kitty.conf")).background_opacity)'
```

`alpha()` is GTK's own CSS function (waybar 0.15 links libgtk-3), so the bar colour stays a single
`@define-color` and only its opacity varies — an `rgba()` literal would mean duplicating the hex.

No blur anywhere: not kitty's `background_blur`, not `decoration.blur`. Blur is a per-frame GPU cost
and this machine has an Iris Plus G1; transparency without it is free.

#### Apps whose transparency is *not* palette-driven

Two apps can't take a palette key, because their transparency isn't a color at all. Both are
documented here so the next "make X transparent" doesn't start from scratch.

| App | Mechanism | Where | Value |
|---|---|---|---|
| Spotify | Hyprland window rule, `opacity` | `hypr/.config/hypr/conf/rules.lua` | `0.88` |
| Zen | Zen's own pref `zen.widget.linux.transparency` | `zen/.config/zen/<profile>/user.js` | `true` |

**The distinction that matters, and it is not obvious.** Hyprland's `opacity` is *whole-surface*
alpha: the compositor blends the finished window texture as one image, so it cannot tell an app's
chrome from its content. That is fine for Spotify. It is wrong for a browser — at `0.92` on Zen it
made *the video being watched* translucent, which is what sent this down the second path.

kitty is the counter-example worth holding onto: `background_opacity` is an **app-level** setting,
so only the terminal background goes translucent and the glyphs stay fully opaque. Matching kitty's
*number* on another app does not reproduce kitty's *effect* unless that app also does its own
compositing.

Zen does. `zen.widget.linux.transparency` gates a CSS block in Zen's own
`zen-styles/zen-theme.css` that sets `background: transparent` on `#main-window` and blanks
`--zen-themed-toolbar-bg-transparent` — chrome only. Web content stays opaque because content
transparency is a *separate* pref, `browser.tabs.allow_transparent_browser`, left at its default
`false`. So: **no Hyprland window rule for class `zen`**, on purpose. If one gets added, videos go
see-through again.

It is a widget-level pref, so it needs a full Zen restart, not a reload.

Deliberately **not** enabled: `zen.theme.acrylic-elements`, which adds `backdrop-filter` blur to the
sidebar and urlbar. Zen's own source comment says it "makes zen REALLY slow" — it forces layering
with `translate: 0` on the content browser. Same reasoning as "no blur anywhere" above. It sits
commented out in `user.js`.

`user.js` rather than about:config: Zen rewrites `prefs.js` on exit, so a pref set only through the
UI can be lost. `user.js` is reapplied at every startup.

**`zen/` must be stowed with `--no-folding`** — more so than any other package here. The stow target
is a live browser profile directory. If stow folded it into a symlink, Zen would write its entire
profile — cookies, history, `places.sqlite`, caches — *into this repo*. The profile directory
already exists in practice, so folding won't trigger, but never stow this one bare.

The profile directory name (`2jw4pton.Default (release)`) is generated at first run and is specific
to this install — `installs.ini` names the active one. On a fresh machine it will differ, so the
path inside `zen/` must be renamed to match before stowing, or the `user.js` lands in a profile Zen
never opens and the pref silently does nothing.

Reading Zen's shipped defaults means unpacking `/opt/zen-browser-bin/{browser/,}omni.ja`. Note
**`unzip` is not installed on this machine**, and `bsdtar`/Python's `zipfile` both fail on these
archives ("Bad magic number for central directory") — Mozilla's `.ja` files use an optimized layout.
Scanning for `PK\x03\x04` local file headers and inflating each entry with `zlib.decompress(raw, -15)`
works, and is how the pref table above was found rather than guessed.

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
- **Spotify needs `--ozone-platform=wayland` or it renders blurry.** `conf/env.lua` forces the
  Wayland backend for Qt (`QT_QPA_PLATFORM`), Firefox (`MOZ_ENABLE_WAYLAND`), GTK and SDL, but
  Spotify is a **CEF/Chromium** app and honours none of those — it silently took XWayland, rendered
  at 1x, and got bilinearly upscaled by eDP-1's 1.25x scale. Symptom seen 2026-08-18: the window
  looked soft and smeary, "like a low-bitrate video", on the laptop panel only (HDMI-A-1 is scale 1,
  so no upscale, no blur). The flag goes in `spotify/.config/spotify-flags.conf`, which the Arch
  package's `/usr/bin/spotify` wrapper reads. Verify with `hyprctl clients` — the class flips from
  `Spotify` (XWayland) to `spotify` (Wayland), and `xwayland:` reads `false`. No window rule here
  keys on that class, but a future one must use the lowercase form.
- `hyprland.lua.stock-0.56.2` is the untouched autogenerated config, kept for reference.
- **Removing a D-Bus-activated daemon's package does not kill an already-running instance.**
  `pacman -R` deletes the binary and the `/usr/share/dbus-1/services/*.service` file, but a process
  already forked from that binary keeps running until something kills it — and it keeps holding
  whatever well-known bus name it registered. Symptom seen swapping mako → swaync (2026-08-18): mako
  was `pacman -R`'d, yet swaync's own `.service` unit kept exiting with "Could not acquire
  notification name" and hit systemd's start-limit, because a leftover `mako` process (started
  before the removal) was still sitting on `org.freedesktop.Notifications`. `pgrep -x <old-daemon>`
  and kill it by PID before trusting a replacement daemon's dbus-activation to "just work".
- **KDE apps ignore the qt6ct palette. They take colors from a `.colors` scheme, and with none
  set they load a bundled LIGHT Breeze.** This is the single cause behind "Dolphin/Gwenview/Okular
  look wrong", and it was misdiagnosed once (2026-08-18) before being traced properly
  (2026-08-19). Dolphin, Gwenview, Okular and the polkit agent all link `KF6ColorScheme`, and
  every KF6 app runs `KColorSchemeManager` at startup. Its `init()` (kcolorscheme 6.29) does:

  ```
  scheme = KSharedConfig::openConfig() -> "UiSettings" -> "ColorScheme"   # kdeglobals
  if scheme.isEmpty():  schemePath = automaticColorSchemePath()
  if !schemePath.isEmpty():
      qApp->setPalette(KColorScheme::createApplicationPalette(openConfig(schemePath)))
  ```

  That `setPalette` runs **after** the platform theme, so it overwrites whatever qt6ct built —
  which is why qt6ct's `custom_palette` "never reaches Dolphin". With the key unset,
  `automaticColorSchemePath()` picks Breeze or BreezeDark off Qt's `colorScheme()` style hint,
  and under `QT_QPA_PLATFORMTHEME=qt6ct` that hint reads **light** even though the XDG appearance
  portal correctly reports dark (`dbus-send … portal.Settings.Read org.freedesktop.appearance
  color-scheme` returns `1`). qt6ct does not forward it. Both Breeze schemes are compiled into
  `kcolorscheme` as Qt resources, so this happens with `breeze` **not** installed and
  `/usr/share/color-schemes/` absent — which is exactly this machine.

  The fix is `theme-src/templates/kde-colors.colors.in` → `~/.local/share/color-schemes/Rice.colors`,
  with `theme-set` pointing `kdeglobals` at it via `kwriteconfig6`. It reaches everything QSS
  could not, Dolphin's `KItemListView` file pane included — that pane is a `QGraphicsWidget`
  painting from a `KColorScheme`, so no QSS rule gets in, `#qt_scrollarea_viewport` included.

  Two traps inside that, both of which produced "the file is ignored":
  - `.colors` values are decimal `R,G,B`. Hex is silently dropped and the app falls back to a
    Breeze default. `theme-set` derives a `_RGB` marker for every hex palette key so templates
    stay on one source of truth; the suffix is reserved.
  - Writing color groups straight into `kdeglobals` does nothing — `kreadconfig6` reads them back
    fine, which is what makes it look well-formed. `kdeglobals` only holds the *pointer*
    (`[UiSettings] ColorScheme`); the colors have to live in a `.colors` file in a scanned
    `color-schemes/` directory.

  `plasma-integration`'s `KDEPlatformTheme` is a *different* route to the same end, and still not
  an option: it pulls `kwin`, `plasma-workspace`, `kscreenlocker` and `krunner`. `breeze` is not
  needed either — it was installed chasing this in 2026-08-18 and is ~41 MiB of dead weight;
  `sudo pacman -Rs breeze` if you want the space back.
- **`qt-apps.qss` is passed per app, never through qt6ct's `stylesheets=` key.** That key applies
  a stylesheet to *every* Qt6 app on qt6ct — there is no per-app scoping in it. The sheet is
  written for pavucontrol-qt and wifi-qt, so it sets `QWidget { background: transparent; }` and
  paints checked tool buttons `@URGENT@`; leaking that into KDE apps knocked out every pane
  background and turned Okular's toolbar pink. It now goes in via Qt's own `-stylesheet <file>`
  argument from `mixer-toggle` and `wifi-qt-toggle`, the only two places either app is launched.
  **A third app wanting this sheet must be launched with `-stylesheet` too** — putting the key
  back in `qt6ct.conf.in` would re-break every KDE app.
- **A long-lived Qt app keeps the stylesheet it launched with.** qt6ct reads
  `Interface/stylesheets` once at app startup, so a window opened before a `theme-set` run keeps
  the old look and can appear "half themed" next to freshly started apps. Restart the app before
  concluding a config change did nothing — misreading this sent the Dolphin session above down
  several dead ends.
- **The laptop speakers come up muted on a fresh install, and a half-unmute still sounds dead.**
  Two separate traps stacked here, which cost a long session on 2026-08-18.

  First, `alsa-utils` was never installed, so `/var/lib/alsa/asound.state` did not exist and
  `alsa-restore.service` — already wired into `sound.target`, nothing to enable — had nothing to
  replay. The card therefore came up every boot in the kernel default state: `Master` **muted at
  0%** and `Speaker` **muted**. Nothing in the PipeWire/UCM path ever unmutes them.

  Second, on this Conexant CX11970 `Master` and `Speaker` are two virtual controls over the **same**
  DAC `0x11` output amp, so their attenuations **compound**. Unmuting both to 70% lands the amp at
  `0x1e` (~-44 dB) — technically playing, inaudible in practice. It reads as
  "still broken" and sends you hunting for driver bugs. 90%/90% gives `0x3c` (~-7 dB), which is
  audible. Verify the real gain at the amp, not the percentage:
  ```sh
  awk '/^Node 0x11 /,/^  Connection/' /proc/asound/card0/codec#0 | grep Amp-Out
  amixer -c0 sset Master 90% unmute && amixer -c0 sset Speaker 90% unmute
  sudo alsactl store          # necessary, but NOT sufficient on its own -- see below
  ```

  Third, and the reason `alsactl store` alone does not hold: `alsaucm -c sof-hda-dsp
  list _devices/HiFi` shows the UCM profile **does** define a `Speaker` device, but WirePlumber
  never exposes it as a sink or port (the analog sink carries only an `[Out] Headphones` port) and
  then runs its **DisableSequence**, setting `Speaker Playback Switch off` at every session start.
  `alsa-restore` runs far earlier in boot, so its restored state is overwritten seconds later.
  Reproduce without rebooting — this is the test to use, not a reboot:
  ```sh
  systemctl --user restart wireplumber && sleep 8 && amixer -c0 sget Speaker
  ```
  **This is all moot now** — the card no longer uses UCM at all. See the UCM bypass note below,
  which removes this failure mode along with several others. A `speaker-unmute.service` user unit
  was the interim workaround and has been deleted: under ACP, PipeWire restores the Speaker mixer
  itself (verified by muting Speaker by hand and restarting wireplumber — it came back at 100%).
  The history is kept here only so the symptom is recognisable if UCM is ever re-enabled.

  Two things look like the bug and are **not**. `dmesg` reports `speaker_outs=0` with
  `line_outs=1 (0x17) type:speaker` — the Conexant autoconfig classifies the internal speaker pin
  as a line-out, which is why the speaker shows up under a PipeWire sink named **"Headphones"** and
  why no separate Speaker sink exists. Harmless. And `EAPD 0x0` on pin `0x17` only means the amp is
  powered down because nothing unmuted is playing; it flips to `EAPD 0x2` on its own once audio
  actually flows.

  **Do not force `options snd-intel-dspcfg dsp_driver=1`.** Forcing the legacy HDA driver instead of
  SOF was the wrong hypothesis here, and it would cost the digital mic array — SOF is auto-selected
  precisely because this machine has DMICs (`Digital mics found on Skylake+ platform, using SOF
  driver`).

  Unrelated but adjacent: with the external monitor connected, WirePlumber picks **HDMI1** as the
  default sink, so audio silently goes to the monitor. Check `pactl list sink-inputs` for which sink
  a stream landed on before assuming the speakers are at fault.
- **A stream can be pinned to a device and then ignore the default sink.** WirePlumber's
  `node.stream.restore-target` (default **true**) remembers, per application, whichever sink a
  stream last played on. Move a stream once — `pactl move-sink-input`, or the dropdown in a volume
  applet — and that app is pinned there forever, silently overriding the default sink. Symptom seen
  2026-08-18: Bluetooth buds connected, `a2dp-sink` active, correctly selected as default sink, and
  the browser still played to the laptop speakers with no sound in the buds. Turned off natively,
  so streams always follow the default sink:
  ```sh
  wpctl settings --save node.stream.restore-target false
  wpctl settings node.stream.restore-target        # -> Value: false (Saved: false)
  ```
  `wpctl settings` is the supported interface in WirePlumber 0.5 — no config file needed. The
  schema for every setting, with defaults, is on disk at `/usr/share/wireplumber/wireplumber.conf`
  under `wireplumber.settings.schema`. Read it there rather than guessing key names.

  Deliberately left at the default: `bluetooth.autoswitch-to-headset-profile = true`, so the buds'
  microphone works. The cost is that any app opening a mic drops the buds to HSP/HFP telephone
  quality until it lets go. Set it to `false` if that trade stops being worth it.

  Diagnose routing with `pactl list sink-inputs` (which sink each stream landed on) before touching
  anything else — it is the first thing to check whenever "device is connected but silent".
- **Two more Bluetooth traps, both self-inflicted and both silent.** Seen 2026-08-18 with the
  OnePlus Nord Buds 3r.

  `pactl set-default-sink` writes a **permanent** pin to
  `~/.local/state/wireplumber/default-nodes` as `default.configured.audio.sink`. While that line
  exists, WirePlumber will not auto-select a newly connected Bluetooth device — the buds connect,
  negotiate A2DP, and stay silent because the default never moves. Delete the line (not the file,
  which also holds the source default) and let auto-selection do its job:
  ```sh
  cat ~/.local/state/wireplumber/default-nodes
  wpctl status | sed -n '/Sinks:/,/Sources:/p'   # '*' marks the current default
  ```

  Separately, the buds can get **stuck in `headset-head-unit`** (HSP/HFP, 1ch 16 kHz — audibly
  terrible) with **nothing recording**. Once in that state `pactl set-card-profile ... a2dp-sink`
  fails with `Failure: No such entity`, because BlueZ has stopped advertising the A2DP endpoint at
  all — check `pactl list cards` and you will see only `headset-*` and `off` profiles. Reconnecting
  the device restores the A2DP endpoints (`a2dp-sink` = AAC, priority 133, the one you want):
  ```sh
  bluetoothctl disconnect <MAC> && sleep 4 && bluetoothctl connect <MAC>
  ```
  `bluetooth.autoswitch-to-headset-profile` is deliberately left at its default `true` so the buds'
  mic works; this stuck state is the price. Reconnect rather than fighting the profile.
- **HDMI stole the default sink, and priority could not stop it.** The analog sink's only port is
  `[Out] Headphones`, which reports **"not available"** whenever the 3.5mm jack is empty — even
  though the laptop speakers hang off the same PCM and work fine. WirePlumber filters on
  availability *before* priority when choosing a default, so it skipped the built-in output and
  fell through to HDMI1, playing to a monitor with no speakers. Measured 2026-08-18: setting the
  HDMI sinks to `priority.session = 100` against the analog sink's `1000` changed nothing — the
  default stayed HDMI1. **Do not retry the priority route.** Disabling the HDMI
  nodes was the first fix and it worked, but it was superseded — bypassing UCM (below) removes the
  HDMI sinks anyway *and* gives the speakers a real always-available port, which the node-disable
  approach did not.

  The interaction to keep in mind when any of this is touched: streams follow the default sink
  (`node.stream.restore-target = false`), the default is auto-selected with **no** configured pin in
  `default-nodes`, and the analog sink is a valid target because ACP gives it an
  `analog-output-speaker` port. Bluetooth still wins automatically when connected.
  Re-pinning a default with `pactl set-default-sink` breaks that chain — see the Bluetooth note.
- **ALSA card indices are not stable — never write `-c0` in anything that persists.** Plugging in
  any USB audio device claims card 0 at boot and pushes the built-in codec to card 1:
  ```
  0 [RMX2001  ]: USB-Audio - realme RMX2001      <- phone on USB
  1 [sofhdadsp]: sof-hda-dsp - IL-SwiftSF314_57  <- the actual laptop codec
  ```
  This is nastier than it looks because `amixer -c0 sset Speaker unmute` then unmutes the **phone**
  and still **exits 0**, so `speaker-unmute.service` reported `Result=success` while the laptop
  speakers stayed silent. Symptom seen 2026-08-18: speakers worked before a reboot, dead after one,
  with a green systemd unit and a `sudo alsactl store` state file that both looked correct.
  Address the card by name everywhere — `amixer -c sofhdadsp` — and check `/proc/asound/cards`
  first whenever a mixer command "works" but nothing changes.
- **`speaker-test` exits 0 even when it never opened the device.** There is no `pulse` ALSA PCM on
  this machine — `pipewire-alsa` provides `pipewire` and `default`, nothing else — so
  `speaker-test -D pulse` fails with `Unknown PCM pulse` / `Playback open error: -2` and **still
  returns exit status 0**. Redirect stderr to `/dev/null` and it looks like a successful test while
  producing no sound whatsoever. This wasted a diagnosis round on 2026-08-18, "confirming" working
  audio that was never played. Use `-D default` (or `-D pipewire`), never `-D pulse`, and confirm
  the sink actually left `SUSPENDED` rather than trusting the command:
  ```sh
  (speaker-test -D default -c 2 -t sine -f 440 -l 1 &) ; sleep 2
  pactl list sinks short          # the target sink must read RUNNING
  pactl list sink-inputs          # and a stream must exist on it
  ```
- **An app that was running while sinks came and went may never reattach.** Firefox-based browsers
  (Zen) keep a dead audio pipe when the sink they were bound to disappears — restarting
  WirePlumber, switching profiles, or removing the HDMI sinks all do it. The tell is that
  `pactl list sink-inputs` reports **no streams at all** while the app still shows as a PipeWire
  client in `wpctl status`. PipeWire is fine in that state and a test tone will play normally;
  only the app is stuck. Restart the app, not the machine.
- **`speaker-test`'s built-in sine is too quiet to judge speakers by.** It generates at a low
  amplitude, so on these laptop speakers it sits down in the noise floor: what you hear is hiss
  with a faint tone under it, which is easily mistaken for "the speakers output static instead of
  audio". Chasing that on 2026-08-18 nearly led to swapping the SOF driver for legacy HDA, when
  nothing was wrong. Generate a real signal instead, and judge with actual content (a browser tab)
  as the control:
  ```sh
  python3 -c "
  import math,struct,wave
  w=wave.open('/tmp/t.wav','w'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(48000)
  w.writeframes(b''.join(struct.pack('<hh',*([int(0.85*32767*math.sin(2*math.pi*440*n/48000))]*2))
                for n in range(48000*10))); w.close()"
  pw-play --target <sink-id> /tmp/t.wav
  ```
- **`pw-play` refuses the built-in sink with "no target node available".** Because the analog
  sink's only port reads "not available" with an empty headphone jack, WirePlumber does not treat
  it as a valid automatic target — `wpctl status` shows **no `*`** next to it even while
  `pactl get-default-sink` names it. Native PipeWire clients then fail outright, while
  PulseAudio-API clients (browsers, `pipewire-alsa`) are still routed there and play fine. Pass
  `--target <id>` explicitly when testing; this is a quirk of the test tool, not a fault to fix.
- **UCM is bypassed on the built-in card, and that is the fix that made audio behave.**
  `audio/.config/wireplumber/wireplumber.conf.d/50-alsa-no-ucm.conf` sets
  `api.alsa.use-ucm = false` for `alsa_card.pci-0000_00_1f.3-platform-skl_hda_dsp_generic`.

  Under UCM the analog sink had a single `[Out] Headphones` port whose availability tracked the
  3.5mm jack. Empty jack meant "not available", which meant **no valid default sink existed at
  all** (`wpctl status` showed no `*` anywhere). Disconnecting Bluetooth then destroyed the playing
  stream instead of moving it — the laptop went silent and the app had to be restarted. Native
  PipeWire clients also failed outright with `no target node available`, while PulseAudio-API
  clients still played. The speakers were never a port, because UCM puts Speaker and Headphones on
  the same PCM and PipeWire keeps only the higher-priority one (Headphones 200 > Speaker 100).

  Without UCM, ACP builds the ordinary analog profile and everything falls into place:
  ```
  analog-output-speaker     priority 10000  availability unknown   <- always usable, active
  analog-output-headphones  priority  9900  follows the jack
  ```
  Verified 2026-08-18 with a tone playing throughout: connecting the buds moved the stream to them
  within 3s, disconnecting moved it straight back to the speakers, and the stream survived both.
  ACP also drives the mixer, so no unmute unit is needed.

  Accepted costs: the three HDMI audio outputs are gone (this display has no speakers) and the
  digital mic array is not exposed, so the built-in microphone does not work — only UCM maps those
  PCMs. The Bluetooth headset mic still does. Delete the file and restart wireplumber to return to
  UCM and get the internal mic back.
- **A route WirePlumber has never seen before starts at 6.4% volume, which is silent here.**
  `device.routes.default-sink-volume` ships as `0.064`. This codec's mixer spans -74 dB in 74
  steps, so 6.4% is far below audibility on the built-in speakers — the output is correct and
  simply cannot be heard. It looks exactly like broken hardware, and it fires whenever a *new*
  route appears: a card profile change, the UCM bypass landing, a fresh install. Diagnosed
  2026-08-18 after the speakers stayed silent through a Bluetooth failover while `pactl` reported
  the sink `RUNNING` on `analog-output-speaker`. Raised to a usable default:
  ```sh
  wpctl settings --save device.routes.default-sink-volume 0.65
  wpctl settings device.routes.default-sink-volume        # -> Value: 0.65 (Saved: 0.65)
  ```
  When speakers are "silent", read the **codec amp** before suspecting the driver — it is the
  ground truth and it maps to what you can actually hear:
  ```sh
  awk '/^Node 0x11 /,/^  Connection/' /proc/asound/card0/codec#0 | grep Amp-Out
  ```
  `0x4a` = 0 dB, clean and loud · `0x38` barely audible · `0x33` inaudible on these speakers ·
  `0x1e` nothing. Anything below roughly `0x40` will be reported as "no sound from the speakers".
- **Paired + trusted does not mean auto-connect.** `bluetoothd` never *initiates* a connection to a
  paired BR/EDR device; it only accepts inbound ones. `Trusted: yes` merely means "do not ask me to
  authorise it when it knocks", and `[Policy] AutoEnable` (default `true`) only powers the adapter
  on at boot. So earbuds that are asleep in their case at login stay disconnected until something
  in the session calls `Device.Connect()`. Nothing did, before 2026-08-18.

  The thing that does it is **blueman's AutoConnect applet plugin**, which walks
  `gsettings get org.blueman.plugins.autoconnect services` on startup, on every adapter
  power-on, and **every 60 s** thereafter. The retry loop is the point: it means the buds connect
  whenever they leave the case, not only if they happen to be awake at the moment of login. Each
  entry is an `(address, uuid)` pair, and the all-zero UUID is blueman's "connect every profile"
  sentinel (`plugins/applet/DBusService.py` maps it to a plain `Device.Connect()`):
  ```sh
  gsettings get org.blueman.plugins.autoconnect services
  # [('9C:DE:F0:CA:81:A0', '00000000-0000-0000-0000-000000000000')]
  ```
  In the GUI this is the checkbox under **Auto-connect** when you right-click the device in
  `blueman-manager`. Verified 2026-08-18 by disconnecting the buds twice: with the entry present
  they came back in 39 s and 42 s, and with the list emptied they stayed down for the full 90 s.

  **This setting is dconf, not a file in this repo** — it lives in `~/.config/dconf/user`, a binary
  blob, and `stow` cannot carry it. Re-run the `gsettings set` above after a reinstall, or the buds
  silently go back to never connecting.
- **The Bluetooth tray icon comes from `blueman-applet`, and nothing else publishes one.** Waybar's
  `tray` module is only a StatusNotifierHost — it displays items, it never invents them. Symptom
  before the applet was autostarted: the icon appeared *only* after opening `blueman-manager`,
  which looks like the manager owning the icon but is really D-Bus activation — the manager talks
  to `org.blueman.Applet` (`blueman/main/DBusProxies.py`), and
  `/usr/share/dbus-1/services/org.blueman.Applet.service` starts the applet on demand. Close the
  manager, and the applet (and icon) linger only until the next login.

  It is launched from `conf/autostart.lua`, after waybar so the tray host exists first. It cannot
  be a systemd user unit: blueman ships `/usr/lib/systemd/user/blueman-applet.service`, but that
  unit has **no `[Install]` section**, so `systemctl --user enable` has nothing to hook it to —
  a different failure from the `graphical-session.target` trap that keeps cliphist out of systemd,
  with the same conclusion.

  Check it is actually publishing an item, rather than squinting at the bar:
  ```sh
  busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher \
      org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
  # as 1 ":1.46/org/blueman/sni"
  ```
  Remember the tray is **behind the `󰅂` chevron** on eDP-1 (`group/tray-expander`, click-to-reveal),
  so a correctly running applet still shows nothing until the drawer is opened. ~64 MB RSS, the
  largest single entry in `autostart.lua`.
