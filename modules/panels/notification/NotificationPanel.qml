pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs.modules.common
import qs.modules.island
import qs.services

// A notification popup, deliberately plain: an icon, who sent it, and what it
// says. No actions, no reply field, no progress rail, no timestamp - none of
// the senders that actually run on this machine use them, and the ones that
// theoretically could (Discord, Zalo) reach this box through a browser, which
// never sets an inline-reply action.
Item {
    id: root

    readonly property var notif: Notifications.current
    readonly property bool urgent: root.notif?.urgency === NotificationUrgency.Critical
    readonly property bool low: root.notif?.urgency === NotificationUrgency.Low

    readonly property color tint: root.urgent ? Theme.urgent
        : (root.low ? Theme.textDim : Theme.accent)

    // The type marker the sender put at the front of the summary is redundant
    // once the island draws its own icon: "⚡ Charging", "󰂚 Do Not Disturb".
    readonly property string summary: Notifications.stripMarkers(root.notif?.summary ?? "")
    readonly property string body: root.notif?.body ?? ""

    // Plenty of senders put their own name in the summary too; printing it
    // twice just wastes the line.
    readonly property string appLabel: {
        const a = root.notif?.appName ?? "";
        return a === root.summary ? "" : a;
    }

    // ---- the icon ---------------------------------------------------------
    // Measured, not assumed: `appIcon` always arrives EMPTY. Whatever the sender
    // put in app_icon is folded into `image` as an `image://icon/...` url - and
    // Quickshell builds that url even for a name that resolves to nothing, so
    // its presence proves nothing. `brightness-lcd` came through as a perfectly
    // well-formed url pointing at an icon that does not exist, which once left
    // the block blank: the Image had a source, so the glyph never ran.
    readonly property string rawImage: root.notif?.image ?? ""

    readonly property string iconPrefix: "image://icon/"
    readonly property string iconName: root.rawImage.startsWith(root.iconPrefix)
        ? root.rawImage.slice(root.iconPrefix.length) : ""

    // `image://icon//home/x.png` - the name after the prefix is itself an
    // absolute path, which is how a screenshot tool hands over its own PNG.
    readonly property bool iconIsPath: root.iconName.startsWith("/")

    // Real pixels: the sender's own image, or a file it pointed at.
    readonly property string photo: root.iconIsPath
        ? `file://${root.iconName}`
        : (root.iconName.length === 0 ? root.rawImage : "")

    // Papirus draws the battery names as a filled, colour-coded level pill,
    // which fights the flat one-plane line art the rest of the island uses -
    // and we have exact battery glyphs of our own. Every other theme icon is
    // kept, because a real app's own icon is worth more than a guess.
    readonly property bool preferOwnGlyph: root.iconName.startsWith("battery")

    // A theme icon, and ONLY if it truly resolves. `iconPath` in check mode
    // returns an empty string for a name the theme does not have, and that is
    // the one honest answer available here.
    readonly property string themeIcon: root.iconIsPath || root.iconName.length === 0
        || root.preferOwnGlyph
        ? ""
        : Quickshell.iconPath(root.iconName, true)

    readonly property string glyph: Notifications.glyphFor(root.summary,
        root.notif?.appName ?? "", root.urgent)

    // ---- the countdown, read by IslandShape -------------------------------
    // The sender's own timeout wins. -1 means "server decides"; 0 means never.
    // A sender may ask for longer, and several here do - the battery script
    // asks for five seconds, a screenshot tool for eight. Capped anyway: how
    // long a popup sits on screen is the shell's call, not the sender's.
    // 0 still means never, which is the one request worth honouring.
    readonly property int lifetime: {
        const own = root.low ? Theme.notifLifetimeLow : Theme.notifLifetime;
        const t = root.notif?.expireTimeout ?? -1;
        if (t === 0)
            return 0;
        if (t > 0)
            return Math.max(1200, Math.min(t, own));
        return own;
    }

    // Critical never expires on its own, and neither does one the pointer is
    // resting on - reading a notification must not make it disappear.
    readonly property bool held: IslandState.expanded || root.urgent
        || root.lifetime === 0

    property real life: 1
    readonly property real drain: root.urgent ? -1 : root.life
    readonly property color drainColor: root.held ? Theme.track : root.tint

    // Restarts from full when the pointer leaves rather than resuming, which is
    // deliberate: hovering means you are reading it, and letting go should give
    // the whole countdown back.
    NumberAnimation on life {
        from: 1
        to: 0
        duration: root.lifetime
        running: !root.held
        onFinished: IslandState.dismissNotification()
    }

    implicitWidth: Theme.notifWidth
    implicitHeight: Math.max(Theme.notifBlockSize, column.implicitHeight)

    // ---- the media block --------------------------------------------------
    ClippingRectangle {
        id: block

        anchors.left: parent.left
        // Centring covers both cases: when the block is as tall as the row this
        // puts it at the top anyway.
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.notifBlockSize

        // A glyph or an app icon stretches with the row, because a tinted block
        // has no aspect to spoil and a gap under it would look like a mistake.
        // A photo does NOT: cropping a screenshot into a tall slot mangles it,
        // so real pixels stay square and sit centred.
        height: root.photo.length > 0 ? Theme.notifBlockSize : root.implicitHeight
        radius: Theme.notifBlockRadius

        color: root.urgent ? Qt.rgba(Theme.urgent.r, Theme.urgent.g, Theme.urgent.b, 0.16)
            : Theme.skeleton

        Image {
            anchors.fill: parent
            visible: root.photo.length > 0
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            // Both dimensions, or an SVG provider has no aspect to crop to and
            // draws nothing at all.
            sourceSize.width: Theme.notifBlockSize * 2
            sourceSize.height: Theme.notifBlockSize * 2
            source: root.photo
        }

        IconImage {
            anchors.centerIn: parent
            visible: root.themeIcon.length > 0
            implicitSize: Theme.notifAppIconSize
            asynchronous: true
            source: root.themeIcon
        }

        Icon {
            anchors.centerIn: parent
            visible: root.photo.length === 0 && root.themeIcon.length === 0
            size: Theme.notifGlyphSize
            text: root.glyph
            color: root.urgent ? Theme.urgent : Theme.textDim
        }
    }

    // ---- the text ---------------------------------------------------------
    Column {
        id: column

        anchors.left: block.right
        anchors.leftMargin: Theme.notifGap
        anchors.right: parent.right
        // Centred, so a one-line notification sits in the middle of the square
        // block instead of clinging to its top edge.
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: root.appLabel.length > 0
            text: root.appLabel
            color: root.tint
            font.family: Theme.fontFamily
            font.pixelSize: Theme.notifAppSize
        }

        Text {
            width: parent.width
            elide: Text.ElideRight
            visible: text.length > 0
            text: root.summary
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.notifSummarySize
            font.weight: Font.Medium
        }

        Text {
            width: parent.width
            visible: text.length > 0
            wrapMode: Text.Wrap
            // A notification is a glance, not a document.
            maximumLineCount: 3
            elide: Text.ElideRight
            // Senders may send basic markup; StyledText renders it instead of
            // printing the tags.
            textFormat: Text.StyledText
            text: root.body
            color: Theme.textDim
            font.family: Theme.fontFamily
            font.pixelSize: Theme.notifBodySize
        }
    }

    // Clicking anywhere dismisses it. With nothing to press, there is no click
    // that could be meant for something else.
    MouseArea {
        anchors.fill: parent
        z: -1
        cursorShape: Qt.PointingHandCursor
        onClicked: IslandState.dismissNotification()
    }
}
