import QtQuick 2.2
import QtQuick.Controls 2.15
import MuseScore 3.0

MuseScore {
    description: "Recorder Fingering (ported to Qt6/MuseScore4)"
    requiresScore: true
    version: "1.0"
    menuPath: "Plugins.Recorder Fingering"
    pluginType: "dialog"
    width:  270
    height: 300

    property bool okFont: true; // flag to indicate if recorder font present
    property real pXoff: 0.5; // text X-Offset
    property real pYoff: 2.5; // text Y-Offset
    property real pHole: 2.0; // hole size from 0.0 to 10.0 (Tiny to Huge)
    property var pFingers: ["a","z","s","x","d","f","v","g","b","h","n","j",
                            "q","2","w","3","e","r","%","t","6","y","8","u","i"];
    property int nofApply: 0; // Count of "Apply" presses for use with "Undo"

    onRun: {
        // check font availability
        if (Qt.fontFamilies().indexOf("Recorder Font") < 0) {
            okFont = false;
            fontNotFound.open();
	    console.log("Font not found!")
            return;
        } else {
            okFont = true;
            dialog.open();
	    console.log("Font found!")
        }
    }

    function applyFont() {
        console.log("applyFont() called");
        if (!okFont) {
            fontNotFound.open();
	    console.log("Font not found!")
            return;
        }

        var holeVal = Number(txtHsize.text);
        if (isNaN(holeVal)) {
            pHole = 2.0;
        } else {
            pHole = holeVal;
            if (pHole < 0) pHole = 2.0;
            else if (pHole > 20) pHole = 20.0;
        }

        var xVal = Number(txtXoff.text);
        if (isNaN(xVal)) pXoff = 0.0; else pXoff = xVal;

        var yVal = Number(txtYoff.text);
        if (isNaN(yVal)) pYoff = 0.0; else pYoff = yVal;

        var staveBeg, staveEnd, tickEnd, rewindMode, toEOF;
        var cursor = curScore.newCursor();

        cursor.rewind(Cursor.SELECTION_START);
        if (cursor.segment) {
            staveBeg = cursor.staffIdx;
            cursor.rewind(Cursor.SELECTION_END);
            staveEnd = cursor.staffIdx;
            if (!cursor.tick) {
                toEOF = true;
            } else {
                toEOF = false;
                tickEnd = cursor.tick;
            }
            rewindMode = Cursor.SELECTION_START;
        } else {
            staveBeg = 0;
            staveEnd = curScore.nstaves - 1;
            toEOF = true;
            rewindMode = Cursor.SCORE_START;
        }

        var fontSize = 12 * pHole + 36;
        var booApply = false;

        curScore.startCmd();
        for (var stave = staveBeg; stave <= staveEnd; ++stave) {
            cursor.staffIdx = stave;
            cursor.voice = 0;
            cursor.rewind(rewindMode);
            cursor.staffIdx = stave;
            while (cursor.segment && (toEOF || cursor.tick < tickEnd)) {
                if (cursor.element) {
                    if (cursor.element.type == Element.CHORD) {
                        var pitch = cursor.element.notes[0].pitch;
                        var index = pitch - 72;
                        if (index >= 0 && index < pFingers.length) {
                            var txt = newElement(Element.STAFF_TEXT);
                            txt.text = pFingers[index];
                            txt.placement = Placement.BELOW;
                            txt.offsetX = pXoff;
                            txt.offsetY = pYoff;
                            txt.align = 2; // HCENTER
                            txt.fontFace = "Recorder Font";
                            txt.fontSize = fontSize;
                              cursor.add(txt);
                            booApply = true;
                        }
                    }
                }
                cursor.next();
            }
        }
        curScore.endCmd();
        if (booApply) ++nofApply;
        // update undo-like control UI
        btnUndo.enabled = (nofApply > 0);
    }

    function unApplyFont() {
        if (nofApply > 0) {
            cmd("undo");
            --nofApply;
            btnUndo.enabled = (nofApply > 0);
        }
    }

    // UI Design Block

	Rectangle {
        id: rootRect
        width: dialog.width
        height: dialog.height

            // Text fields

            Text {
                id: lblNoFont
                x: 10; y: 10
                visible: !okFont
                text: "Recorder font is missing"
            }

            Text {
                id: lblHsize
                x: 99; y: 60
                visible: okFont
                text: "Hole size"
	        font.pointSize: 13
            }

            TextField {
                id: txtHsize
                x: 103; y: 90
                width: 60; height: 28
                text: "2.0"
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 13
                visible: okFont
            }

            Text {
                id: lblXoff
                x: 15; y: 60
                text: "X-Offset"
	        font.pointSize: 13
                visible: okFont
            }

            TextField {
                id: txtXoff
                x: 16; y: 90
                width: 60; height: 28
                text: "0.0"
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 13
                visible: okFont
            }

            Text {
                id: lblYoff
                x: 191; y: 60
                text: "Y-Offset"
	        font.pointSize: 13
                visible: okFont
            }

            TextField {
                id: txtYoff
                x: 191; y: 90
                width: 60; height: 28
                text: "2.0"
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 13
                visible: okFont
            }

            // Buttons

            Rectangle {
                id: btnApply
                x: 40; y: 150
                width: 180; height: 36
                color: !okFont ? "#888" : "#2E8B57"
                radius: 6

                Text {
                    anchors.centerIn: parent
                    text: "Apply"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: okFont
                    onClicked: {
                        console.log("Apply clicked")
                        applyFont()
                    }
                }
            }

            Rectangle {
                id: btnUndo
                x: 40; y: 192
                width: 180; height: 36
                property bool enabled: false
                color: enabled ? "#8B2E2E" : "#555"
                radius: 6

                Text {
                    anchors.centerIn: parent
                    text: "Undo"
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: btnUndo.enabled
                    onClicked: {
                        console.log("Undo clicked")
                        unApplyFont()
                    }
                }
            }
        }

    // Simple dialog to inform about missing font
    Dialog {
        id: fontNotFound
        title: "Missing Font"
        modal: true
        visible: false

        contentItem: Column {
            spacing: 10
            padding: 12
            Text { text: "The recorder font is not installed on your device." }
            Text { text: "Please install RecorderFont.ttf and restart MuseScore." }
            Button {
                text: "OK"
                onClicked: fontNotFound.close()
            }
        }
    }
}