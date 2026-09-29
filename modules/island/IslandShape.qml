import QtQuick
import Quickshell.Widgets
import qs.modules.common

// The island's visible body. It is sized BY its content: whatever is declared
// inside it is measured, padded, and the shape grows or shrinks to fit — that
// is the whole "dynamic" idea, and every future panel gets it for free just by
// having an implicit size.
//
// Blur-critical: `color` is the single place the fill alpha is set. It must
// stay above Hyprland's ignore_alpha floor (0.79) or the compositor stops
// blurring the island. See vault/notes.md fact 1.
ClippingRectangle {
    id: root

    // Children declared inside IslandShape land in the holder, not directly on
    // the Rectangle, so the Rectangle's own size can be derived from them.
    default property alias content: holder.data

    // Hover belongs to the shape, so it tracks the island's real visible bounds
    // rather than the window's (which is now much larger than the island).
    readonly property alias hovered: hoverHandler.hovered

    // Horizontal padding is overridable per panel. The workspace strip sets it
    // to 0 so its own cell padding IS the bar's padding - that way the focused
    // mark reaches the bar's edge on the end cells without being stretched, and
    // the number stays centred inside its mark.
    property real paddingH: Theme.islandPaddingH

    // The minimum width is overridable for the same reason. It exists so a tiny
    // panel still reads as a pill rather than a stub, but the workspace strip
    // is already made of full-height round cells - the floor only padded dead
    // bar onto its ends.
    property real minWidth: Theme.islandMinWidth

    // Content is measured, never stretched. Nothing inside may anchor to the
    // shape's width/height: the shape's size comes FROM the content, so
    // anchoring back to it would close a binding loop and freeze the layout.
    implicitWidth: Math.max(root.minWidth, holder.childrenRect.width + root.paddingH * 2)
    implicitHeight: Math.max(Theme.islandMinHeight, holder.childrenRect.height + Theme.islandPaddingV * 2)

    // These two bindings look redundant — an Item's width already follows its
    // implicitWidth — but they are load-bearing. That default is applied in C++
    // without ever creating a QML binding, so `Behavior on width` never sees the
    // change and the island teleports between sizes. Binding width explicitly
    // routes the change through QML, which is what the Behavior can intercept.
    // Verified: without these, polling the layer during a content change showed
    // only the two end widths and no intermediate frames.
    width: implicitWidth
    height: implicitHeight

    // Animating width/height (rather than letting them snap to implicit size)
    // is what makes the island *move* between states instead of teleporting.
    Behavior on width {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Theme.animEasing
        }
    }
    Behavior on height {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Theme.animEasing
        }
    }

    // A panel may ask for a rounder corner than the bar's; the greeting and the
    // leaving veil do, because in the middle of the screen the island reads as
    // a card rather than a strip.
    property real radiusHint: Theme.radius

    // Capped at half the height so the idle pill stays fully round, while a
    // tall expanded panel keeps a sane corner instead of turning into a stadium.
    radius: Math.min(root.radiusHint, height / 2)

    // Otherwise the corner POPS the instant a panel with its own radiusHint is
    // swapped away - one of the things that made the greeting's exit read as
    // three separate glitches rather than one movement.
    Behavior on radius {
        NumberAnimation {
            duration: 420
            easing.type: Easing.InOutCubic
        }
    }
    color: Theme.surface

    // A ClippingRectangle, not a Rectangle with `clip: true`. Qt's clip is
    // RECTANGULAR and ignores `radius`, so content could still paint into the
    // island's rounded corners - the workspace mark visibly poked out past the
    // bar's rounded end while the shape was still animating its width. This
    // clips to the actual rounded silhouette.

    Item {
        id: holder

        anchors.centerIn: parent
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    // A panel's countdown, drawn on the island's own bottom edge rather than
    // inside the content. It has to live here, declared in this file, because
    // anything a panel declares lands in `holder` and would be measured - a
    // full-island-width bar inside the content would inflate the island by two
    // paddings and then fight the width it just caused.
    //
    // Below zero means no countdown at all, which is what a critical
    // notification and every other panel use.
    property real drain: -1
    property color drainColor: Theme.accent

    Rectangle {
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, root.drain))
        height: 2
        visible: root.drain >= 0
        color: root.drainColor

        Behavior on color {
            ColorAnimation { duration: Theme.animDuration }
        }
    }

    // A HoverHandler, NOT a hoverEnabled MouseArea. A MouseArea here sits on
    // top of the content and consumes hover, so the transport buttons inside
    // the panel never saw the pointer and never highlighted. Input handlers
    // compose: this one and the buttons' own handlers are both active.
    HoverHandler {
        id: hoverHandler
    }
}
