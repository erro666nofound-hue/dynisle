#!/usr/bin/env bash
# shellcheck disable=SC2088  # the "~/.config" strings are display text
# dynisle installer - Arch Linux + Hyprland.
#
#   ./install.sh              install everything on this machine
#   ./install.sh --dry-run    print what would happen, change nothing
#   ./install.sh --collect    copy THIS machine's configs into dots/ (run
#                             before committing, so the repo matches the desk)
#
#   --no-packages   skip pacman        --no-system   skip everything needing sudo
#
# Every package it installs comes from Arch's official repositories - no AUR
# helper is needed. Anything it would overwrite in ~/.config is copied to
# ~/.config/dynisle-backup-<date>/ first.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
TARGET="$CONFIG/quickshell/dynisle"
BACKUP="$CONFIG/dynisle-backup-$(date +%Y%m%d-%H%M%S)"

DRY=0 PACKAGES=1 SYSTEM=1 COLLECT=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --no-packages) PACKAGES=0 ;;
        --no-system) SYSTEM=0 ;;
        --collect) COLLECT=1 ;;
        -h|--help) sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "unknown option: $arg (try --help)" >&2; exit 2 ;;
    esac
done

say()  { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
note() { printf '    %s\n' "$*"; }
warn() { printf '\033[1;33m !\033[0m  %s\n' "$*" >&2; }
run()  { if ((DRY)); then printf '    [dry-run] %s\n' "$*"; else "$@"; fi; }

# ---------------------------------------------------------------------------
# What belongs to this setup
# ---------------------------------------------------------------------------

# Official repositories only. Checked one by one with `pacman -Si` when this
# list was written.
PACKAGE_LIST=(
    # compositor, session, login screen
    hyprland hypridle hyprlock hyprsunset hyprpolkitagent uwsm
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk greetd greetd-tuigreet
    # the shell itself
    quickshell qt6-5compat qt6-svg qt6-imageformats python-gobject
    # what the shell calls
    matugen grim wl-clipboard brightnessctl cava libpulse networkmanager
    libnotify pacman-contrib imagemagick xdg-utils polkit cliphist fuzzel rsync
    # sound
    pipewire pipewire-pulse wireplumber rtkit
    # terminals and the prompt (python draws the fastfetch black hole)
    kitty foot fish starship eza fastfetch python
    # file manager - SUPER + E opens it
    nautilus
    # how every window looks: GTK theme (nautilus & co), icons, and the KDE
    # platform theme Qt apps and the shell's icon lookup go through
    # (hypr/hyprland/env.lua sets QT_QPA_PLATFORMTHEME=kde)
    adw-gtk-theme papirus-icon-theme breeze breeze-icons plasma-integration
    # what keybinds call: colour picker, media keys, killall, volume mixer
    hyprpicker playerctl psmisc pavucontrol
    # display settings (resolution, position, scale) - writes hypr/monitors.lua
    nwg-displays
    # fonts (Google Sans Flex is not packaged; it ships in fonts/)
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable
    # Vietnamese typing
    fcitx5 fcitx5-bamboo fcitx5-gtk fcitx5-qt fcitx5-configtool
    # keyring
    gnome-keyring
    # to build Google Chrome from its AUR recipe (see step 1b)
    base-devel git
)

# Paths under ~/.config. Directories are mirrored, files are copied.
TRACKED=(
    hypr
    matugen
    kitty
    fastfetch/config.jsonc
    foot/foot.ini
    fuzzel/fuzzel.ini
    fish/config.fish
    fish/auto-Hypr.fish
    fcitx5/profile
    fcitx5/config
    fcitx5/conf
    xdg-desktop-portal/hyprland-portals.conf
    starship.toml
    gtk-3.0/settings.ini
    gtk-4.0/settings.ini
    kdeglobals
    # Chrome's Wayland + input-method flags: without --enable-wayland-ime,
    # Vietnamese typing does not reach Chrome
    chrome-flags.conf
)

# Never carried between machines: backups, this machine's display layout, and
# files another program writes for itself. Excluded files are also never
# DELETED on the receiving side, so a machine keeps its own monitors.lua.
EXCLUDES=(
    --exclude='*.bak*' --exclude='*.old' --exclude='*.new'
    --exclude='_unused/' --exclude='monitors.*' --exclude='workspaces.*'
    --exclude='lumen.conf' --exclude='__restore_video_wallpaper.sh'
    # the lock screen's sizes for THIS machine's scale (fix.sh writes it)
    --exclude='scale.conf'
    # lives only in the repo; --collect's --delete must never remove it
    --exclude='LICENSE-*'
)

# ---------------------------------------------------------------------------
# --collect: this machine -> dots/
# ---------------------------------------------------------------------------
if ((COLLECT)); then
    say "Collecting this machine's configs into $REPO/dots"
    for rel in "${TRACKED[@]}"; do
        src="$CONFIG/$rel"
        dst="$REPO/dots/$rel"
        if [[ ! -e "$src" ]]; then
            warn "missing on this machine, skipped: ~/.config/$rel"
            continue
        fi
        run mkdir -p "$(dirname "$dst")"
        if [[ -d "$src" ]]; then
            run rsync -a --delete "${EXCLUDES[@]}" "$src/" "$dst/"
        else
            run rsync -a "$src" "$dst"
        fi
        note "~/.config/$rel"
    done
    say "Done. Review with 'git status' / 'git diff' before committing."
    exit 0
fi

# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------
if [[ $EUID -eq 0 ]]; then
    echo "Run this as your normal user, not root - it asks for sudo itself." >&2
    exit 1
fi
if ! command -v pacman >/dev/null; then
    echo "This installer is for Arch Linux (pacman not found)." >&2
    exit 1
fi
if [[ ! -d "$REPO/dots" ]]; then
    echo "dots/ is missing next to install.sh - is this a full copy of the repo?" >&2
    exit 1
fi

# 1. packages ---------------------------------------------------------------
if ((PACKAGES)); then
    say "Installing ${#PACKAGE_LIST[@]} packages (pacman will ask to confirm)"
    # -Syu, never -Sy alone: a partial upgrade is how Arch systems break.
    run sudo pacman -Syu --needed "${PACKAGE_LIST[@]}"
elif ! command -v rsync >/dev/null; then
    echo "rsync is needed (sudo pacman -S rsync), or run without --no-packages." >&2
    exit 1
fi

# 1b. Google Chrome - the browser SUPER + W / SUPER + B open -----------------
# Not in Arch's official repositories. A repository that has it (chaotic-aur,
# if set up) is used first, so `pacman -Syu` keeps it updated; otherwise
# scripts/update-chrome builds it from its AUR recipe (run that script again
# to update Chrome later).
if ((PACKAGES)); then
    if command -v google-chrome-stable >/dev/null; then
        note "Google Chrome is already installed"
    elif pacman -Si google-chrome >/dev/null 2>&1; then
        say "Installing Google Chrome"
        run sudo pacman -S --needed --noconfirm google-chrome
    else
        say "Building Google Chrome from the AUR (a few minutes)"
        run "$REPO/scripts/update-chrome" \
            || warn "Google Chrome did not install - SUPER + W falls back to another browser"
    fi
fi

# 2. the shell --------------------------------------------------------------
say "Placing dynisle at $TARGET"
if [[ "$(realpath -m "$TARGET")" == "$REPO" ]]; then
    note "already there"
else
    if [[ -e "$TARGET" || -L "$TARGET" ]]; then
        run mkdir -p "$BACKUP/quickshell"
        run mv "$TARGET" "$BACKUP/quickshell/dynisle"
        note "old copy moved to $BACKUP/quickshell/dynisle"
    fi
    run mkdir -p "$(dirname "$TARGET")"
    # A link, so `git pull` in the repo updates the running shell.
    run ln -s "$REPO" "$TARGET"
    note "linked to $REPO"
fi

# 3. configs ----------------------------------------------------------------
say "Copying configs into ~/.config (anything replaced is backed up first)"
for rel in "${TRACKED[@]}"; do
    src="$REPO/dots/$rel"
    dst="$CONFIG/$rel"
    [[ -e "$src" ]] || { warn "not in dots/, skipped: $rel"; continue; }

    if [[ -e "$dst" ]]; then
        run mkdir -p "$(dirname "$BACKUP/$rel")"
        run cp -a "$dst" "$BACKUP/$rel"
    fi
    run mkdir -p "$(dirname "$dst")"
    if [[ -d "$src" ]]; then
        # --delete: a fresh Hyprland writes its own hyprland.conf, and left
        # next to hyprland.lua it would be read instead.
        run rsync -a --delete "${EXCLUDES[@]}" "$src/" "$dst/"
    else
        run rsync -a "$src" "$dst"
    fi
    note "~/.config/$rel"
done
[[ -d "$BACKUP" ]] && note "backups: $BACKUP"

# 4. fonts ------------------------------------------------------------------
say "Installing Google Sans Flex (SIL Open Font License)"
run mkdir -p "$HOME/.local/share/fonts/dynisle"
run cp "$REPO"/fonts/* "$HOME/.local/share/fonts/dynisle/"
run fc-cache -f

# 5. a first palette and lock screen ----------------------------------------
# Hyprland's config reads colours matugen generates, and the lock screen draws
# a pre-blurred image. Neither exists until a wallpaper is picked, so seed both.
say "Generating a first colour palette"
run mkdir -p "$HOME/.local/state/quickshell/user/generated/terminal" \
             "$HOME/.local/state/quickshell/user/generated/wallpaper" \
             "$HOME/.cache/dynisle"
if [[ -f "$HOME/.local/state/quickshell/user/generated/colors.json" ]]; then
    note "a palette already exists, left alone"
else
    run matugen color hex '#7fd4dd' -t scheme-fidelity
fi
if [[ ! -f "$HOME/.cache/dynisle/lock.png" ]]; then
    run magick -size 1920x1080 xc:'#121416' "$HOME/.cache/dynisle/lock.png"
fi
# The fastfetch black hole is drawn in the palette's colours, so it is made
# here rather than shipped; picking a wallpaper redraws it.
run python3 "$REPO/scripts/blackhole.py"
# Folders open in nautilus (from the browser's downloads, for example).
run xdg-mime default org.gnome.Nautilus.desktop inode/directory
# Links open in Chrome, the browser the keybinds open.
if [[ -f /usr/share/applications/google-chrome.desktop ]]; then
    run xdg-settings set default-web-browser google-chrome.desktop \
        || warn "could not make Chrome the default browser"
fi

# Each screen's scale, from its real size: hypr/monitors.lua belongs to one
# machine and is never copied, and without it Hyprland runs every screen at
# scale 1 - everything tiny on a sharper screen. fix.sh redoes this any time.
# It also writes hypr/hyprlock/scale.conf, since hyprlock ignores the scale;
# with monitors.lua already there, that one is still made from its scale.
say "Screen scale"
if ((DRY)); then
    python3 "$REPO/scripts/display-scale.py" --dry-run | sed -n '1,/^$/p'
else
    python3 "$REPO/scripts/display-scale.py" --if-missing \
        || warn "could not pick a screen scale - run ~/.config/quickshell/dynisle/fix.sh after logging in"
fi

# 5b. how windows look -------------------------------------------------------
# The blur and see-through windows are Hyprland's (hypr/custom/dynisle-blur.lua)
# plus kitty's own opacity, both copied above. This is what the apps read.
say "Dark theme, icons and cursor for GTK and Qt apps"
CURSOR=Bibata-Modern-Classic
# libadwaita apps (nautilus) take their style from links into adw-gtk3, the
# same links the original machine has.
run mkdir -p "$CONFIG/gtk-4.0"
for link in adw-gtk3-dark/gtk-4.0/gtk.css adw-gtk3-dark/gtk-4.0/gtk-dark.css \
            adw-gtk3-dark/gtk-4.0/assets adw-gtk3/gtk-4.0/libadwaita.css \
            adw-gtk3/gtk-4.0/libadwaita-tweaks.css; do
    src="/usr/share/themes/$link" dst="$CONFIG/gtk-4.0/${link##*/}"
    if [[ ! -e "$src" ]]; then
        continue
    fi
    if [[ -e "$dst" && ! -L "$dst" ]]; then
        run mkdir -p "$BACKUP/gtk-4.0"
        run mv "$dst" "$BACKUP/gtk-4.0/"
    fi
    run ln -sfn "$src" "$dst"
