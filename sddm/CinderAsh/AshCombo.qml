// SPDX-FileCopyrightText: 2026 MisterKnot
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Controls.Basic as Basic
Basic.ComboBox {
    id: control
    implicitHeight: 46
    font.pixelSize: 15
    leftPadding: 14
    rightPadding: 34
    hoverEnabled: true
    palette.text: "#E4DDD5"
    palette.buttonText: "#E4DDD5"
    palette.base: "#151313"
    palette.window: "#2A2421"
    palette.highlight: "#8B0000"
    palette.highlightedText: "#E4DDD5"
    contentItem: TextInput {
        text: control.editable ? control.editText : control.displayText
        font: control.font
        color: "#E4DDD5"
        selectionColor: "#8B0000"
        selectedTextColor: "#E4DDD5"
        readOnly: !control.editable
        selectByMouse: control.editable
        verticalAlignment: TextInput.AlignVCenter
        clip: true
        onTextEdited: control.editText = text
    }
    indicator: Text {
        x: control.width - width - 14
        y: (control.height-height)/2
        text: "⌄"
        color: "#A59D98"
        font.pixelSize: 18
    }
    background: Rectangle {
        radius: 5
        color: "#151313"
        border.width: control.activeFocus ? 2 : 1
        border.color: control.activeFocus || control.hovered ? "#FF4500" : "#4A3E3D"
    }
    delegate: Basic.ItemDelegate {
        required property int index
        width: control.width - 2
        text: control.textAt(index)
        highlighted: control.highlightedIndex === index
        contentItem: Text { text: parent.text; color: "#E4DDD5"; font: control.font; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
        background: Rectangle { color: parent.highlighted || parent.hovered ? "#8B0000" : "#2A2421" }
    }
    popup: Basic.Popup {
        y: control.height + 4
        width: control.width
        padding: 1
        implicitHeight: Math.min(contentItem.implicitHeight + 2, 240)
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            Basic.ScrollIndicator.vertical: Basic.ScrollIndicator { }
        }
        background: Rectangle { color: "#2A2421"; border.color: "#4A3E3D"; radius: 5 }
    }
}
