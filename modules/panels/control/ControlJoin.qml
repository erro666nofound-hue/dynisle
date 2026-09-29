import QtQuick
import qs.modules.common
import qs.modules.island
import qs.services

// The password sheet for a network we have never joined. Same bar, one layer
// deeper - nothing pops out over the top.
Column {
    id: root

    readonly property var target: IslandState.joinTarget
    // WPA2 will not accept anything shorter, so there is no point letting the
    // button light up before then.
    readonly property bool valid: field.text.length >= 8

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

        Column {
            anchors.left: back.right
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Text {
                text: root.target?.ssid ?? ""
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 14
            }

            Text {
                text: "Enter the network password"
                color: Theme.textDisabled
                font.family: Theme.fontFamily
                font.pixelSize: 11
            }
        }

        Icon {
            anchors.right: parent.right
            anchors.rightMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            size: 20
            text: "wifi_lock"
            color: Theme.textDim
        }
    }

    Rectangle {
        width: Theme.ccWidth
        height: 40
        radius: Theme.ccListRadius
        color: Qt.rgba(1, 1, 1, 0.06)
        border.width: 1
        border.color: field.activeFocus ? Theme.accent : "transparent"

        Behavior on border.color {
            ColorAnimation { duration: Theme.animDuration }
        }

        TextInput {
            id: field

            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: reveal.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 13
            echoMode: reveal.shown ? TextInput.Normal : TextInput.Password
            passwordCharacter: "•"
            passwordMaskDelay: 400
            selectByMouse: true
            selectionColor: Theme.accentStrong
            selectedTextColor: Theme.text
            focus: true

            // The sheet is only ever on screen because someone chose to type
            // here, so it takes the caret the moment it appears.
            Component.onCompleted: field.forceActiveFocus()

            onAccepted: if (root.valid) root.join()

            Keys.onEscapePressed: IslandState.popView()

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                visible: field.text.length === 0
                text: "Password"
                color: Theme.textDisabled
                font: field.font
            }
        }

        RoundButton {
            id: reveal

            property bool shown: false

            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            icon: reveal.shown ? "visibility_off" : "visibility"
            onPressed: reveal.shown = !reveal.shown
        }
    }

    Text {
        width: Theme.ccWidth
        visible: Network.lastError.length > 0
        leftPadding: 4
        text: "Could not connect. Check the password and try again."
        color: Theme.urgent
        font.family: Theme.fontFamily
        font.pixelSize: 11
        wrapMode: Text.WordWrap
    }

    Row {
        anchors.right: parent.right
        spacing: Theme.ccGap

        SheetButton {
            label: "Cancel"
            onPressed: IslandState.popView()
        }

        SheetButton {
            label: "Connect"
            primary: true
            usable: root.valid
            onPressed: root.join()
        }
    }

    function join(): void {
        Network.connectNew(root.target.ssid, field.text);
        IslandState.popView();
    }

    component SheetButton: Item {
        id: button

        property string label: ""
        property bool primary: false
        // Not `enabled`: that would shadow Item.enabled, which Qt warns about and
        // which leaves the base property quietly out of sync.
        property bool usable: true

        signal pressed

        implicitWidth: buttonLabel.implicitWidth + 32
        implicitHeight: 32

        opacity: button.usable ? 1 : 0.4

        Behavior on opacity {
            NumberAnimation { duration: Theme.animDuration }
        }

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: button.primary
                ? (buttonHover.hovered && button.usable ? Theme.accent : Theme.accentStrong)
                : Qt.rgba(1, 1, 1, buttonHover.hovered && button.usable ? 0.12 : 0.06)

            Behavior on color {
                ColorAnimation { duration: Theme.animDuration }
            }
        }

        Text {
            id: buttonLabel

            anchors.centerIn: parent
            text: button.label
            color: button.primary && buttonHover.hovered && button.usable ? "#101012" : Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: 12
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
