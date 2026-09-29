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
    # terminals and the prompt
    kitty foot fish starship eza fastfetch
    # fonts (Google Sans Flex is not packaged; it ships in fonts/)
    ttf-jetbrains-mono-nerd ttf-material-symbols-variable
    # Vietnamese typing
    fcitx5 fcitx5-bamboo fcitx5-gtk fcitx5-qt fcitx5-configtool
    # keyring
    gnome-keyring
)

# Paths under ~/.config. Directories are mirrored, files are copied.
TRACKED=(
    hypr
    matugen
    kitty
    fastfetch/config.jsonc
    fastfetch/blackhole.txt
    foot/foot.ini
    fuzzel/fuzzel.ini
    fish/config.fish
    fish/auto-Hypr.fish
    fcitx5/profile
    fcitx5/config
    fcitx5/conf
    xdg-desktop-portal/hyprland-portals.conf
)

# Never carried between machines: backups, this machine's display layout, and
# files another program writes for itself. Excluded files are also never
# DELETED on the receiving side, so a machine keeps its own monitors.lua.
EXCLUDES=(
    --exclude='*.bak*' --exclude='*.old' --exclude='*.new'
    --exclude='_unused/' --exclude='monitors.*' --exclude='workspaces.*'
    --exclude='lumen.conf' --exclude='__restore_video_wallpaper.sh'
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
EOF
