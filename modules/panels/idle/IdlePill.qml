import QtQuick
import qs.modules.common
import qs.services

// The resting content of the island: the time, nothing else.
// Matches vault/assets/reference-screenshots/01-collapsed-idle.png — the date
// belongs to the expanded week strip (UT-04), not to the idle pill.
Item {
    id: root

    implicitWidth: clock.implicitWidth
    implicitHeight: clock.implicitHeight

    Text {
        id: clock

        anchors.centerIn: parent

        text: DateTime.time
        color: Theme.text
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontSize
        font.weight: Font.Medium
    }
}
