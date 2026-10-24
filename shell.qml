import QtQuick
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick.Effects

// qmllint disable uncreatable-type
PanelWindow {
    id: root

    WlrLayershell.namespace: "cts"

    property string screenshotPath: ""
    property int searchNum: 0
    property var pointsList: []
    property var theMostDown: null
    property var theMostUp: null
    property var theMostLeft: null
    property var theMostRight: null
    property var mosts: null

    function updateDrag(mouse: MouseEvent) {
        root.pointsListChanged();
        if (root.theMostLeft === null || mouse.x < root.theMostLeft)
            root.theMostLeft = mouse.x;

        if (root.theMostRight === null || mouse.x > root.theMostRight)
            root.theMostRight = mouse.x;

        if (root.theMostUp === null || mouse.y < root.theMostUp)
            root.theMostUp = mouse.y;

        if (root.theMostDown === null || mouse.y > root.theMostDown)
            root.theMostDown = mouse.y;
    }

    function stopDrag() {
        root.pointsList = [];
        root.pointsListChanged();
    }

    function readMosts(): var {
        var mosts = {
            left: root.theMostLeft,
            right: root.theMostRight,
            top: root.theMostUp,
            bottom: root.theMostDown
        };
        root.theMostLeft = null;
        root.theMostRight = null;
        root.theMostUp = null;
        root.theMostDown = null;
        return mosts;
    }

    function takeScreenshot() {
        root.visible = false;
        captureTimer.restart();
    }

    visible: true
    onVisibleChanged: if (visible)
        fadeIn.restart()
    screen: Quickshell.screens[0]
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: root.visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    Component.onCompleted: {
        takeScreenshot();
    }

    Timer {
        id: captureTimer

        interval: 100
        running: false
        repeat: false
        onTriggered: {
            screenshotProcess.running = true;
        }
    }

    Timer {
        id: closeTimer

        interval: 600
        running: false
        repeat: false
        onTriggered: {
            root.visible = false;
            Qt.quit();
        }
    }

    Process {
        id: screenshotProcess

        command: ["grim", "-o", root.screen.name, `/tmp/cts${root.searchNum}.png`]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.screenshotPath = `file:///tmp/cts${root.searchNum}.png`;
                root.searchNum++;
                root.visible = true;
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        onActivated: {
            fadeOut.restart();
            closeTimer.running = true;
        }
    }

    Process {
        id: chromium

        command: ["bash", `${Quickshell.shellDir}/search.sh`, root.screenshotPath.replace("file://", "")]
        onExited: exitCode => {
            Qt.quit();
        }
    }

    Process {
        id: crop

        command: ["magick", root.screenshotPath, "-crop", `${root.mosts.right - root.mosts.left}x${root.mosts.bottom - root.mosts.top}+${root.mosts.left}+${root.mosts.top}`, "/tmp/cts-crop.png"]
        onExited: exitCode => {
            if (exitCode === 0) {
                root.screenshotPath = "/tmp/cts-crop.png";
                chromium.running = true;
                root.visible = false;
            }
        }
    }

    Shortcut {
        sequence: "S"
        onActivated: {
            chromium.running = true;
            root.visible = false;
        }
    }

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    Image {
        id: screenCapture

        anchors.fill: parent
        source: root.screenshotPath
        fillMode: Image.PreserveAspectCrop
    }

    Item {
        id: glow
        anchors.fill: parent

        property real thickness: 40
        property real angle: 0
        property real intensity: 0

        NumberAnimation on angle {
            from: 0
            to: 360
            duration: 5000
            loops: Animation.Infinite
            running: glow.visible
        }

        Shape {
            id: colors
            anchors.fill: parent
            layer.enabled: true
            visible: false

            ShapePath {
                strokeWidth: -1
                fillGradient: ConicalGradient {
                    centerX: colors.width / 2
                    centerY: colors.height / 2
                    angle: glow.angle
                    GradientStop {
                        position: 0.00
                        color: "#4285F4"
                    }
                    GradientStop {
                        position: 0.25
                        color: "#EA4335"
                    }
                    GradientStop {
                        position: 0.50
                        color: "#FBBC05"
                    }
                    GradientStop {
                        position: 0.75
                        color: "#34A853"
                    }
                    GradientStop {
                        position: 1.00
                        color: "#4285F4"
                    }
                }
                startX: 0
                startY: 0
                PathLine {
                    x: colors.width
                    y: 0
                }
                PathLine {
                    x: colors.width
                    y: colors.height
                }
                PathLine {
                    x: 0
                    y: colors.height
                }
                PathLine {
                    x: 0
                    y: 0
                }
            }
        }

        Item {
            id: ring
            anchors.fill: parent
            layer.enabled: true
            visible: false

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.width: glow.thickness
                border.color: "white"
            }
        }

        MultiEffect {
            id: masked
            anchors.fill: parent
            source: colors
            maskEnabled: true
            maskSource: ring
            layer.enabled: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: masked
            blurEnabled: true
            blur: 1.0
            blurMax: 64
            opacity: glow.intensity
        }

        ParallelAnimation {
            id: fadeIn

            NumberAnimation {
                target: glow
                property: "intensity"
                from: 0
                to: 1
                duration: 300
                easing.type: Easing.OutCubic
            }

            NumberAnimation {
                target: glow
                property: "thickness"
                from: 0
                to: 40
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        ParallelAnimation {
            id: fadeOut

            NumberAnimation {
                target: glow
                property: "intensity"
                from: 1
                to: 0
                duration: 600
                easing.type: Easing.InCubic
            }

            NumberAnimation {
                target: glow
                property: "thickness"
                from: 40
                to: 0
                duration: 600
                easing.type: Easing.InCubic
            }
        }

        onVisibleChanged: if (visible)
            fadeIn.restart()
    }

    Item {
        anchors.fill: parent

        Shape {
            id: drawing
            anchors.fill: parent

            ShapePath {
                strokeWidth: 4
                strokeColor: "lightgreen"
                fillColor: "transparent"

                PathPolyline {
                    path: root.pointsList
                }
            }
        }

        MultiEffect {
            anchors.fill: parent
            source: drawing

            blurEnabled: true
            blur: 0.7
            blurMax: 32

            colorization: 1.0
            colorizationColor: "#fff"

            opacity: 0.9
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        onPressed: mouse => {
            console.log("Drag started!");
            root.pointsList = [Qt.point(mouse.x, mouse.y)];
            root.updateDrag(mouse);
        }
        onPositionChanged: mouse => {
            if (pressed) {
                const currentPoints = root.pointsList;
                currentPoints.push(Qt.point(mouse.x, mouse.y));
                root.pointsList = currentPoints;
                root.updateDrag(mouse);
            }
        }
        onReleased: mouse => {
            console.log("Drag stopped.");
            const mosts = root.readMosts();
            console.log(mosts.left, mosts.right, mosts.top, mosts.bottom);
            root.mosts = mosts;
            root.stopDrag();
            crop.running = true;
        }
        onCanceled: {
            console.log("Drag canceled.");
            root.stopDrag();
            root.readMosts();
        }
    }
}
