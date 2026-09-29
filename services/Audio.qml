pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

// Speaker and microphone. Volume and mute come straight from Pipewire, which
// works perfectly - but WHICH device is the default has to come from `pactl`.
//
// Measured, not assumed: `Pipewire.defaultAudioSink` is unusable in this build.
// It is typed `PwNodeIface` and is not null, yet it reaches QML as a QVariant
// box that never coerces - `?.description`, `?.audio?.volume` and `?.ready` all
// come out nullish, and it never equals the same node taken from
// `Pipewire.nodes`. Assigning it to a typed `PwNode` property (which is what
// end4-pC does) does not help either.
//
// So the previous identity lookup here could never match, and it silently fell
// through to `sinks[0]` - which on this machine is Easy Effects, NOT the
// default. The control centre was showing and driving the wrong device, and the
// volume it displayed never moved when the volume actually changed.
//
// `pactl get-default-sink` prints the node name, which matches `PwNode.name`
// exactly, so one cheap call resolves it and `pactl subscribe` says when to ask
// again. No polling.
Singleton {
    id: root

    property string defaultSinkName: ""
    property string defaultSourceName: ""

    // Falling back to the first device still matters: for the moment before
    // pactl answers, showing the obvious device beats showing nothing.
    readonly property var sink: root.sinks.find(n => n.name === root.defaultSinkName)
        ?? root.sinks[0] ?? null
    readonly property var source: root.sources.find(n => n.name === root.defaultSourceName)
        ?? root.sources[0] ?? null

    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property string sinkName: root.sink?.description ?? root.sink?.nickname ?? ""

    readonly property real micVolume: root.source?.audio?.volume ?? 0
    readonly property bool micMuted: root.source?.audio?.muted ?? false
    readonly property string sourceName: root.source?.description ?? root.source?.nickname ?? ""

    // Real devices only: streams are individual apps playing audio, not
    // somewhere you can send output.
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => !n.isSink && !n.isStream
        && n.type === PwNodeType.AudioSource)

    // Quickshell only keeps a node's properties live while something binds it,
    // so the ones being read here have to be tracked explicitly.
    PwObjectTracker {
        objects: [root.sink, root.source, ...root.sinks, ...root.sources]
    }

    function setVolume(v: real): void {
        if (!root.sink?.audio)
            return;

        root.sink.audio.volume = Math.max(0, Math.min(1, v));
        // Dragging up from silence unmutes, which is what everyone expects.
        if (v > 0 && root.sink.audio.muted)
            root.sink.audio.muted = false;
    }

    function toggleMute(): void {
        if (root.sink?.audio)
            root.sink.audio.muted = !root.sink.audio.muted;
    }

    function setMicVolume(v: real): void {
        if (!root.source?.audio)
            return;

        root.source.audio.volume = Math.max(0, Math.min(1, v));
        if (v > 0 && root.source.audio.muted)
            root.source.audio.muted = false;
    }

    function toggleMicMute(): void {
        if (root.source?.audio)
            root.source.audio.muted = !root.source.audio.muted;
    }

    // ---- which device is default ------------------------------------------
    Process {
        id: readSink

        running: true
        command: ["pactl", "get-default-sink"]
        stdout: StdioCollector {
            onStreamFinished: root.defaultSinkName = text.trim()
        }
    }

    Process {
        id: readSource

        running: true
        command: ["pactl", "get-default-source"]
        stdout: StdioCollector {
            onStreamFinished: root.defaultSourceName = text.trim()
        }
    }

    function refreshDefaults(): void {
        readSink.running = false;
        readSink.running = true;
        readSource.running = false;
        readSource.running = true;
    }

    // Event-driven: pactl prints a line whenever anything changes, and the
    // server events are the ones that carry a default-device switch.
    Process {
        running: true
        command: ["pactl", "subscribe"]
        stdout: SplitParser {
            onRead: line => {
                if (line.includes("on server") || line.includes("on sink")
                        || line.includes("on source"))
                    settle.restart();
            }
        }
    }

    // pactl reports the change before the server has finished applying it.
    Timer {
        id: settle

        interval: 200
        onTriggered: root.refreshDefaults()
    }

    // One process each: a sink change and a source change are separate user
    // actions and must not cancel one another.
    Process { id: applySink }
    Process { id: applySource }

    function setSink(node): void {
        if (!node)
            return;

        // Optimistic, so the tick in the device picker moves under the pointer
        // instead of waiting for pactl to answer.
        root.defaultSinkName = node.name;
        applySink.running = false;
        applySink.command = ["pactl", "set-default-sink", node.name];
        applySink.running = true;
    }

    function setSource(node): void {
        if (!node)
            return;

        root.defaultSourceName = node.name;
        applySource.running = false;
        applySource.command = ["pactl", "set-default-source", node.name];
        applySource.running = true;
    }
}
