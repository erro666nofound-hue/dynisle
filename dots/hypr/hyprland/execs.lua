-- put former exec-once commands inside the func and former exec commands outside
hl.on("hyprland.start", function ()

    -- Bar, wallpaper
    hl.exec_cmd("$HOME/.config/hypr/hyprland/scripts/start_geoclue_agent.sh")
    hl.exec_cmd("qs -c $qsConfig")
    hl.exec_cmd("$HOME/.config/hypr/custom/scripts/__restore_video_wallpaper.sh")

    -- Core components (authentication, lock screen, notification daemon)
    hl.exec_cmd("gnome-keyring-daemon --start --components=secrets")
    hl.exec_cmd("hypridle")
    hl.exec_cmd("dbus-update-activation-environment --all")
    hl.exec_cmd("sleep 1 && dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP") -- Some fix idk

    -- Bring the sound server up at login instead of waiting for the first
    -- client to socket-activate it, so the sink exists before anything asks
    -- for it. These units are enabled either way; this only removes the lag.
    hl.exec_cmd("systemctl --user start pipewire.service pipewire-pulse.service wireplumber.service")

    -- Audio. EasyEffects is NOT started any more, and that is the fix.
    --
    -- It was inherited from the ii/end4 setup and never asked for. What it does
    -- on every boot: creates `easyeffects_sink`, TAKES THE DEFAULT SINK, and
    -- starts it at 0%. MEASURED - `pactl info` reports
    -- `Default Sink: easyeffects_sink`, and the control centre showed 0% on a
    -- device called "Easy Effects Sink" that would not turn up. Anything
    -- playing before its pipeline settles goes nowhere, which is the "phải chờ
    -- một lúc thì nhạc mới nghe được" on every single boot.
    --
    -- Reordering the startup did not help: the problem is not WHEN it starts,
    -- it is that it seizes the default output. Removing it leaves the real
    -- hardware sink as the default, where the volume sticks.
    --
    -- To bring it back: restore this line and set EasyEffects to not become
    -- the default output.
    -- hl.exec_cmd("easyeffects --hide-window --service-mode")

    -- Clipboard: history
    --hl.exec_cmd("wl-paste --watch cliphist store")
    -- `qs -c dynisle ipc call cliphistService update` was ii's handler and does
    -- not exist in dynisle, so every single copy spawned a process that failed
    -- silently. cliphist itself still stores; only the dead notify is gone.
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    -- Cursor
    hl.exec_cmd("hyprctl setcursor Bibata-Modern-Classic 24")
end)
