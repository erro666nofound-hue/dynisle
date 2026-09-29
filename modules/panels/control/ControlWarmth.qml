import QtQuick
import qs.modules.common
import qs.modules.island
import qs.services

// Reached by HOLDING the night light tile. `hyprctl hyprsunset temperature`
// takes any number, so the tile's on/off is only half of what the service can
// actually do - this is the other half, and it costs nothing while nobody
// holds the tile.
Column {
    id: root

    // Below this the screen goes orange enough to be unpleasant; above it the
    // effect is not worth having.
    readonly property int minKelvin: 2500
    readonly property int maxKelvin: 6000

    spacing: Theme.ccGap

    Item {
        width: Theme.ccWidth
        height: 34

        RoundButton {
            id: back

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            icon: "arrow_back"
            onPressed: IslandState.popView()
        }

        Text {
            anchors.left: back.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "Night light"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 14
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            text: NightLight.active ? `${NightLight.temperature} K` : "Off"
            color: NightLight.active ? Theme.accent : Theme.textDisabled
            font.family: Theme.fontMono
            font.pixelSize: Theme.ccValueSize
        }
    }

    ControlSlider {
        icon: "bedtime"
        // Warmer to the LEFT, which is the direction the screen actually gets
        // warmer - a raw Kelvin scale would run backwards under the hand.
        value: 1 - (NightLight.temperature - root.minKelvin)
            / (root.maxKelvin - root.minKelvin)
        off: !NightLight.active

        onMoved: v => NightLight.set(Math.round(
            root.maxKelvin - v * (root.maxKelvin - root.minKelvin)))
        onIconPressed: NightLight.toggle()
    }

    Text {
        width: Theme.ccWidth
        leftPadding: 4
        text: "Hold the tile to come back here. A tap just turns it on and off."
        color: Theme.textDisabled
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }
}
