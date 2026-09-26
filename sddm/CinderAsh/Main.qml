// SPDX-FileCopyrightText: 2026 MisterKnot
// SPDX-License-Identifier: GPL-3.0-or-later
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic as Basic

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: "#151313"
    property bool authenticating: false
    property string message: ""
    property date now: new Date()
    readonly property bool wide: width >= 1100
    readonly property bool compact: height < 720
    readonly property int cardPad: compact ? 20 : 32
    readonly property string userName: userInput.editText.trim()
    function attemptLogin() {
        if (authenticating || userName.length === 0 || sessionInput.currentIndex < 0) return;
        message = "";
        authenticating = true;
        sddm.login(userName, password.text, sessionInput.currentIndex);
    }
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true
    Image {
        anchors.fill: parent
        source: "background.svg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.65
    }
    // Keep the authentication form on a quiet, opaque surface.
    Rectangle { anchors.fill: parent; color: "#151313"; opacity: 0.2 }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Column {
        x: root.wide ? root.width * 0.09 : 28
        y: root.wide ? root.height * 0.29 : 20
        spacing: 12
        Text { text: "CINDER ASH"; color: "#E0A96D"; font.pixelSize: root.wide ? 18 : 14; font.letterSpacing: 5 }
        Text { visible: root.wide; text: Qt.formatTime(root.now, "hh:mm"); color: "#E4DDD5"; font.pixelSize: 96; font.weight: Font.Light }
        Text { visible: root.wide; text: Qt.formatDate(root.now, "dddd, d MMMM"); color: "#A59D98"; font.pixelSize: 18 }
        Rectangle { visible: root.wide; width: 64; height: 3; color: "#C23B22" }
    }
    Rectangle {
        id: card
        width: Math.min(420, root.width - 48)
        height: Math.min(root.height - 140, form.implicitHeight + root.cardPad * 2)
        x: root.wide ? root.width * 0.66 - width / 2 : (root.width - width)/2
        y: Math.max(68, (root.height - height)/2)
        radius: 12
        color: "#2A2421"
        border.color: "#4A3E3D"
        Flickable {
            anchors.fill: parent
            contentHeight: form.implicitHeight + root.cardPad * 2
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            Basic.ScrollBar.vertical: Basic.ScrollBar {}
        ColumnLayout {
            id: form
            anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
            anchors.margins: root.cardPad
            spacing: root.compact ? 8 : 12
            Text { text: "Welcome back"; color: "#E4DDD5"; font.pixelSize: 28; font.weight: Font.DemiBold }
            Text { text: "Sign in to your desktop"; color: "#A59D98"; font.pixelSize: 14; Layout.bottomMargin: 8 }
            Text { text: "User"; color: "#A59D98"; font.pixelSize: 13 }
            AshCombo {
                id: userInput
                objectName: "userInput"
                Layout.fillWidth: true
                model: userModel
                textRole: "name"
                editable: true
                currentIndex: Math.max(-1, userModel.lastIndex)
                enabled: !root.authenticating
                Accessible.name: "User name"
                onActivated: password.forceActiveFocus()
                Component.onCompleted: if (userModel.lastUser) editText = userModel.lastUser
                KeyNavigation.tab: password
            }
            Text { text: "Password"; color: "#A59D98"; font.pixelSize: 13 }
            AshField {
                id: password
                objectName: "passwordInput"
                Layout.fillWidth: true
                placeholderText: "Enter your password"
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                enabled: !root.authenticating
                Accessible.name: "Password"
                onAccepted: root.attemptLogin()
                KeyNavigation.tab: sessionInput
                Component.onCompleted: forceActiveFocus()
            }
            Text { visible: keyboard.capsLock; text: "Caps Lock is on"; color: "#E0A96D"; font.pixelSize: 13 }
            Text { text: "Desktop session"; color: "#A59D98"; font.pixelSize: 13 }
            AshCombo {
                id: sessionInput
                objectName: "sessionInput"
                Layout.fillWidth: true
                model: sessionModel
                textRole: "name"
                currentIndex: Math.max(0, sessionModel.lastIndex)
                enabled: !root.authenticating
                Accessible.name: "Desktop session"
                KeyNavigation.tab: loginButton
            }
            Text {
                Layout.fillWidth: true
                visible: root.message.length > 0
                text: root.message
                wrapMode: Text.WordWrap
                color: "#E0A96D"
                font.pixelSize: 13
                Accessible.role: Accessible.AlertMessage
            }
            AshButton {
                id: loginButton
                objectName: "loginButton"
                Layout.fillWidth: true
                Layout.topMargin: 8
                primary: true
                text: root.authenticating ? "Signing in…" : "Sign in"
                enabled: !root.authenticating && root.userName.length > 0 && sessionInput.currentIndex >= 0
                onClicked: root.attemptLogin()
                KeyNavigation.tab: layoutInput
            }
        }
        }
    }
    RowLayout {
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: 28; anchors.bottomMargin: 22
        spacing: 10
        AshCombo {
            id: layoutInput
            objectName: "keyboardInput"
            implicitWidth: 155
            model: keyboard.layouts
            textRole: "longName"
            currentIndex: keyboard.currentLayout
            visible: count > 1
            Accessible.name: "Keyboard layout"
            onActivated: keyboard.currentLayout = currentIndex
        }
        AshButton { text: "About"; onClicked: aboutDialog.open() }
    }
    RowLayout {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 28; anchors.bottomMargin: 22
        spacing: 10
        AshButton { text: "Suspend"; visible: sddm.canSuspend; enabled: !root.authenticating; onClicked: sddm.suspend() }
        AshButton { text: "Restart"; visible: sddm.canReboot; enabled: !root.authenticating; onClicked: { powerDialog.action = "restart"; powerDialog.open(); } }
        AshButton { text: "Shut down"; visible: sddm.canPowerOff; enabled: !root.authenticating; onClicked: { powerDialog.action = "shutdown"; powerDialog.open(); } }
    }
    Basic.Popup {
        id: aboutDialog
        anchors.centerIn: parent
        width: Math.min(380, root.width - 48)
        padding: 24
        modal: true
        focus: true
        background: Rectangle { color: "#2A2421"; radius: 10; border.color: "#E0A96D" }
        contentItem: ColumnLayout {
            spacing: 14
            Text { text: "Cinder Ash 0.01"; color: "#E4DDD5"; font.pixelSize: 24 }
            Text { text: "Created by MisterKnot"; color: "#A59D98"; font.pixelSize: 15 }
            Text { text: "github.com/MisterKnot"; color: "#E0A96D"; font.pixelSize: 14 }
            AshButton { text: "Close"; Layout.alignment: Qt.AlignRight; onClicked: aboutDialog.close() }
        }
    }
    Basic.Popup {
        id: powerDialog
        property string action: ""
        anchors.centerIn: parent
        width: Math.min(380, root.width - 48)
        padding: 24
        modal: true
        focus: true
        background: Rectangle { color: "#2A2421"; radius: 10; border.color: "#4A3E3D" }
        contentItem: ColumnLayout {
            spacing: 20
            Text { text: powerDialog.action === "restart" ? "Restart this computer?" : "Shut down this computer?"; color: "#E4DDD5"; font.pixelSize: 20 }
            RowLayout {
                AshButton { text: "Cancel"; onClicked: powerDialog.close() }
                AshButton { primary: true; text: "Confirm"; onClicked: { powerDialog.close(); if (powerDialog.action === "restart") sddm.reboot(); else sddm.powerOff(); } }
            }
        }
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.authenticating = false;
            root.message = "Sign-in failed. Check your user name and password.";
            password.clear();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() { password.clear(); root.message = "Starting your session…"; }
    }
    Connections {
        target: keyboard
        function onCurrentLayoutChanged() { layoutInput.currentIndex = keyboard.currentLayout; }
    }
}
