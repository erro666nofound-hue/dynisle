hl.bind("CTRL+SUPER+ALT+Slash", hl.dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.lua"), {description = "Edit user keybinds"} )

-- Remap: Super+D opens/closes the launcher (was Maximize)
-- Also remove the old tap-Super-alone trigger for the same action, now superseded by Super+D
hl.unbind("SUPER + D")
hl.unbind("SUPER + SUPER_L")
hl.unbind("SUPER + SUPER_R")
-- REMOVED 2026-09-03: this bound SUPER + D to ii's `ipc call search toggle`,
-- a handler dynisle does not have. Hyprland runs EVERY binding on a key, so it
-- fired alongside the real one further down and spawned a process that failed
-- silently on every single launcher open.

-- Remap: Super+W toggles float/tile (was Browser)
hl.unbind("SUPER + W")
hl.bind("SUPER + W", hl.dsp.window.float({ action = "toggle" }), { description = "Window: Float/Tile" })

-- Remap: Super+B opens the browser (was duplicate left-sidebar toggle)
hl.unbind("SUPER + B")
hl.bind("SUPER + B", hl.dsp.exec_cmd(browser), { description = "App: Browser" })

-- Remove: Super+M did media controls popup, freed up for Lumen's own Super+M shortcut
hl.unbind("SUPER + M")

-- Remap: Shift+PrintScreen does the region screenshot (was: Print did a fullscreen shot)
-- Same action as the bar's screen-snip icon (UtilButtons.qml calls
-- `qs ipc call region screenshot`, which is what this global dispatch triggers).
hl.unbind("Print")
hl.bind("SHIFT + Print", hl.dsp.global("quickshell:regionScreenshot"), { description = "Utilities: Screen snip" })

-- New: Super+Shift+number moves the focused window to that workspace and switches to it
for i = 1, 10 do
    hl.bind("SUPER + SHIFT + " .. (i % 10), function()
        hl.dispatch(hl.dsp.window.move({ workspace = workspace_in_group(i), follow = true }))
    end, { description = "Window: Move to workspace " .. i .. " and follow" })
end

-- New: Super+M gọi Mini Lumen (chỗ trống do hl.unbind ở trên để lại).
-- Lệnh này KHÔNG mở app thứ hai — nó nói chuyện với bản đang chạy qua socket
-- (lumen/src/lumen/core/ipc.py), và chỉ mở app khi chưa có bản nào. Bấm lại là
-- ẩn; ẩn rồi Lumen vẫn chạy nền và nhạc vẫn phát.
hl.bind("SUPER + M", hl.dsp.exec_cmd("lumen --mini"), { description = "App: Mini Lumen" })

-- dynisle launcher (2026-09-02). This file is required after
-- hyprland.keybinds, so it OVERRIDES that file's SUPER + D, which was
-- fullscreen/maximize toggle. A compositor global shortcut, not `qs ipc call`:
-- ipc spawns a process per keypress.
hl.bind("SUPER + D", hl.dsp.global("quickshell:dynisleLauncher"),
    { description = "Shell: Toggle dynisle launcher" })

-- dynisle control centre (2026-09-02). SUPER + R was free: hyprland.keybinds
-- only uses R with CTRL+SUPER (restart shell), SUPER+SHIFT and SUPER+ALT
-- (screen recording), so nothing is displaced here.
hl.bind("SUPER + R", hl.dsp.global("quickshell:dynisleControl"),
    { description = "Shell: Toggle dynisle control centre" })

-- Full-screen shot straight to the clipboard (2026-09-02). SHIFT + Print above
-- is the region snip; this is the whole screen. Both are clipboard-only - no
-- folder is created and nothing is written to disk.
hl.unbind("SUPER + Print")
hl.bind("SUPER + Print", hl.dsp.global("quickshell:fullScreenshot"),
    { description = "Utilities: Full screenshot to clipboard" })

-- ---------------------------------------------------------------------------
-- Cleanup, 2026-09-02: dynisle is the shell now (custom/variables.lua sets
-- qsConfig). Everything below re-points what the old value used to reach.

-- end4-pC's screen recorder and wallpaper switcher are real, working scripts
-- and there is no dynisle replacement yet, so they are kept - but pinned to an
-- absolute path. They used to be reached through $qsConfig, which now says
-- "dynisle" and has no scripts folder at all.
local end4 = "$HOME/.config/quickshell/end4-pC/scripts"

hl.unbind("SUPER + SHIFT + R")
hl.unbind("SUPER + ALT + R")
hl.unbind("CTRL + ALT + R")
hl.unbind("SUPER + SHIFT + ALT + R")
hl.unbind("CTRL + SUPER + T")

hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd(end4 .. "/videos/record.sh"),
    { locked = true, description = "Record: region" })

hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd(end4 .. "/videos/record.sh --fullscreen"),
    { locked = true, description = "Record: full screen" })
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd(end4 .. "/videos/record.sh --fullscreen --sound"),
    { locked = true, description = "Record: full screen with sound" })
-- end4's switchwall.sh is unbound (2026-09-03). It changed the wallpaper and
-- regenerated colours BEHIND dynisle's back, so `config/wallpaper.json` and the
-- picture actually on screen drifted apart, and the lock screen's baked
-- background would never be regenerated for it. SUPER + A is the one way in.
hl.unbind("CTRL + SUPER + T")

-- Points at a welcome window that only exists in end4-pC's own shell, and that
-- shell no longer runs. Nothing to re-point it to.
hl.unbind("SHIFT + SUPER + ALT + Slash")

-- dynisle session panel (2026-09-03): lock, sleep, restart, shut down.
-- SUPER + S was briefly the theme picker and is free again.
hl.unbind("SUPER + S")
hl.bind("SUPER + S", hl.dsp.global("quickshell:dynisleSession"),
    { description = "Shell: Session" })

-- dynisle wallpaper picker (2026-09-02). SUPER + A was free.
hl.unbind("SUPER + A")
hl.bind("SUPER + A", hl.dsp.global("quickshell:dynisleWallpaper"),
    { description = "Shell: Wallpaper picker" })
