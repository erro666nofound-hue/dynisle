import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.modules.common

PanelWindow {
    id: root

    property string wallpaper

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    // Ignore, not just a zero zone: the wallpaper must cover the whole screen
    // including the strip the island reserves. With plain `exclusiveZone: 0`
    // this window still *honours* other surfaces' zones and gets shoved down
    // by the island's reservation, leaving a bare gap at the top.
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "quickshell:dynisle-wallpaper"

    // A wallpaper must never take pointer input. Without this, a fullscreen
    // background layer quietly swallows every click that lands on bare desktop.
    // Empty region = no input at all (end4-pC uses the same idiom in Idle.qml).
    mask: Region {
        item: null
    }

    color: Theme.backdrop

    // TWO images, crossfading. One Image with a bound source swaps the picture
    // on the frame it finishes decoding, which is a hard cut - and a hard cut is
    // exactly what the shell's own colours are now easing away from.
    //
    // `back` holds what is on screen; `front` loads the new one underneath at
    // zero opacity and fades up only once it is READY, so a slow decode never
    // shows a blank screen mid-fade.
    Image {
        id: back

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }

    Image {
        id: front

        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        opacity: 0

        onStatusChanged: {
            if (front.status === Image.Ready)
                fade.restart();
        }

        NumberAnimation {
            id: fade

            target: front
            property: "opacity"
            from: 0
            to: 1
            duration: Theme.recolourDuration
            easing.type: Easing.InOutQuad

            // Once it has fully arrived it becomes the one on screen, and the
            // front layer is freed for the next change.
            onFinished: {
                back.source = front.source;
                front.opacity = 0;
                front.source = "";
            }
        }
    }

    // The binding already has a value when this object is built, so
    // onWallpaperChanged may never fire for the FIRST picture - and then
    // nothing would ever be shown at all.
    Component.onCompleted: back.source = root.wallpaper

    // Clearing needs its own animation, because there is nothing to fade IN.
    NumberAnimation {
        id: clear

        target: back
        property: "opacity"
        from: 1
        to: 0
        duration: Theme.recolourDuration
        easing.type: Easing.InOutQuad

        onFinished: {
            back.source = "";
            front.source = "";
            back.opacity = 1;
        }
    }

    onWallpaperChanged: {
        // CLEARED, not changed. An empty source never reaches Image.Ready, so
        // handing it to `front` meant `fade` never started, `onFinished` never
        // ran, and the old picture stayed on screen forever - which is why
        // "No wallpaper" appeared to do nothing at all.
        if (root.wallpaper.length === 0) {
            if (back.source != "")
                clear.restart();
            return;
        }

        // A picture arriving mid-clear must cancel it, or it would fade in over
        // a half-faded backdrop and then be wiped by onFinished.
        clear.stop();
        back.opacity = 1;

        if (back.source == "") {
            // First picture of the session: nothing to fade from.
            back.source = root.wallpaper;
            return;
        }

        front.source = root.wallpaper;
    }
}
