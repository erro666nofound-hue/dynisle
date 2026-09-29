import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.island
import qs.services

// The search field. This is the island's own content, so the island itself
// becomes the search pill - the results are a separate surface below, drawn by
// Island.qml.
Item {
    id: root

    // The island adds no padding of its own here, so the field and the results
    // surface below it come out exactly the same width.
    readonly property real islandPaddingH: 0

    implicitWidth: Theme.launcherWidth
    implicitHeight: Theme.launcherFieldHeight

    // Island.qml grants the surface keyboard focus. Getting the caret into the
    // field takes BOTH halves: `focus: true` below tells Qt where focus belongs
    // inside the window, and this call claims it now in case the window was
    // already focused when the panel loaded.
    Component.onCompleted: {
        // Seeded once, never bound - see the note on onTextChanged below.
        // openLauncher() resets the query, so a fresh launcher opens empty.
        field.text = Launcher.query;
        root.claimFocus();
    }

    function claimFocus(): void {
        field.forceActiveFocus();
    }

    function syncQuery(): void {
        Launcher.query = field.text + field.preeditText;
    }

    Rectangle {
        id: lens

        anchors.left: parent.left
        anchors.leftMargin: Theme.launcherPanelPad
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.launcherLensSize
        height: Theme.launcherLensSize
        radius: width / 2
        color: Theme.accentFill

        Text {
            anchors.centerIn: parent
            text: "\uf002"
            color: Theme.accent
            font.family: Theme.fontMono
            font.pixelSize: 15
        }
    }

    TextInput {
        id: field

        anchors.left: lens.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter

        // Declarative focus, so when the surface gains keyboard focus Qt routes
        // it here rather than leaving it on the window with nowhere to go.
        focus: true

        // NOT `text: Launcher.query`. That is a two-way binding: the binding
        // stays live while you type, so it re-asserts the old value over the
        // character just entered and the field looks like it is ignoring the
        // keyboard. The query flows one way, field -> service, and the field is
        // seeded once in Component.onCompleted.
        //
        // Both signals matter. With a Vietnamese input method running, each
        // keystroke lands in the IME's PREEDIT buffer and `text` does not change
        // until it is committed - which is why the results only appeared after
        // pressing space or enter. Reading the preedit alongside the committed
        // text makes the search live again for every keyboard.
        onTextChanged: root.syncQuery()
        onPreeditTextChanged: root.syncQuery()

        color: Theme.text
        selectionColor: Theme.accent
        selectedTextColor: Theme.surfaceTint
        font.family: Theme.fontFamily
        font.pixelSize: Theme.launcherFontSize
        clip: true

        // Escape must always work: the surface holds exclusive keyboard focus
        // while the launcher is up, so this is the way back.
        Keys.onEscapePressed: IslandState.closeLauncher()
        Keys.onReturnPressed: root.run()
        Keys.onEnterPressed: root.run()
        // On the search list up/down is one row and that IS one item. On the
        // pinned grid it is a whole row of tiles.
        Keys.onUpPressed: Launcher.moveRow(-1)
        Keys.onDownPressed: Launcher.moveRow(1)

        // The pinned row is horizontal, so left/right is the natural way to
        // walk it. Only while nothing is typed: once there is a query these
        // keys belong to the caret.
        Keys.onLeftPressed: event => {
            if (Launcher.query.length === 0)
                Launcher.move(-1);
            else
                event.accepted = false;
        }

        Keys.onRightPressed: event => {
            if (Launcher.query.length === 0)
                Launcher.move(1);
            else
                event.accepted = false;
        }

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            // Preedit counts as typing, or the placeholder would sit on top of
            // the characters an IME has not committed yet.
            // Preedit counts as typing, or the placeholder would sit on top of
            // the characters an IME has not committed yet.
            visible: field.text.length === 0 && field.preeditText.length === 0 && field.preeditText.length === 0
            text: "Search, calculate or run"
            color: Theme.textDisabled
            font: field.font
        }
    }

    function run(): void {
        Launcher.activate();
        IslandState.closeLauncher();
    }

}
