pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Alpha must stay above Hyprland's ignore_alpha floor (0.79) or the
    // compositor stops blurring the island entirely. Working band 0.85-0.90.
    readonly property real surfaceAlpha: 0.88

    // Slow enough to read as a change of mood, short enough not to feel broken.
    readonly property int recolourDuration: 550

    // ---- colours generated from the wallpaper ------------------------------
    // matugen is already installed and configured on this machine; it writes a
    // full Material palette here every time a wallpaper is applied, along with
    // GTK, hyprlock and fuzzel. So the shell reads ONE file and the whole
    // desktop stays in step.
    //
    // Only these four are read. Everything else in this file is derived from
    // them, which is exactly why UT-02 put every colour in one place.
    property var palette: ({})

    FileView {
        path: `${Quickshell.env("HOME")}/.local/state/quickshell/user/generated/colors.json`
        watchChanges: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            try {
                root.palette = JSON.parse(text());
            } catch (e) {
                // A half-written file is normal while matugen runs; keep the
                // last good palette rather than flashing to the fallbacks.
            }
        }
    }

    // The fallbacks are not decoration: matugen has not run yet on a fresh
    // config, and a shell with no colours at all looks broken.
    // NOT readonly, and each carries a Behavior: a Behavior intercepts writes,
    // including the ones a binding makes, so when matugen hands over a new
    // palette these four EASE across instead of snapping. Every other colour in
    // this file is derived from them, so the whole shell fades as one.
    property color surfaceTint: root.palette.background ?? "#1a1a1a"

    Behavior on surfaceTint {
        ColorAnimation {
            duration: Theme.recolourDuration
            easing.type: Easing.OutCubic
        }
    }
    readonly property color surface: Qt.rgba(surfaceTint.r, surfaceTint.g, surfaceTint.b, surfaceAlpha)
    readonly property color backdrop: "black"

    property color text: root.palette.on_background ?? "#ececec"
    property color textDim: root.palette.outline ?? "#9aa0a6"
    // Set while the colour picker's handle is being dragged, so the island
    // recolours live without running matugen on every frame. matugen is invoked
    // once, on commit. Transparent means "not previewing".
    // Live preview while the hue rail is dragged. matugen is far too slow to
    // run per frame, so the island wears the candidate colour directly and
    // matugen is invoked once, on commit. Transparent means "not previewing".
    property color previewAccent: "transparent"

    property color accent: root.previewAccent.a > 0
        ? root.previewAccent
        : (root.palette.primary ?? "#7fd4dd")

    Behavior on text {
        ColorAnimation { duration: Theme.recolourDuration; easing.type: Easing.OutCubic }
    }
    Behavior on textDim {
        ColorAnimation { duration: Theme.recolourDuration; easing.type: Easing.OutCubic }
    }
    Behavior on accent {
        ColorAnimation { duration: Theme.recolourDuration; easing.type: Easing.OutCubic }
    }

    readonly property real radius: 20

    // The one spacing value that frames the island: the gap above it (to the
    // screen edge) and the gap below it (to the first tiled window) are both
    // this. Was 10, now 2/3 of that.
    readonly property real screenGap: 7

    // Hyprland inserts its own `general:gaps_out` between the reserved zone and
    // the first tiled window. The island must reserve that much LESS, otherwise
    // the compositor's gap stacks on top of ours and the space below the island
    // ends up wider than the space above it. Keep in sync with gaps_out in
    // ~/.config/hypr/hyprland/shellOverrides/main.lua.
    readonly property real compositorGapsOut: 5

    // The island is sized BY ITS CONTENT, not by fixed dimensions. These are
    // the padding the content sits in, plus a floor so a very small panel
    // still reads as a pill rather than a stub.
    readonly property real islandPaddingH: 20
    readonly property real islandPaddingV: 8
    readonly property real islandMinWidth: 96

    // The reserved zone and the equal 7px gaps are both derived from this, so
    // it is the ONE height that must not follow the content — otherwise every
    // expansion would shove the user's windows down the screen.
    readonly property real islandMinHeight: 40

    // The island's WINDOW is this size and never changes; only the shape inside
    // it animates. Resizing a layer-shell surface makes the compositor
    // reallocate and re-commit the surface on every animation frame, which is
    // visibly janky — the window is therefore made big enough for the largest
    // panel once, and a mask keeps the transparent remainder click-through.
    // Raise these if a future panel outgrows them.
    readonly property real islandMaxWidth: 900
    readonly property real islandMaxHeight: 480

    readonly property real spacing: 8

    // Expanded panel. The content width is fixed rather than hugging the text:
    // a track title changes every song, and a panel that resized on every song
    // change would be twitchy. The island still hugs *this* width.
    readonly property real panelContentWidth: 360
    readonly property real rowGap: 8

    // ONE knob for the whole expanded panel. The user asked for 75% of the
    // first build; every panel dimension below is derived from it, so a future
    // "make it a bit smaller/bigger" is a single number, not a sweep.
    readonly property real panelScale: 0.75

    // Album art. Base 176 = 4x the original 44, at the user's request.
    readonly property real artSize: Math.round(176 * panelScale)
    readonly property real artRadius: Math.round(16 * panelScale)

    // The cava visualiser is the album art's BORDER: 56 bars seated around its
    // rounded rectangle, corners included, with fully rounded caps.
    readonly property real cavaBarThickness: Math.max(3, Math.round(4 * panelScale))
    readonly property real cavaBarMin: Math.max(2, Math.round(3 * panelScale))
    readonly property real cavaBarMax: Math.round(16 * panelScale)
    readonly property real cavaRingGap: Math.round(6 * panelScale)

    // Transport controls, sized so the panel is not mostly gap.
    readonly property real transportGlyphSize: Math.round(26 * panelScale)
    readonly property real transportHitSize: Math.round(40 * panelScale)
    readonly property real transportSpacing: Math.round(14 * panelScale)

    // Panel layout spacings and the fixed width the track text elides at.
    readonly property real panelColumnGap: Math.round(30 * panelScale)
    readonly property real panelStackGap: Math.round(14 * panelScale)
    readonly property real trackTextWidth: Math.round(250 * panelScale)

    // The media half and the time/calendar half are separated by a hairline
    // with generous air either side, per the user's sketch.
    readonly property real panelGroupGap: Math.round(26 * panelScale)

    // Panel type scale, kept separate from the generic tokens so shrinking the
    // panel never touches the idle pill's clock.
    readonly property real panelFontTitle: Math.round(18 * panelScale)
    readonly property real panelFontTime: Math.round(44 * panelScale)
    readonly property real panelFontBody: Math.round(13 * panelScale)
    readonly property real panelFontSmall: Math.round(11 * panelScale)

    // Disabled controls must still be legible - at skeleton (10% white) they
    // vanished completely against the panel.
    readonly property color textDisabled: Qt.rgba(1, 1, 1, 0.28)

    // Press feedback on buttons.
    readonly property real pressScale: 0.86
    readonly property int pressDuration: 90

    // Week strip: 7 days centred on today.
    readonly property real dayCellWidth: Math.round(32 * panelScale)
    readonly property real dayCellHeight: Math.round(46 * panelScale)
    readonly property real dayCellSpacing: Math.max(2, Math.round(3 * panelScale))
    readonly property color weekend: "#e88a9a"

    // Workspace flash strip. Sized near the idle pill's height so the island
    // barely changes shape when it flashes.
    readonly property real wsCellSize: 24
    readonly property real wsFontSize: 15
    // One uniform padding around every workspace number. It doubles as the
    // bar's own horizontal padding (the strip sets the island's to 0), which is
    // what makes the focused mark meet the bar's edge on the end cells while
    // the number stays centred inside it.
    // The bar's height inside this panel: the digits' line box plus the
    // island's vertical padding either side. Everything else derives from it,
    // so changing the bar's height cannot desynchronise the strip.
    readonly property real wsBarHeight: root.wsCellSize + root.islandPaddingV * 2

    // The mark is inset from the bar rather than spanning its full height -
    // touching both edges made it read as jammed in. The same inset is applied
    // horizontally, so the margin is even on all four sides.
    readonly property real wsMarkScale: 0.9
    readonly property real wsMarkSize: Math.round(root.wsBarHeight * root.wsMarkScale)
    readonly property real wsMarkInset: (root.wsBarHeight - root.wsMarkSize) / 2

    // How airy the strip is. Spacing comes from cell width, never from a Row
    // `spacing` - that would break the end cells' contact with the bar's edge.
    // The focused cell is twice as wide as the rest, so the strip is tight
    // everywhere except around the mark. At scale 1 the focused cell is square
    // and the mark is a circle, which read as too thin; 1.5 makes it a
    // shortened bar again.
    readonly property real wsSpacingScale: 1.5
    readonly property real wsActiveCellWidth: Math.round(root.wsBarHeight * root.wsSpacingScale)
    readonly property real wsIdleCellWidth: Math.round(root.wsBarHeight * 0.5 * root.wsSpacingScale)

    // Launcher. The search field IS the island; the results are a second
    // surface drawn below it, separated by launcherGap - two surfaces, as in
    // the reference, still inside the one PanelWindow.
    readonly property real launcherWidth: 470
    readonly property real launcherGap: 10
    readonly property real launcherLensSize: 38
    readonly property real launcherToolSize: 30
    readonly property real launcherFieldHeight: 40
    readonly property real launcherFontSize: 16

    readonly property real launcherRowHeight: 46
    readonly property real launcherRowRadius: 14
    readonly property real launcherPanelRadius: 22
    readonly property real launcherPanelPad: 8

    // The results panel is capped and scrolls past this. Without a cap it grew
    // straight past the bottom of the (fixed 480px) island window and the
    // compositor sliced it off - the rounded bottom corners turned into a flat
    // cut, which is exactly what a long search for "a" looked like.
    readonly property real launcherMaxListHeight: 322

    // Pinned apps wrap onto more rows and then scroll. Three rows is as tall as
    // the panel gets before that happens.
    readonly property real launcherPinSpacing: 6

    // How many pinned tiles fit across the panel. Shared, because the keyboard
    // needs it to jump a whole row and the layout needs it to wrap.
    readonly property int launcherPerRow: Math.max(1, Math.floor(
        (launcherWidth - launcherPanelPad * 2 + launcherPinSpacing)
        / (launcherPinSize + launcherPinSpacing)))
    readonly property real launcherMaxPinHeight: 3 * (launcherPinSize + launcherPinSpacing)
        - launcherPinSpacing
    readonly property real launcherIconSize: 26
    readonly property real launcherNameSize: 14
    readonly property real launcherKindSize: 10

    readonly property real launcherPinSize: 56
    readonly property real launcherPinIcon: 32
    readonly property real launcherPinRadius: 16
    readonly property real launcherPinButtonSize: 24
    readonly property real launcherBadgeSize: 16

    readonly property color accentFill: Qt.rgba(accent.r, accent.g, accent.b, 0.16)
    readonly property color accentStrong: Qt.rgba(accent.r, accent.g, accent.b, 0.22)

    // Notification popup.
    readonly property real notifWidth: 380
    readonly property real notifWidthWide: 420
    // The media block on the left. Square at this size when the row is short,
    // and it stretches to the row's height when the text makes the row taller -
    // that is the whole point, an icon must never leave a gap under itself.
    readonly property real notifBlockSize: 44
    readonly property real notifBlockRadius: 13
    readonly property real notifGap: 12

    // A guessed Material Symbol is drawn at the larger size; a real app icon
    // resolved from the theme is drawn smaller, centred, because a symbolic
    // icon blown up to fill a tall block looks wrong.
    readonly property real notifGlyphSize: 24
    readonly property real notifAppIconSize: 26
    readonly property real notifStampSize: 11
    readonly property int notifLifetime: 3000
    // Low urgency is background chatter and gets less of the screen's time.
    readonly property int notifLifetimeLow: 2000
    readonly property color urgent: "#e88a9a"
    readonly property color warning: "#e8c08a"

    // The two session actions that lose unsaved work. Taken from matugen's own
    // error role, so it follows the wallpaper like everything else rather than
    // being the one hardcoded colour in the shell.
    property color danger: root.palette.error ?? "#ffb4ab"

    Behavior on danger {
        ColorAnimation { duration: Theme.recolourDuration; easing.type: Easing.OutCubic }
    }

    readonly property color dangerFill: Qt.rgba(danger.r, danger.g, danger.b, 0.15)
    readonly property real notifAppSize: 12
    readonly property real notifSummarySize: 15
    readonly property real notifBodySize: 13

    // Control centre.
    readonly property real ccWidth: 470
    readonly property real ccRowHeight: 40
    readonly property real ccKnobSize: 14
    readonly property real ccTrackHeight: 6
    readonly property real ccRoundSize: 28
    // One tile height for every tile in the grid: shape carries meaning here,
    // so two different tile sizes would say something that is not true.
    // 78, not 66: a narrow tile stacks a 20px glyph over two lines of text, and
    // at 66 the label climbed onto the icon.
    readonly property real ccTileHeight: 78
    readonly property real ccTileRadius: 18

    // Four columns. Everything else in the grid is derived, so a tile spanning
    // two columns lines up exactly with two tiles plus the gap between them.
    readonly property int ccColumns: 4
    readonly property real ccColWidth: (ccWidth - ccGap * (ccColumns - 1)) / ccColumns

    function ccSpan(n: int): real {
        return n * ccColWidth + (n - 1) * ccGap;
    }

    // Wallpaper picker. Six across, as agreed on the design page.
    readonly property real wallWidth: 780
    readonly property int wallColumns: 6
    // ZERO, and that is not a mistake. The visible gap between two pictures is
    // this plus twice `wallPad`, because each picture is inset inside its own
    // cell. At 10 that came to 20px of air, which read as too loose; the cells
    // now sit flush and the 5px inset on each side gives the 10px the user
    // asked for - without changing how far a picture sits from its own edge.
    readonly property real wallGap: 0
    readonly property real wallRadius: 14
    // The picture is INSET inside its cell. The selection outline is drawn on
    // the cell itself, so it lives in this gap rather than on the picture - and
    // the tick has somewhere to sit that is not on top of the image.
    readonly property real wallPad: 5

    // A folder card: an icon row with the remove button, then the name. The
    // mark and the remove button used to overlap in a card too small for both.
    readonly property real folderCardHeight: 22 + 5 + 18 + (wallPad + 6) * 2

    // The session panel: four tiles wide, and that is the whole panel.
    readonly property real sessionTile: 116
    readonly property real sessionGap: 8
    readonly property real sessionWidth: sessionTile * 4 + sessionGap * 3

    readonly property real wallCell: (wallWidth - wallGap * (wallColumns - 1)) / wallColumns
    // 16:10, which is close enough to every wallpaper to crop cleanly.
    readonly property real wallCellHeight: wallCell / 1.6
    // TWO rows, then it scrolls - and no fade at the cut, by request.
    readonly property real wallMaxHeight: 2 * (wallCellHeight + wallGap) - wallGap

    // The vitals strip: CPU, memory, temperature.
    readonly property real ccVitalHeight: 46
    readonly property real ccVitalRadius: 16

    // Temperature is drawn against a range it actually moves in. Against
    // 0-100 the bar would sit near the middle and never visibly change.
    readonly property real ccTempMin: 30
    readonly property real ccTempMax: 90
    readonly property real ccTempWarm: 70
    readonly property real ccTempHot: 85

    // Now playing.
    readonly property real ccArtSize: 52
    readonly property real ccArtRadius: 14
    readonly property real ccTransportSize: 30
    readonly property real ccTransportMain: 34
    readonly property int ccWaveBars: 20
    readonly property real ccWaveHeight: 14
    readonly property real ccGap: 8
    readonly property real ccDeviceSize: 11
    readonly property real ccValueSize: 13
    readonly property real ccListRowHeight: 42
    readonly property real ccListRadius: 12
    readonly property real ccGroupSize: 10

    readonly property color track: Qt.rgba(1, 1, 1, 0.11)

    readonly property color divider: Qt.rgba(1, 1, 1, 0.12)
    readonly property color skeleton: Qt.rgba(1, 1, 1, 0.10)

    // How the island grows and shrinks between content sizes.
    readonly property int animDuration: 150
    readonly property int animEasing: Easing.OutCubic

    // Content is swapped instantly by the Loader, so it fades in while the
    // shape is still growing — without this the new panel appears at full size
    // inside a pill that has not finished expanding.
    readonly property int contentFadeDuration: 150

    readonly property string fontFamily: "Google Sans Flex"
    readonly property string fontMono: "JetBrainsMono Nerd Font"

    // Line-art icons: outline only, one plane, one stroke weight. The FILL axis
    // is what does it - see Icon.qml, which sets it. Installed as
    // ttf-material-symbols-variable.
    readonly property string fontIcon: "Material Symbols Rounded"

    // 16, not 13. Measured off reference screenshot 01: the clock's digits are
    // 7px tall in a 25px pill — a ratio of 0.28. On our 40px pill that is ~11px
    // of digit height, which "Google Sans Flex" hits at pixelSize 16.
    readonly property real fontSize: 16
    readonly property real fontSizeTitle: 18
    readonly property real fontSizeTime: 30
    readonly property real fontSizeBody: 13
    readonly property real fontSizeSmall: 11
}
