import QtQuick
import qs.modules.common
import qs.services

// CPU, memory and temperature, in the control centre itself rather than behind
// another layer - enough to answer "is something wrong" at a glance.
//
// Three equal cells, so this one divides by three rather than using the tile
// grid's four columns.
Row {
    id: root

    readonly property real cellWidth: (Theme.ccWidth - Theme.ccGap * 2) / 3

    spacing: Theme.ccGap

    Vital {
        icon: "memory"
        label: "CPU"
        value: `${Math.round(SysInfo.cpu * 100)}`
        unit: "%"
        fraction: SysInfo.cpu
    }

    Vital {
        icon: "memory_alt"
        label: "RAM"
        // Gigabytes, not just a percentage: "50%" says nothing on its own,
        // "3.8 GB" of 7.6 tells you whether the next thing you open will fit.
        // The bar carries the proportion, so the number is free to be useful.
        value: SysInfo.gib(SysInfo.memUsed)
        unit: " GB"
        fraction: SysInfo.memFraction
    }

    Vital {
        icon: "device_thermostat"
        label: "Temp"
        value: `${Math.round(SysInfo.temperature)}`
        unit: "°C"
        fraction: (SysInfo.temperature - Theme.ccTempMin)
            / (Theme.ccTempMax - Theme.ccTempMin)
        // The only one that earns a colour. CPU and memory being busy is
        // normal; a hot package on a laptop this age is not.
        tint: SysInfo.temperature >= Theme.ccTempHot ? Theme.urgent
            : (SysInfo.temperature >= Theme.ccTempWarm ? Theme.warning : Theme.accent)
    }

    component Vital: Item {
        id: cell

        property string icon: ""
        property string label: ""
        property string value: ""
        property string unit: ""
        property real fraction: 0
        property color tint: Theme.accent

        implicitWidth: root.cellWidth
        implicitHeight: Theme.ccVitalHeight

        Rectangle {
            anchors.fill: parent
            radius: Theme.ccVitalRadius
            color: Qt.rgba(1, 1, 1, 0.05)
        }

        Icon {
            id: glyph

            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.top: parent.top
            anchors.topMargin: 9
            size: 15
            text: cell.icon
            color: cell.tint === Theme.accent ? Theme.textDim : cell.tint

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        Text {
            anchors.left: glyph.right
            anchors.leftMargin: 7
            anchors.verticalCenter: glyph.verticalCenter
            text: cell.label
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: 11
        }

        // The unit is deliberately quieter and smaller than the figure: the
        // number is what you read, the unit only says which number it is.
        //
        // An Item, NOT a Row: baseline anchoring is what lines two different
        // type sizes up on the same line, and a Row positions its children
        // itself - the baseline anchors inside one were ignored and the whole
        // readout escaped out of the top of the cell.
        Item {
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.verticalCenter: glyph.verticalCenter
            width: figure.implicitWidth + unit.implicitWidth + 1
            height: figure.implicitHeight

            Text {
                id: figure

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: cell.value
                color: Theme.text
                font.family: Theme.fontMono
                font.pixelSize: 14
            }

            Text {
                id: unit

                anchors.left: figure.right
                anchors.leftMargin: 1
                anchors.baseline: figure.baseline
                text: cell.unit
                color: Theme.textDisabled
                font.family: Theme.fontMono
                font.pixelSize: 11
            }
        }

        Rectangle {
            id: track

            anchors.left: parent.left
            anchors.leftMargin: 11
            anchors.right: parent.right
            anchors.rightMargin: 11
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10
            height: 4
            radius: 2
            color: Theme.track

            Rectangle {
                width: track.width * Math.max(0, Math.min(1, cell.fraction))
                height: parent.height
                radius: parent.radius
                color: cell.tint

                Behavior on width {
                    NumberAnimation { duration: 400 }
                }

                Behavior on color {
                    ColorAnimation { duration: Theme.animDuration }
                }
            }
        }
    }
}
