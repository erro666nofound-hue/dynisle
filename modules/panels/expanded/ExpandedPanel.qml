import QtQuick
import Quickshell.Widgets
import qs.modules.common
import qs.services

// The hovered state of the island, rebuilt to the user's own sketch:
//
//   [ ART ] [ track name        ] [ time          ]
//   [     ] [ transport buttons ] [ week strip    ]
//
// The cava visualiser is the album art's BORDER - 56 bars growing outward from
// its four edges - rather than a separate block. All bars have fully rounded
// caps.
//
// Like every panel, this states its own size and never anchors to the island;
// the island measures it and grows to fit (vault/notes.md fact 16).
Item {
    id: root

    // The art plus the cava border that surrounds it.
    readonly property real artCell: Theme.artSize + 2 * (Theme.cavaRingGap + Theme.cavaBarMax)
    readonly property real artOrigin: Theme.cavaRingGap + Theme.cavaBarMax

    // Length once around the artwork's rounded rectangle: four straight runs
    // plus four quarter-circle corners.
    readonly property real perimeter: 2 * (Theme.artSize - 2 * Theme.artRadius)
        + 2 * (Theme.artSize - 2 * Theme.artRadius)
        + 2 * Math.PI * Theme.artRadius

    // Walk `s` along that perimeter and return [x, y, nx, ny] - the point and
    // its outward unit normal. Used to seat each cava bar on the border.
    function borderSeat(s: real): var {
        const R = Theme.artRadius;
        const W = Theme.artSize;
        const o = root.artOrigin;
        const run = W - 2 * R;
        const arc = Math.PI * R / 2;
        let t = s;

        if (t < run)  return [o + R + t, o, 0, -1];                       // top
        t -= run;
        if (t < arc) { const a = t / R;                                    // top-right
            return [o + W - R + R * Math.sin(a), o + R - R * Math.cos(a), Math.sin(a), -Math.cos(a)]; }
        t -= arc;
        if (t < run)  return [o + W, o + R + t, 1, 0];                    // right
        t -= run;
        if (t < arc) { const a = t / R;                                    // bottom-right
            return [o + W - R + R * Math.cos(a), o + W - R + R * Math.sin(a), Math.cos(a), Math.sin(a)]; }
        t -= arc;
        if (t < run)  return [o + W - R - t, o + W, 0, 1];                // bottom
        t -= run;
        if (t < arc) { const a = t / R;                                    // bottom-left
            return [o + R - R * Math.sin(a), o + W - R + R * Math.cos(a), -Math.sin(a), Math.cos(a)]; }
        t -= arc;
        if (t < run)  return [o, o + W - R - t, -1, 0];                   // left
        t -= run;
        const a = t / R;                                                   // top-left
        return [o + R - R * Math.cos(a), o + R - R * Math.sin(a), -Math.cos(a), -Math.sin(a)];
    }

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    Row {
        id: layout

        spacing: Theme.panelGroupGap

        // ---- Album art, wrapped in the cava border ------------------------
        Item {
            id: artCell

            implicitWidth: root.artCell
            implicitHeight: root.artCell

            ClippingRectangle {
                id: art

                x: root.artOrigin
                y: root.artOrigin
                width: Theme.artSize
                height: Theme.artSize
                radius: Theme.artRadius
                // Stands in until the artwork loads, or for a track with none.
                color: Theme.skeleton

                Image {
                    anchors.fill: parent
                    source: Media.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            // The border itself: bars spaced evenly along the artwork's rounded
            // rectangle, corners INCLUDED, each rotated to point straight out.
            // (An earlier version split the perimeter into four straight sides
            // and left the corners bare, which is not a border.)
            Repeater {
                model: Cava.barCount

                Rectangle {
                    id: bar

                    required property int index

                    readonly property var seat: root.borderSeat(
                        (bar.index + 0.5) / Cava.barCount * root.perimeter)
                    readonly property real level: Cava.values[bar.index] ?? 0
                    readonly property real len: Theme.cavaBarMin
                        + bar.level * (Theme.cavaBarMax - Theme.cavaBarMin)

                    width: Theme.cavaBarThickness
                    height: bar.len

                    // Pushed out along the outward normal, then rotated so its
                    // long axis lies on that normal. A rect at rotation 0 grows
                    // downward, which is the normal of the bottom edge, hence
                    // the -90 offset.
                    x: bar.seat[0] + bar.seat[2] * (Theme.cavaRingGap + bar.len / 2) - width / 2
                    y: bar.seat[1] + bar.seat[3] * (Theme.cavaRingGap + bar.len / 2) - height / 2
                    rotation: Math.atan2(bar.seat[3], bar.seat[2]) * 180 / Math.PI - 90

                    // Fully rounded caps, as asked.
                    radius: Theme.cavaBarThickness / 2
                    color: Theme.accent
                    opacity: 0.5 + 0.5 * bar.level
                }
            }
        }

        // ---- Track name + transport ---------------------------------------
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.panelStackGap

            Column {
                spacing: 3

                // Elided at a fixed width so a long track title can never widen
                // the island on a song change.
                Text {
                    width: Theme.trackTextWidth
                    elide: Text.ElideRight
                    text: Media.hasPlayer ? Media.title : "Nothing playing"
                    color: Media.hasPlayer ? Theme.text : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontTitle
                    font.weight: Font.Medium
                }

                Text {
                    width: Theme.trackTextWidth
                    elide: Text.ElideRight
                    visible: Media.hasPlayer
                    text: Media.artist
                    color: Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.panelFontBody
                }
            }

            Row {
                spacing: Theme.transportSpacing
                visible: Media.hasPlayer

                TransportButton {
                    glyph: "\uf048"
                    usable: Media.canGoPrevious
                    onActivated: Media.previous()
                }

                TransportButton {
                    // Shows what pressing it will do: a pause bar while
                    // playing, a play triangle while paused.
                    glyph: Media.isPlaying ? "\uf04c" : "\uf04b"
                    usable: Media.canToggle
                    onActivated: Media.togglePlaying()
                }

                TransportButton {
                    glyph: "\uf051"
                    usable: Media.canGoNext
                    onActivated: Media.next()
                }
            }
        }

        // ---- Separator between the two halves ------------------------------
        // A hairline with air either side, so the media group and the
        // time/calendar group read as two things rather than one crowded row.
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 1
            height: root.artCell * 0.62
            color: Theme.divider
        }

        // ---- Time + week strip ---------------------------------------------
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.panelStackGap

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: DateTime.time
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: Theme.panelFontTime
                font.weight: Font.Medium
            }

            Row {
                spacing: Theme.dayCellSpacing

                Repeater {
                    // Seven days centred on today, matching reference
                    // screenshot 02 - a rolling window, not a calendar month.
                    model: 7

                    Item {
                        id: day

                        required property int index

                        readonly property date date: {
                            const d = new Date(DateTime.now);
                            d.setDate(d.getDate() + day.index - 3);
                            return d;
                        }
                        readonly property bool isToday: day.index === 3
                        readonly property bool isWeekend: day.date.getDay() === 0 || day.date.getDay() === 6

                        // The strip fades out toward both ends, as in reference
                        // screenshot 02 - the outermost pair is nearly gone,
                        // which frames today without needing a hard edge.
                        opacity: 1 - Math.pow(Math.abs(day.index - 3) / 3, 2.2) * 0.85

                        width: Theme.dayCellWidth
                        height: Theme.dayCellHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            visible: day.isToday
                            color: Theme.accent
                            opacity: 0.18
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                // Today spells its day out; the rest are a
                                // single letter. That contrast is what makes
                                // today read as today in the reference, more
                                // than the highlight behind it does.
                                text: {
                                    const name = Qt.formatDateTime(day.date, "ddd").toUpperCase();
                                    return day.isToday ? name : name.charAt(0);
                                }
                                color: day.isToday ? Theme.accent : (day.isWeekend ? Theme.weekend : Theme.textDim)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelFontSmall
                                font.weight: day.isToday ? Font.Medium : Font.Normal
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: day.date.getDate()
                                color: day.isToday ? Theme.accent : (day.isWeekend ? Theme.weekend : Theme.text)
                                font.family: Theme.fontFamily
                                font.pixelSize: Theme.panelFontBody
                                font.weight: day.isToday ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }

    // A transport control.
    //
    // `usable`, not `enabled`: `enabled` is an existing Item property and
    // shadowing it breaks input handling.
    //
    // Input HANDLERS, not a MouseArea: the island's own hover lives on
    // IslandShape, and a nested hoverEnabled MouseArea would swallow that
    // hover, so the island could not tell it was still being hovered.
    // Handlers compose instead of competing.
    component TransportButton: Item {
        id: button

        required property string glyph
        property bool usable: true
        signal activated

        implicitWidth: Theme.transportHitSize
        implicitHeight: Theme.transportHitSize

        // The glyph is a SIBLING of the hover pad, never its child. Opacity in
        // QML multiplies down into children, so a glyph placed inside a pad
        // that fades to 0 vanishes with it - which is exactly why these buttons
        // rendered as nothing at all, with no error to show for it.
        Item {
            id: content

            anchors.fill: parent
            scale: tap.pressed ? Theme.pressScale : 1

            Behavior on scale {
                NumberAnimation {
                    duration: Theme.pressDuration
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: Theme.text
                opacity: hover.hovered && button.usable ? 0.12 : 0

                Behavior on opacity {
                    NumberAnimation { duration: Theme.pressDuration }
                }
            }

            Text {
                anchors.centerIn: parent
                text: button.glyph
                color: button.usable ? (hover.hovered ? Theme.text : Theme.textDim) : Theme.textDisabled
                font.family: Theme.fontMono
                font.pixelSize: Theme.transportGlyphSize
            }
        }

        HoverHandler {
            id: hover
            enabled: button.usable
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            id: tap
            enabled: button.usable
            onTapped: button.activated()
        }
    }
}
