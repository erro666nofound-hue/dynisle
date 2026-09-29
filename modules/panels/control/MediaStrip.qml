import QtQuick
import Quickshell.Widgets
import qs.modules.common
import qs.services

// Now playing, at the top of the control centre. This is what the panel was
// missing: `services/Media.qml` has been finished and unused since UT-07.
//
// The whole strip disappears when nothing is playing - the island is supposed
// to fit its content, so an empty band would be the wrong answer.
Item {
    id: root

    implicitWidth: Theme.ccWidth
    implicitHeight: Theme.ccArtSize

    ClippingRectangle {
        id: art

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.ccArtSize
        height: Theme.ccArtSize
        radius: Theme.ccArtRadius
        color: Theme.skeleton

        Image {
            anchors.fill: parent
            visible: Media.artUrl.length > 0
            source: Media.artUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: Theme.ccArtSize * 2
            sourceSize.height: Theme.ccArtSize * 2
        }

        // Nothing supplied: a note rather than an empty square.
        Icon {
            anchors.centerIn: parent
            visible: Media.artUrl.length === 0
            size: 22
            text: "music_note"
        }
    }

    Item {
        anchors.left: art.right
        anchors.leftMargin: 12
        anchors.right: transport.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: title.implicitHeight + by.implicitHeight + Theme.ccWaveHeight + 6

        Text {
            id: title

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            elide: Text.ElideRight
            text: Media.title
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
            font.weight: Font.Medium
        }

        Text {
            id: by

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: title.bottom
            elide: Text.ElideRight
            visible: text.length > 0
            text: Media.artist
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }

        // The audio itself, as the bed the artist line sits on. Cava is already
        // running for the expanded panel, so this costs nothing extra - it is
        // the one place the visualiser earns its keep.
        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            spacing: 2
            visible: Media.isPlaying

            Repeater {
                model: Theme.ccWaveBars

                Rectangle {
                    required property int index

                    // Sampled across the full spectrum rather than taking the
                    // first twenty bars, which would show bass only.
                    readonly property real level: Cava.values[
                        Math.floor(index * Cava.barCount / Theme.ccWaveBars)] ?? 0

                    width: 3
                    height: Math.max(2, level * Theme.ccWaveHeight)
                    radius: 1.5
                    color: Theme.accent
                    opacity: 0.55
                    anchors.bottom: parent.bottom

                    Behavior on height {
                        NumberAnimation { duration: 90 }
                    }
                }
            }
        }
    }

    Row {
        id: transport

        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        TransportButton {
            icon: "skip_previous"
            usable: Media.canGoPrevious
            onPressed: Media.previous()
        }

        TransportButton {
            icon: Media.isPlaying ? "pause" : "play_arrow"
            main: true
            usable: Media.canToggle
            onPressed: Media.togglePlaying()
        }

        TransportButton {
            icon: "skip_next"
            usable: Media.canGoNext
            onPressed: Media.next()
        }
    }

    component TransportButton: Item {
        id: button

        property string icon: ""
        property bool main: false
        property bool usable: true

        signal pressed

        implicitWidth: button.main ? Theme.ccTransportMain : Theme.ccTransportSize
        implicitHeight: button.implicitWidth
        opacity: button.usable ? 1 : 0.35

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.main ? Theme.accentStrong
                : Qt.rgba(1, 1, 1, buttonHover.hovered && button.usable ? 0.08 : 0)

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        Icon {
            anchors.centerIn: parent
            size: button.main ? 20 : 18
            text: button.icon
            color: button.main ? Theme.accent : Theme.textDim
        }

        HoverHandler {
            id: buttonHover
            enabled: button.usable
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            enabled: button.usable
            onTapped: button.pressed()
        }
    }
}
