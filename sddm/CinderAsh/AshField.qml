// SPDX-FileCopyrightText: 2026 MisterKnot
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls.Basic as Basic
Basic.TextField {
    id: control
    implicitHeight: 46
    color: "#E4DDD5"
    placeholderTextColor: "#A59D98"
    selectionColor: "#8B0000"
    selectedTextColor: "#E4DDD5"
    font.pixelSize: 16
    leftPadding: 14
    rightPadding: 14
    background: Rectangle {
        radius: 5
        color: "#151313"
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus ? "#FF4500" : "#4A3E3D"
    }
}
