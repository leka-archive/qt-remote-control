import QtQuick 2.4
import QtQuick.Window 2.2
import QtBluetooth 5.3
import QtQuick.Controls 1.3
import QtQuick.Controls.Styles 1.4
import QtQuick.Dialogs 1.2
import QtQml 2.0
// adding localstorage :)
import QtQuick.LocalStorage 2.0 as Sql

Item {
    id: mainPageWraper
    visible: true
    property string selected_main

    MouseArea {
        anchors.fill: parent
        onClicked: {
            function is_open(){
                if (colorSelector.visible == true)
                    return true
                return false
            }

            if (is_open() == true) {
                lightController.changeColor(lightController.prevColor, selected_main)
                lightController.closeSelector()
            }
        }
    }

    // CREATE DATABASE FOR SAVING USER DATA
    function getDatabase() {
        var db = Sql.LocalStorage.openDatabaseSync("TestDB", "", "Description", 100000);
        db.transaction(
                    function(tx) {
                        var query="CREATE TABLE IF NOT EXISTS DATA(type VARCHAR(100), value VARCHAR(100))";
                        var debug =tx.executeSql(query);
                        console.debug(JSON.stringify(debug));
                    });
        return db;
    }

    function printValues() {
        var db = getDatabase();
        db.transaction( function(tx) {
            var rs = tx.executeSql("SELECT * FROM DATA");
            console.debug(JSON.stringify(rs));
            console.debug("===============================");
            for(var i = 0; i < rs.rows.length; i++) {
                var dbItem = rs.rows.item(i);
                console.log("TYPE"+ dbItem.type + ", VALUE"+dbItem.value);
            }
            console.debug("-------------------------------");
        });
    }


    Item {
        Component.onCompleted: {
            printValues()
        }
    }

    // FIRST VIEW WRAPPER (main view, not bluetooth)
    Item {
        id: mainView
        width: parent.width
        height: parent.height
        anchors.left: parent.left
        anchors.leftMargin: 0
        anchors.right: parent.right

        // JOYSTICK ELEMENT (JoyStick.qml)
        JoyStick {
            id:joystick

            property string oldDir
            property int oldPower

            function set_value(val) {
                val = Math.round(val * 100) / 100
                if (val < 100 && val >= 10)
                    val = "+0"+val
                else if (val > -100 && val <= -10)
                    val = "-0"+Math.abs(val)
                else if (val === 0)
                    val = "+000"
                else if (val < 10 && val > 0)
                    val = "+00"+val
                else if (val > -10 && val < 0)
                    val = "-00"+Math.abs(val)
                else if (val >= 100)
                    val = "+"+val
                else if (val <= -100)
                    val = val
                return val
            }

            function set_value_led(val) {
                val = Math.round(val * 100) / 100
                if (val < 100 && val >= 10)
                    val = "0"+val
                else if (val > -100 && val <= -10)
                    val = "0"+Math.abs(val)
                else if (val === 0)
                    val = "000"
                else if (val < 10 && val > 0)
                    val = "00"+val
                else if (val > -10 && val < 0)
                    val = "00"+Math.abs(val)
                else if (val >= 100)
                    val = val
                else if (val <= -100)
                    val = val
                return val
            }

            function rgbToBin(r,g,b){
                var bin = r << 16 | g << 8 | b;
                return (function(h){
                    return new Array(25-h.length).join("0")+h
                })(bin.toString(2))
            }

            function rgbToUint32(color) {
                var red = Math.round(color.r * 255)
                var green = Math.round(color.g * 255)
                var blue = Math.round(color.b * 255)
                var uint32 = rgbToBin(red,green,blue)
                return uint32
            }

            onDirChanged: {
                if (socket.connected == true) {
                    var colorArray = lightController.getColors()
                    var colorEars = colorArray.center
                    var colorTopLeft = colorArray.topLeft
                    var colorTopRight = colorArray.topRight
                    var colorBotLeft = colorArray.botLeft
                    var colorBotRight = colorArray.botRight
                    var ct
                    var fl
                    var fr
                    var bl
                    var br
                    var mainControl = colorArray.right

                    if (lightController.getSelected().right == "#000000")
                        mainControl = set_value_led(Math.round(mainControl.r * 255))+","+set_value_led(Math.round(mainControl.g * 255))+","+set_value_led(Math.round(mainControl.b * 255))
                    else if (lightController.getSelected().right = "#808080")
                        mainControl = "000,000,000"

                    if (lightController.getSelected().center == "#000000")
                        ct = set_value_led(Math.round(colorEars.r * 255))+","+set_value_led(Math.round(colorEars.g * 255))+","+set_value_led(Math.round(colorEars.b * 255))
                    else if(lightController.getSelected().center == "#808080")
                        ct = mainControl

                    if (lightController.getSelected().topLeft == "#000000")
                        fl = set_value_led(Math.round(colorTopLeft.r * 255))+","+set_value_led(Math.round(colorTopLeft.g * 255))+","+set_value_led(Math.round(colorTopLeft.b * 255))
                    else if(lightController.getSelected().topLeft == "#808080")
                        fl = mainControl

                    if (lightController.getSelected().topRight == "#000000")
                        fr = set_value_led(Math.round(colorTopRight.r * 255))+","+set_value_led(Math.round(colorTopRight.g * 255))+","+set_value_led(Math.round(colorTopRight.b * 255))
                    else if(lightController.getSelected().topRight == "#808080")
                        fr = mainControl

                    if (lightController.getSelected().botLeft == "#000000")
                        bl = set_value_led(Math.round(colorBotLeft.r * 255))+","+set_value_led(Math.round(colorBotLeft.g * 255))+","+set_value_led(Math.round(colorBotLeft.b * 255))
                    else if(lightController.getSelected().botLeft == "#808080")
                        bl = mainControl

                    if (lightController.getSelected().botRight == "#000000")
                        br = set_value_led(Math.round(colorBotRight.r * 255))+","+set_value_led(Math.round(colorBotRight.g * 255))+","+set_value_led(Math.round(colorBotRight.b * 255))
                    else if(lightController.getSelected().botRight == "#808080")
                        br = mainControl

                    socket.sendStringData("["+set_value(left)+","+set_value(right)+","+ct+","+fl+","+fr+","+bl+","+br+"]")
//                    console.debug("["+set_value(left)+","+set_value(right)+","+ct+","+fl+","+fr+","+bl+","+br+"]")

                }
            }

            width: parent.height * 0.4
            height: parent.height * 0.4
            anchors.left: parent.left
            anchors.leftMargin: 50
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 50
        }

        /***********************************************/

        LightControl {
            id: lightController
            height: parent.height * 0.4 + 100
            width: parent.height* 0.4
            anchors.right: parent.right
            anchors.rightMargin: 0
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 0
        }
        Item {
            id: colorpicker
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter

            ColorDialogTab {
                id: colorSelector
                width: 300
                height: 400
                onColorChanged: {
                    lightController.changeColor(color, selected)
                    selected_main = selected
                    console.debug("color: "+color+"  prev_color: "+lightController.prevColor)
                }
                anchors.verticalCenter: parent.verticalCenter
                anchors.horizontalCenter: parent.horizontalCenter
                visible: false
            }
        }

        // SCANNER
        Scanner {
            id: scanner
            onSelected: {
                socket.connected = false
                socket.setService(remoteService)
                socket.connected = true
                stackView.pop()
            }
        }

        BluetoothSocket {
            id: socket
            connected: true
            onSocketStateChanged: {
                console.log("Socket state: " + socketState)
            }

            onDataAvailable: {
                console.debug("Received (dataAvaliable) " )
                console.debug(stringData);
            }

            onStringDataChanged: {
                console.debug("Received (stringDataChanged) " )
                console.debug(stringData);
            }
        }
        Rectangle {
            color: "transparent"
            anchors.top: parent.top
            anchors.topMargin: 0
            width: parent.width
            height: 100

            Text {
                text: socket.connected ? socket.service.deviceName : ""
                visible: socket.connected
                font.pointSize: 35
                anchors.leftMargin: 10
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: btScanButton.left
            }

            ImgButton {
                id: btScanButton

                imgSrc: "btScanButton.svg"
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 80
                height: 80

                onClicked: {
                    console.debug("BT scannig menu selected.")
                    stackView.push(scanner)
                }
            }
        }
    }

    StackView {
        id: stackView
        initialItem: mainView
        focus: true
        anchors.fill: parent
        Keys.onReleased: {
            if (event.key === Qt.Key_Back && stackView.depth > 1) {
                stackView.pop()
                event.accepted = true
                console.debug("Back key pressed.")
            }
        }
    }
}
