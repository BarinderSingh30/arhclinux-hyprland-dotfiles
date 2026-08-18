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
| which modules are in the bar | `waybar/.config/waybar/config.jsonc` | restart waybar |
| how the bar looks | `theme-src/templates/waybar-style.css.in` | `theme-set` |
| notification behaviour, widgets | `swaync/.config/swaync/config.json` | `swaync-client -R` |
| how notifications/the panel look | `theme-src/templates/swaync-style.css.in` | `theme-set` |
| shell behaviour, aliases, keys | `zsh/.config/zsh/conf/*.zsh` | `exec zsh` |
| the launcher | `rofi/.config/rofi/config.rasi` | nothing |
| terminal behaviour (not color) | `kitty/.config/kitty/kitty.conf` | new kitty window |
| how Dolphin is themed | `dolphin/` + `fileManager` in `conf/binds.lua` | reopen Dolphin |

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

`dolphin/` ships no colors. It just switches Dolphin from `QT_QPA_PLATFORMTHEME=qt6ct` (the
session-wide default, set in `conf/env.lua`) to `gtk3`, for Dolphin alone. Qt's gtk3 platform
theme — `libqgtk3.so`, already part of `qt6-base`, nothing extra installed — builds the Qt
palette from the **GTK theme**, so Dolphin ends up matching the GTK apps instead of fighting
Qt. pavucontrol-qt and wifi-qt keep qt6ct and are untouched.

Note what this does and does not follow: Dolphin tracks `GTK_THEME` (currently `adw-gtk3-dark`
in *both* palettes), **not** the palette's hex values. Switching `theme-set gruvbox` therefore
does not recolor Dolphin — both palettes name the same GTK theme, so it looks identical. A
palette naming a *light* GTK theme would flip Dolphin to light.

Three files would be needed to cover every launch route, and only two live here — the third is
`fileManager` in `hypr/.config/hypr/conf/binds.lua`, because a Hyprland bind execs the binary
directly and never reads a `.desktop` file. Missing that is why `SUPER+E` stayed unthemed once
already. The `.desktop` override covers rofi and "Open With"; the systemd drop-in covers D-Bus
activation of `org.freedesktop.FileManager1` ("Show in folder" from Firefox), which inherits the
`systemctl --user` activation environment instead. **All three must agree.**

The `.desktop` file's header records the three routes that were measured and *failed* — qt6ct's
palette, `kdeglobals`, and KDE's own `BreezeDark.colors` — so they do not get retried. Reverting
to a stock light Dolphin is `stow -D dolphin` plus resetting `fileManager` to plain `"dolphin"`,
then `systemctl --user daemon-reload` and `update-desktop-database ~/.local/share/applications`.

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
stow --no-folding -t ~ hypr waybar swaync kitty rofi zsh cliphist scripts dolphin spotify
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
- **Dolphin is themed through `QT_QPA_PLATFORMTHEME=gtk3`, not qt6ct.** Everything else Qt6 uses
  qt6ct; Dolphin is the one exception, wired up in the `dolphin/` package **and** in
  `binds.lua`. The Qt-native routes were each measured on this machine 2026-08-18 and each
  failed, so do not retry them:
  - qt6ct's `custom_palette` never reaches Dolphin. Confirmed with the stylesheet disabled in an
    isolated `XDG_CONFIG_HOME`, so QSS could not have been masking it.
  - `~/.config/kdeglobals` is inert. `kreadconfig6` reads the values back correctly, so the file
    is well-formed and found — nothing converts it into a `QPalette`. (KDE wants decimal
    `R,G,B` there, not hex, which is a separate trap that wasted time first time round.)
  - KDE's own `/usr/share/color-schemes/BreezeDark.colors`, copied in verbatim, still renders
    light. That is the decisive one: the scheme file is not the problem.
  - `qt-apps.qss` reaches the toolbar and sidebar but never the file-list pane, because
    `KItemListView` is a `QGraphicsWidget` painting from a `KColorScheme`, not a styleable
    `QWidget`. No QSS rule gets in, `#qt_scrollarea_viewport` included.

  What applies KDE color schemes is `KDEPlatformTheme` from **plasma-integration**, which pulls
  `kwin`, `plasma-workspace`, `kscreenlocker` and `krunner` — a second desktop, so it is not an
  option here. `breeze` was installed chasing this and turned out **not** to be needed for the
  gtk3 route; it is ~41 MiB of dead weight and can be removed with
  `sudo pacman -Rs breeze` if you want the space back.
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
  sudo alsactl store          # persist; alsa-restore replays it at boot
  ```

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
