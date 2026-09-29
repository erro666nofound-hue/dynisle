

-- XDG_DATA_DIRS, pinned to a fixed value. Do NOT read the old value here.
-- hyprland/env.lua does `hl.env("XDG_DATA_DIRS", <4 dirs> .. os.getenv("XDG_DATA_DIRS"))`,
-- which appends a fresh copy of itself on EVERY `hyprctl reload`. It had grown
-- to 27 copies (108 entries), and every GTK/GIO app rescans each entry for
-- icons, mime types and desktop files - that was the ~14s nautilus startup
-- delay. This file is required after hyprland.env, so this value wins, and it
-- is idempotent no matter how many times the config is reloaded.
local dynisle_home = os.getenv("HOME") or "/home/toast"
hl.env("XDG_DATA_DIRS", dynisle_home .. "/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:/usr/local/share:/usr/share")
