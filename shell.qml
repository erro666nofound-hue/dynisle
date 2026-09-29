//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1

import Quickshell
import qs.modules.island
import qs.modules.wallpaper
import qs.services
import qs.modules.screenshot

ShellRoot {
    WallpaperLayer {
        // Whatever the picker last applied, and nothing when it has applied
        // nothing. There used to be a hardcoded fallback picture here; the file
        // was later deleted, so every start asked for a path that did not exist
        // and logged a warning - and it asked on EVERY start, because the
        // FileView loads asynchronously and this binding runs before it. The
        // layer paints `Theme.backdrop` underneath, so no picture reads as
        // empty rather than broken.
        wallpaper: Wallpapers.current.length > 0
            ? `file://${Wallpapers.current}` : ""
    }

    // BEFORE the island, deliberately: Hyprland stacks same-layer surfaces in
    // creation order, and the flying screenshot has to pass UNDERNEATH the
    // island at the end of its flight.
    ShotLayer {}

    Island {}
}
