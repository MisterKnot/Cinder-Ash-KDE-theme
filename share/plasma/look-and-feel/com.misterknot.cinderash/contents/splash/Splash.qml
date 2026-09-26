// SPDX-FileCopyrightText: 2026 MisterKnot
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
Rectangle {
    id: root
    color: "#151313"
    property int stage: 0
    property real progress: Math.min(1, Math.max(0.04, stage / 6))
    Behavior on progress { NumberAnimation { duration: 260 } }
    Column {
        anchors.centerIn: parent
        spacing: 28
        Item {
            width: 80; height: 90; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { x: 18; y: 16; width: 25; height: 62; rotation: 27; color: "#8B0000" }
            Rectangle { x: 39; y: 4; width: 16; height: 70; rotation: 27; color: "#C23B22" }
            Rectangle { x: 52; y: 15; width: 5; height: 46; rotation: 27; color: "#FF4500" }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "CINDER ASH"; color: "#E4DDD5"; font.pixelSize: 26; font.letterSpacing: 6 }
        Rectangle {
            width: 220; height: 3; color: "#4A3E3D"; anchors.horizontalCenter: parent.horizontalCenter
            Rectangle { width: parent.width * root.progress; height: 3; color: "#FF4500" }
        }
        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Preparing your desktop"; color: "#A59D98"; font.pixelSize: 14 }
    }
}
