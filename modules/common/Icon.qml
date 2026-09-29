import QtQuick
import qs.modules.common

// One line-art icon. Material Symbols is a variable font whose FILL axis is
// what separates outline glyphs from solid ones, so every icon in dynisle goes
// through here rather than setting the family by hand and getting filled shapes.
Text {
    id: root

    property real size: 20

    font.family: Theme.fontIcon
    font.pixelSize: root.size
    font.weight: Font.Light
    font.variableAxes: ({ "FILL": 0, "wght": 300, "GRAD": 0, "opsz": 24 })

    color: Theme.textDim
    verticalAlignment: Text.AlignVCenter
    horizontalAlignment: Text.AlignHCenter
}
