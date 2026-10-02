# dynisle

A single "dynamic island" shell for Hyprland on Arch Linux, written in
[Quickshell](https://quickshell.org). One floating pill at the top of the
screen that grows into whatever you need: launcher, control centre, media,
notifications, wallpaper picker, session menu, screenshots.

## Install on a fresh Arch

1. Install Arch (`archinstall` with the *minimal* profile is enough) and log in.
2. One command - gets `git`, clones this repo into place, runs the installer:

   ```sh
   sudo pacman -S --needed git && git clone https://github.com/erro666nofound-hue/dynisle ~/.config/quickshell/dynisle && ~/.config/quickshell/dynisle/install.sh
   ```

3. Reboot and log in on the tuigreet screen.

What it sets up: Hyprland with all the keybinds, window blur and
see-through windows, the shell, kitty/foot/fish/starship and the fastfetch
greeting, nautilus, the dark GTK theme (adw-gtk3) and Papirus icons for
GTK apps, Breeze for Qt apps, the Bibata cursor, Google Sans Flex, and
Vietnamese typing (fcitx5 + Bamboo).

`install.sh` installs packages from Arch's official repositories only - no
AUR helper. The one thing that is not packaged there, the Bibata cursor, comes
from its own GitHub release. It backs up anything it replaces in `~/.config`
to `~/.config/dynisle-backup-<date>/`.
Try `./install.sh --dry-run` first to see every step without changing
anything.

## Keeping the repo in step with your machine

The configs in `dots/` are a copy. After changing things on your machine:

```sh
cd ~/.config/quickshell/dynisle
./install.sh --collect      # copy ~/.config -> dots/
git add -A && git commit -m "update configs" && git push
```

## Keys

| | |
|---|---|
| `SUPER` + `D` | launcher |
| `SUPER` + `R` | control centre |
| `SUPER` + `A` | wallpaper and colours |
| `SUPER` + `S` | lock, sleep, restart, shut down |
| `Shift` + `Print` / `SUPER` + `Print` | screenshot a region / the whole screen |
| `SUPER` + `Space` | Vietnamese typing on/off |

## What is where

| | |
|---|---|
| `shell.qml`, `modules/`, `services/` | the shell |
| `dots/` | Hyprland, hypridle, hyprlock, matugen, kitty, foot, fish, fuzzel, fcitx5, fastfetch |
| `system/` | power-plan helper + polkit rule, greetd config, session launcher |
| `fonts/` | Google Sans Flex |
| `vault/` | design notes and the build history |

## Credits

- The Hyprland config in `dots/hypr/` started from
  [end-4/dots-hyprland](https://github.com/end-4/dots-hyprland) and stays under
  its GPL-3.0 licence (`dots/hypr/LICENSE-end-4-dots-hyprland.txt`).
- Google Sans Flex: SIL Open Font License (`fonts/GoogleSansFlex-LICENSE.txt`).
