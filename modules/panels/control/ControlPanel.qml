import QtQuick
import qs.modules.common
import qs.modules.island
import qs.services

// The control centre. Designed on the web first and agreed there:
// https://claude.ai/code/artifact/9fe004f3-9728-4ddc-b072-727398f7a276
//
// Every layer lives inside this one bar - going into Wi-Fi or a device picker
// slides the bar's own contents sideways rather than opening a second surface,
// which is what the user asked for ("phần expand của wifi chính là cái thanh
// bar, không phải mở thêm cái gì đâu").
Item {
    id: root

    // The views set their own width, so the shape only adds vertical breathing
    // room - horizontal padding would double up on the rows' own insets.
    readonly property real islandPaddingH: 14
    readonly property real islandMinWidth: Theme.ccWidth + 28

    // Rescanning costs radio time, so it runs only while the control centre is
    // actually on screen - the home tile shows a live strength too, not just
    // the network list.
    Component.onCompleted: {
        Network.watching = true;
        SysInfo.watching = true;
        // Next turn, not this one: the panel and the surface's keyboard focus
        // flip together, so asking right away can happen before the window is
        // focusable at all - the trap the launcher hit (notes.md fact 30).
        Qt.callLater(() => root.forceActiveFocus());
    }

    Component.onDestruction: {
        Network.watching = false;
        SysInfo.watching = false;
    }

    implicitWidth: Theme.ccWidth
    // NO Behavior here on purpose. IslandShape already animates its own height
    // from this, and animating it here too meant two animations of different
    // durations chained together: the content settled at one size, then moved
    // again as the island caught up. One animation, in one place.
    implicitHeight: viewLoader.item?.implicitHeight ?? 0

    // Escape closes it. The panel holds the keyboard while it is open, so this
    // is the only thing that has to be listening.
    //
    // Focus is claimed on the next turn, not this one: the panel and the
    // surface's keyboard focus flip together, so asking for it right away can
    // happen before the window is focusable at all - the same trap the launcher
    // hit (vault/notes.md fact 30).
    focus: true
    Keys.onEscapePressed: IslandState.closeControl()


    Loader {
        id: viewLoader

        width: Theme.ccWidth

        sourceComponent: {
            switch (IslandState.controlView) {
            case "wifi":   return wifiView;
            case "warmth": return warmthView;
            case "join":   return joinView;
            case "output": return outputView;
            case "input":  return inputView;
            default:       return homeView;
            }
        }

        // A layer arriving comes in from the side it conceptually sits on:
        // deeper views enter from the right, backing out enters from the left.
        onSourceComponentChanged: viewSlide.restart()

        transform: Translate { id: viewShift }
    }

    // Declared out here on purpose: a Loader's default property is
    // sourceComponent, so an animation written inside one silently becomes the
    // thing it loads (vault/notes.md fact 16c).
    ParallelAnimation {
        id: viewSlide

        NumberAnimation {
            target: viewShift
            property: "x"
            from: IslandState.controlForward ? 26 : -26
            to: 0
            // The SAME duration IslandShape uses for its height. When the slide
            // outlasted the resize the content arrived, then kept drifting as
            // the island was still growing under it - which is the "moves
            // again" the user saw. One duration, one motion.
            duration: Theme.animDuration
            easing.type: Theme.animEasing
        }

        NumberAnimation {
            target: viewLoader
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.animDuration
        }
    }

    Component {
        id: homeView
        ControlHome {}
    }

    Component {
        id: wifiView
        ControlWifi {}
    }

    Component {
        id: warmthView
        ControlWarmth {}
    }

    Component {
        id: joinView
        ControlJoin {}
    }

    Component {
        id: outputView
        ControlDevices { kind: "output" }
    }

    Component {
        id: inputView
        ControlDevices { kind: "input" }
    }
}
