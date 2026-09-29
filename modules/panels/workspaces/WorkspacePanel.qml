import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Hyprland
import qs.modules.common
import qs.modules.island

// Shown for 1.5s after a workspace switch, and nothing else - no clock.
//
// Only workspaces that actually exist are listed. Hyprland destroys a
// workspace once its last window closes, so "exists in the model" already
// means "has windows on it"; the focused one is unioned in so the strip never
// omits where you just landed, even on an empty workspace.
Item {
    id: root

    // The island gives this panel NO horizontal padding of its own. Each cell's
    // own padding is the bar's padding instead, which is what lets the mark
    // meet the bar's edge on the first and last cells while the number stays
    // centred inside it.
    readonly property real islandPaddingH: 0

    // No minimum width either. The cells are already full-height rounded
    // shapes, so the island's usual floor only added dead bar to either end:
    // a single focused workspace rendered as `|  [1]  |` instead of `[1]`.
    readonly property real islandMinWidth: 0

    // Workspaces that hold windows, plus wherever you are right now.
    //
    // "Exists in Hyprland's model" is NOT the same as "has windows": Hyprland
    // keeps an empty workspace alive while it is focused, and when you step off
    // it the NEXT workspace is created before the old empty one is destroyed.
    // Filtering only on existence therefore produced a frame with both of them
    // - `1 2 3 [4]` flashing between `1 2 [3]` and `1 2 [4]` - which shoved the
    // numbers sideways and made the island resize twice. Requiring windows (or
    // focus) removes the stale one immediately, so the strip never changes
    // length on an empty-to-empty switch.
    readonly property var ids: {
        const focused = IslandState.workspace;

        const seen = Hyprland.workspaces.values
            // Special workspaces (scratchpad) carry negative ids.
            .filter(w => w.id > 0
                && ((w.toplevels?.values?.length ?? 0) > 0 || w.id === focused))
            .map(w => w.id);

        if (focused > 0 && !seen.includes(focused))
            seen.push(focused);

        return seen.sort((a, b) => a - b);
    }

    // Where the mark belongs, computed from the layout the strip is HEADING
    // for rather than read off the cells. The cells animate their width when
    // focus moves, and a mark chasing live geometry would lag behind them;
    // both now run the same duration and easing toward the same endpoint.
    readonly property bool hasMark: root.ids.includes(IslandState.workspace)

    readonly property var markSeat: {
        let x = 0;

        for (let i = 0; i < root.ids.length; i++) {
            const active = root.ids[i] === IslandState.workspace;
            const w = active ? Theme.wsActiveCellWidth : Theme.wsIdleCellWidth;

            if (active)
                return [x, w];

            x += w;
        }

        return [0, 0];
    }

    // Animations are held until the strip has been built once, so the mark does
    // not fly in from x=0 the first time the panel appears.
    property bool settled: false

    implicitWidth: strip.implicitWidth
    implicitHeight: strip.implicitHeight

    Component.onCompleted: {
        root.syncCells();
        root.settled = true;
    }

    onIdsChanged: root.syncCells()

    // Update the model IN PLACE instead of handing the Repeater a new array.
    //
    // A Repeater over a plain JS array cannot diff it: every change destroys
    // and rebuilds all delegates. For one frame the strip is empty, so the
    // island animates its width down to nothing and back - that is the scaling
    // glitch - and the focused number visibly gets recreated. Stepping from one
    // EMPTY workspace to another (3 -> 4) is the pure case: nothing about the
    // strip should move, only one digit should change.
    //
    // Editing a ListModel cell by cell keeps every delegate alive, so that is
    // exactly what happens.
    function syncCells(): void {
        const want = root.ids;

        for (let i = 0; i < want.length; i++) {
            if (i < cells.count) {
                if (cells.get(i).wsId !== want[i])
                    cells.setProperty(i, "wsId", want[i]);
            } else {
                cells.append({ wsId: want[i] });
            }
        }

        while (cells.count > want.length)
            cells.remove(cells.count - 1);
    }

    ListModel {
        id: cells
    }

    // ONE mark for the whole strip, declared OUTSIDE the Repeater on purpose.
    //
    // It used to live inside each cell, which could never travel: a Repeater
    // over a plain JS array cannot diff it, so every model change destroys and
    // rebuilds all delegates, taking their marks with them. The mark vanished
    // at one number and reappeared at the next, and the rebuilt cells animated
    // their width up from zero, which is the scaling glitch. Out here it is a
    // single long-lived object that simply slides and stretches to whichever
    // cell is focused.
    Rectangle {
        // The bar's own shape, shortened: `radius = height / 2` over a width
        // comfortably greater than the height. It fills the focused cell inset
        // by the same margin on all four sides. It still overflows the strip
        // vertically (the strip is only as tall as the digits), but no longer
        // reaches the bar's edges. IslandShape clips, and `childrenRect`
        // measures direct children only, so the island's own size is unaffected.
        x: root.markSeat[0] + Theme.wsMarkInset
        y: (parent.height - height) / 2
        width: root.markSeat[1] - Theme.wsMarkInset * 2
        height: Theme.wsMarkSize
        radius: height / 2

        // No border: at exactly the bar's height a stroke sits on the bar's own
        // edge and reads as the mark bursting out of it.
        color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.22)
        opacity: root.hasMark ? 1 : 0

        Behavior on x {
            enabled: root.settled
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Theme.animEasing
            }
        }
        Behavior on width {
            enabled: root.settled
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Theme.animEasing
            }
        }
        Behavior on opacity {
            enabled: root.settled
            NumberAnimation { duration: Theme.animDuration }
        }
    }

    Row {
        id: strip

        // No spacing: the cells' padding already separates the numbers, and a
        // gap here would leave the end marks short of the bar's edge.
        spacing: 0

        Repeater {
            model: cells

            Item {
                id: cell

                required property int wsId
                readonly property bool isActive: IslandState.workspace === cell.wsId

                // Only the focused cell is a full square; the rest are half as
                // wide, so the strip is tight everywhere except around the mark.
                implicitWidth: cell.isActive ? Theme.wsActiveCellWidth : Theme.wsIdleCellWidth

                // Same duration and easing as the mark, so the cell and the
                // mark arrive together.
                Behavior on implicitWidth {
                    enabled: root.settled

                    NumberAnimation {
                        duration: Theme.animDuration
                        easing.type: Theme.animEasing
                    }
                }
                implicitHeight: Theme.wsCellSize


                Text {
                    id: label

                    anchors.centerIn: parent
                    text: cell.wsId
                    color: cell.isActive ? Theme.accent : Theme.textDim
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.wsFontSize
                    font.weight: cell.isActive ? Font.DemiBold : Font.Normal

                    Behavior on color {
                        ColorAnimation { duration: Theme.animDuration }
                    }
                }
            }
        }
    }
}
