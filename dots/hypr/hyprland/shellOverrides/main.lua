-- Auto-managed by illogical-impulse (qs -c ii). Running ii rewrites the keys it
-- manages here and resets blur.size to 1 and active_opacity to 1 - it did so on
-- 2026-09-02. DO NOT put dynisle's blur/opacity values in this file: they live
-- in ~/.config/hypr/custom/dynisle-blur.lua, which hyprland.lua loads AFTER
-- this one so it wins even right after ii has clobbered these lines.
-- Original saved as main.lua.bak-*
hl.config({ decoration = { blur = { size = 1 } } })
hl.config({ decoration = { blur = { passes = 3 } } })
hl.config({ decoration = { blur = { popups = true } } })

-- Hyprland caches the blurred backdrop and reuses it instead of reblurring
-- every frame. When that cache goes stale a window silently loses its blur and
-- is left merely transparent - which is what the user was seeing ("blur ngon
-- ngay sau khi restart shell, rồi mất"): restarting dynisle recreated the
-- wallpaper layer, invalidating the cache and making blur correct again.
-- Turning the cache off costs GPU time but blur stays correct. Note this also
-- disables blur.xray, which only functions when new_optimizations is on.
hl.config({ decoration = { blur = { new_optimizations = false } } })
-- Frosted glass on windows = translucency AND blur, together.
-- Neither half works alone: opacity on its own is plain see-through (the look
-- vault/notes.md fact 1 rejects), and blur on its own is invisible because
-- Hyprland only blurs what sits behind translucent pixels. The reason this
-- used to look like cheap transparency was the global no_blur window rule in
-- rules.lua, which is now gone — so these values buy real blur, not see-through.
-- Tune here, not in dynisle: this is compositor-side, nothing to do with the
-- island's own fill alpha (that lives in Theme.qml and must stay > 0.79).
-- Measured, not guessed: at 0.92 only 8% of the backdrop showed through, and
-- blur over 8% of a soft wallpaper is imperceptible - which is exactly why the
-- windows looked "transparent but not blurred". 0.85 nearly doubles what the
-- blur has to work with while keeping text comfortably readable.
hl.config({ decoration = { active_opacity = 1 } })
hl.config({ decoration = { inactive_opacity = 0.9 } })

-- Games and video never get touched, whatever the values above are.
hl.config({ decoration = { fullscreen_opacity = 1.0 } })
hl.config({ general = { layout = "dwindle" } })
hl.config({ input = { kb_layout = "us" } })
hl.config({ input = { numlock_by_default = true } })
hl.config({ input = { repeat_delay = 250 } })
hl.config({ input = { repeat_rate = 35 } })
hl.config({ input = { follow_mouse = 1 } })
hl.config({ input = { touchpad = { natural_scroll = false } } })
hl.config({ input = { touchpad = { disable_while_typing = true } } })
hl.config({ input = { touchpad = { clickfinger_behavior = false } } })
hl.config({ input = { touchpad = { scroll_factor = 0.7 } } })
hl.config({ animations = { enabled = true } })
hl.config({ decoration = { shadow = { enabled = false } } })
hl.config({ decoration = { blur = { enabled = true } } })
hl.config({ general = { gaps_in = 2 } })
hl.config({ general = { gaps_out = 5 } })
hl.config({ general = { border_size = 1 } })
hl.config({ decoration = { rounding = 22 } })
hl.config({ general = { allow_tearing = 1 } })