done
# GTK 4 and the portal read these from dconf, not from settings.ini
for kv in "color-scheme prefer-dark" "gtk-theme adw-gtk3-dark" "icon-theme Papirus" \
          "cursor-theme $CURSOR" "cursor-size 24" \
          "font-name Google Sans Flex Medium 11 @opsz=11,wght=500"; do
    run gsettings set org.gnome.desktop.interface "${kv%% *}" "${kv#* }" \
        || warn "gsettings could not set ${kv%% *} (no session bus yet?)"
done
# Qt apps: kdeglobals names breeze-plus-dark, which is AUR-only; without it,
# use the dark Breeze icons instead of KDE's light default.
if [[ -f "$CONFIG/kdeglobals" && ! -d /usr/share/icons/breeze-plus-dark ]]; then
    run sed -i 's/^Theme=breeze-plus-dark$/Theme=breeze-dark/' "$CONFIG/kdeglobals"
fi
# The cursor (Bibata, GPL-3.0) is not in Arch's official repositories, so it
# comes from its own GitHub release - the same files the original machine has.
if [[ -d "$HOME/.local/share/icons/$CURSOR" ]]; then
    note "cursor $CURSOR already installed"
elif ((DRY)); then
    note "[dry-run] download $CURSOR from github.com/ful1e5/Bibata_Cursor"
