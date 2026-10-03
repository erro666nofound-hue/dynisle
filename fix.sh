#!/usr/bin/env bash
# Everything too small (or too big) on this screen? Run this.
#
#   ~/.config/quickshell/dynisle/fix.sh            pick each screen's scale from
#                                                  its real size (pixels per inch)
#   ~/.config/quickshell/dynisle/fix.sh 1.5        use this scale instead
#   ~/.config/quickshell/dynisle/fix.sh --dry-run  only show what it would do
#   ~/.config/quickshell/dynisle/fix.sh --lock     after changing the scale in
#                                                  Displays Settings: resize the lock screen to match
#
# Sizes in dynisle, kitty, Chrome, nautilus... are all logical pixels that
# Hyprland multiplies by the monitor's scale. This picks the scale that makes
# them the same physical size as on the 13.3" 1366x768 laptop dynisle was made
# on, at any resolution, writes it to ~/.config/hypr/monitors.lua and reloads
# Hyprland. The details are in scripts/display-scale.py.
set -euo pipefail
exec python3 "$(dirname "$(readlink -f "$0")")/scripts/display-scale.py" "$@"
