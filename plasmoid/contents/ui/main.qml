import QtQuick 2.0
import QtQuick.Layouts 1.1
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 3.0 as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.plasmoid 2.0

Item {
    id: root
    
    property string control: "0x10"
    property string listCmd: "ddcutil detect -t"
    property variant displays: []
    property variant displayIntr: []

    property int brightnessReadCount: 0


    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    PlasmaCore.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []

        property date brightnessCmdStart: new Date(0)
        property string nextBrightnessCommand: ""

        onNewData: {
            console.log(sourceName)
            if (sourceName == listCmd) {
                brightnessReadCount = 0;
                var respLines = data["stdout"].trim().split(/\n/);
                var disp = [];
                var invalidDisplay = false;
                var name = "";
                var i2cBus = ""
                var index = 0;
                for (var line of respLines) {
                    line = line.trim();
                    if (line.length == 0) {
                        if (!invalidDisplay) {
                            disp.push({name, i2cBus, brightness: -1});
                        }
                    } else if (line.startsWith("Display")) {
                        index++;
                        invalidDisplay = false;
                    } else if (line.startsWith("Invalid")) {
                        invalidDisplay = true;
                    } else if (line.startsWith("I2C bus") && !invalidDisplay) {
                        i2cBus = line.split(/:/)[1].trim().substr(9);
                        // request for current brightness
                        executable.exec(`ddcutil getvcp -b ${i2cBus} ${control} | grep "VCP code"`);
                    } else if (line.startsWith("Monitor") && !invalidDisplay) {
                        name = line.split(/:/)[2].trim() || `Display ${index}`;
                    }
                }
                if (!invalidDisplay) {
                    disp.push({name, i2cBus, brightness: 0});
                }
                displayIntr = disp;
            } else if (sourceName.startsWith("ddcutil getvcp -b")) {
                brightnessReadCount++;
                var bus = sourceName.split(/\s/)[3];
                for (var disp of displayIntr) {
                    if (disp.i2cBus == bus) {
                        disp.brightness = Number(data["stdout"].split(/=/)[1].split(/,/)[0].trim())
                        break;
                    }
                }
                if (brightnessReadCount == displayIntr.length) {
                    displays = displayIntr;
                }
            } else if (sourceName.startsWith("ddcutil setvcp")) {
                // execute next command
                if (nextBrightnessCommand) {
                    brightnessCmdStart = new Date();
                    connectSource(nextBrightnessCommand);
                    nextBrightnessCommand = "";
                } else {
                    brightnessCmdStart = new Date(0);
                }
            }
            disconnectSource(sourceName);
        }
        
        function exec(cmd) {
            connectSource(cmd);
        }

        function processBrightnessCommands(cmd) {
            if (Date.now() - brightnessCmdStart.getTime() > 2000) {
                nextBrightnessCommand = "";
                brightnessCmdStart = new Date();
                connectSource(cmd);
            } else {
                nextBrightnessCommand = cmd;
            }
        }
    }

    Plasmoid.compactRepresentation: Item {
        property int wheelDelta: 0

        PlasmaCore.IconItem {
            id: buttonIcon
            anchors.fill: parent
            source: "display-brightness-symbolic"
        }
        /* Rectangle {
            width: 2
            height: parent.height * ((displays.length > 0 ? displays[0].brightness : 0) / 100.0)
            anchors.bottom: parent.bottom
            anchors.right: parent.right
        } */
        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (!plasmoid.expanded) {
                    executable.exec(listCmd);
                }
                plasmoid.expanded = !plasmoid.expanded;
            }
            onWheel: {
                if (!plasmoid.expanded) {
                    plasmoid.expanded = true;
                }
                var delta = wheel.angleDelta.y || wheel.angleDelta.x;
                wheelDelta += delta;
                while (wheelDelta >= 120) {
                    wheelDelta -= 120;
                    for (var disp of displays) {
                        disp.brightness += 5;
                        if (disp.brightness > 100) {
                            disp.brightness = 100;
                        }
                        updateBrightness(disp);
                    }
                    displays = displays;
                }
                while (wheelDelta <= -120) {
                    wheelDelta += 120;
                    for (var disp of displays) {
                        disp.brightness -= 5;
                        if (disp.brightness < 0) {
                            disp.brightness = 0;
                        }
                        updateBrightness(disp);
                    }
                    displays = displays;
                }
            }
        }
    }

    Plasmoid.fullRepresentation: Item {
        Layout.minimumWidth: container.implicitWidth
        Layout.minimumHeight: container.implicitHeight
        Layout.preferredWidth: 400 * PlasmaCore.Units.devicePixelRatio
        Layout.preferredHeight: 80 * PlasmaCore.Units.devicePixelRatio

        ColumnLayout {
            id: container
            anchors.fill: parent
            spacing: 20
            PlasmaExtras.Heading {
                level: 1
                text: `Brightness Control`
                Layout.alignment: Qt.AlignHCenter
            }
            Repeater {
                model: displays.length
                ColumnLayout {
                    Layout.fillWidth: true
                    PlasmaExtras.Heading {
                        level: 3
                        text: displays[index].name
                        font.weight: Font.Bold
                    }
                    RowLayout {
                        PlasmaComponents.Slider {
                            Layout.fillWidth: true
                            from: 0
                            to: 100
                            value: displays[index].brightness
                            stepSize: 5
                            onMoved: {
                                if (displays[index].brightness != value) {
                                    displays[index].brightness = value;
                                    updateBrightness(displays[index]);
                                    displays = displays
                                }
                            }
                        }
                        PlasmaExtras.Heading {
                            text: `  ${displays[index].brightness}%`
                            level: 4
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        executable.exec(listCmd);
    }

    function updateBrightness(disp) {
        executable.processBrightnessCommands(`ddcutil setvcp -b ${disp.i2cBus} ${control} ${disp.brightness} --noverify`);
    }
}