else
    mkdir -p "$HOME/.local/share/icons"
    if curl -fsSL "https://github.com/ful1e5/Bibata_Cursor/releases/latest/download/$CURSOR.tar.xz" \
        | tar -xJ -C "$HOME/.local/share/icons"; then
        note "cursor $CURSOR installed"
    else
        warn "could not download the $CURSOR cursor - the default one stays"
    fi
fi
# XWayland apps find the cursor through the "default" theme
run mkdir -p "$HOME/.local/share/icons/default"
if ((DRY)); then
    note "[dry-run] write ~/.local/share/icons/default/index.theme"
else
    printf '[Icon Theme]\nName=Default\nComment=Default Cursor Theme\nInherits=%s\n' "$CURSOR" \
        > "$HOME/.local/share/icons/default/index.theme"
fi

# 6. things that need root --------------------------------------------------
if ((SYSTEM)); then
    say "System files (sudo)"
    run sudo install -Dm755 "$REPO/system/dynisle-powerplan" /usr/local/bin/dynisle-powerplan
    run sudo install -Dm644 "$REPO/system/49-dynisle-powerplan.rules" /etc/polkit-1/rules.d/49-dynisle-powerplan.rules
    run sudo install -Dm755 "$REPO/system/wayland-session" /usr/local/bin/wayland-session
    note "power plans helper, its polkit rule, and the session launcher"

    # Only take over the login screen if there is not one already.
    if [[ -e /etc/systemd/system/display-manager.service ]]; then
        note "a display manager is already enabled - greetd left alone"
    else
        run sudo install -Dm644 "$REPO/system/greetd-config.toml" /etc/greetd/config.toml
        run sudo systemctl enable greetd.service
        note "greetd + tuigreet will be the login screen after a reboot"
    fi

    say "User services"
    # dynisle's Night light talks to hyprsunset, which nothing else starts.
    run systemctl --user enable hyprsunset.service
fi

say "Finished."
cat <<'EOF'

    Next:
      1. Reboot, and log in on the tuigreet screen.
      2. SUPER + A opens the wallpaper picker - add a folder of pictures and
         pick one; the colours follow it.
      3. Vietnamese typing: fcitx5 with Bamboo is set up; Super + Space toggles.

    Keys: SUPER + D launcher · SUPER + R control centre · SUPER + S session
          SUPER + A wallpaper · Shift + Print region shot · SUPER + Print full
          SUPER + E files (nautilus) · SUPER + W / SUPER + B Chrome
          Things too small or too big? ~/.config/quickshell/dynisle/fix.sh
          (update Chrome later: ~/.config/quickshell/dynisle/scripts/update-chrome)
          Every other Hyprland keybind is the
          same as on the machine this was copied from.
EOF
