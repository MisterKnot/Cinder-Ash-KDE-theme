// SPDX-FileCopyrightText: 2026 MisterKnot
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls.Basic as Basic
Basic.Button {
    id: control
    property bool primary: false
    implicitHeight: 44
    implicitWidth: Math.max(100, contentItem.implicitWidth + 36)
    hoverEnabled: true
    font.pixelSize: 15
    font.bold: primary
    padding: 12
    opacity: enabled ? 1 : 0.5
    contentItem: Text {
        text: control.text
        font: control.font
        color: control.primary ? "#151313" : "#E4DDD5"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 5
        color: control.primary ? (control.down ? "#E0A96D" : "#FF4500") : (control.down || control.hovered ? "#8B0000" : "#2A2421")
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? "#E0A96D" : (control.hovered ? "#C23B22" : "#4A3E3D")
    }
}
