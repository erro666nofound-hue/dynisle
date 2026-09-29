-- The folder within ~/.config/quickshell containing the config.
--
-- This one line is what makes dynisle the shell of this machine. It is read by
-- hyprland/execs.lua ("qs -c $qsConfig" on start) and by CTRL+SUPER+R, so
-- until it was changed Hyprland was still AUTOSTARTING end4-pC on every login -
-- which would have taken the notification bus away from dynisle.
--
-- Anything that used $qsConfig to reach end4-pC's own scripts has been pinned
-- to an absolute path in custom/keybinds.lua, so those keep working.
hl.env("qsConfig", "dynisle")

-- File manager: nautilus instead of dolphin (user request, 2026-09-02).
-- Overrides hyprland/variables.lua, which keybinds.lua loads before this file.
fileManager = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'nautilus' 'nemo' 'thunar' 'kitty -1 fish -c yazi'"

-- Terminal: kitty instead of foot (user request, 2026-09-02).
-- The default list put 'foot' first, so SUPER+Return had been opening foot all
-- along - which is why foot and kitty appeared to blur differently.
terminal = "~/.config/hypr/hyprland/scripts/launch_first_available.sh 'kitty -1' 'foot' 'alacritty' 'wezterm' 'konsole' 'kgx' 'uxterm' 'xterm'"
