import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 900
    height: 700
    title: "SpamGuard AI"

    Rectangle {
        anchors.fill: parent
        color: "#0f172a"
    }

    StackView {
        id: mainStack
        anchors.fill: parent
        initialItem: frontPage

        pushEnter: Transition { PropertyAnimation { property: "opacity"; from: 0; to: 1; duration: 400 } }
        pushExit: Transition { PropertyAnimation { property: "opacity"; from: 1; to: 0; duration: 400 } }
    }

    Component {
        id: frontPage
        Page {
            background: Rectangle { color: "transparent" }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 50
                spacing: 30

                ColumnLayout {
                    spacing: 5
                    Text {
                        text: "SpamGuard AI"
                        font.pixelSize: 38
                        font.bold: true
                        color: "#38bdf8"
                    }
                    Text {
                        text: "Analyze emails for phishing and malicious content."
                        font.pixelSize: 16
                        color: "#94a3b8"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#1e293b"
                    radius: 15
                    border.color: "#334155"
                    border.width: 2

                    ScrollView {
                        anchors.fill: parent
                        anchors.margins: 20

                        TextArea {
                            id: emailInput
                            placeholderText: "Paste raw email content or headers here..."
                            color: "#f8fafc"
                            font.pixelSize: 15
                            wrapMode: TextEdit.Wrap
                            placeholderTextColor: "#475569"
                            background: null

                            onTextChanged: {
                                emailAnalyzer.emailText = text
                            }
                        }
                    }
                }

                Button {
                    id: analyzeBtn
                    Layout.preferredWidth: 250
                    Layout.preferredHeight: 60
                    Layout.alignment: Qt.AlignHCenter
                    enabled: emailInput.text.length > 0 && !emailAnalyzer.isAnalyzing

                    background: Rectangle {
                        color: analyzeBtn.enabled ? (analyzeBtn.down ? "#0284c7" : "#0ea5e9") : "#334155"
                        radius: 12
                        border.color: analyzeBtn.hovered && analyzeBtn.enabled ? "#7dd3fc" : "transparent"
                        border.width: analyzeBtn.hovered && analyzeBtn.enabled ? 2 : 0
                    }

                    contentItem: Text {
                        text: emailAnalyzer.isAnalyzing ? "ANALYZING..." : "ANALYZE NOW"
                        color: "black"
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        emailAnalyzer.analyzeEmail()
                    }
                }
            }
        }
    }

    Component {
        id: resultPage
        Page {
            background: Rectangle { color: "transparent" }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 40
                spacing: 20

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50

                    Button {
                        text: "← Back"
                        font.pixelSize: 14
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 40

                        background: Rectangle {
                            color: parent.down ? "#1e293b" : "transparent"
                            radius: 8
                            border.color: "#334155"
                            border.width: 2
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "#94a3b8"
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        onClicked: {
                            mainStack.pop()
                            emailAnalyzer.clearAnalysis()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Analysis Report"
                        font.pixelSize: 24
                        font.bold: true
                        color: "#38bdf8"
                    }

                    Item { Layout.fillWidth: true }

                    Item { Layout.preferredWidth: 100 }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ScrollView {
                        anchors.centerIn: parent
                        width: Math.min(parent.width, 800)
                        height: parent.height
                        clip: true

                        ColumnLayout {
                            width: parent.width + 210
                            spacing: 25

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: mainCardContent.implicitHeight + 60
                                color: "#1e293b"
                                radius: 15
                                border.color: emailAnalyzer.spamScore >= 0.75 ? "#dc2626" :
                                             emailAnalyzer.spamScore >= 0.5 ? "#f59e0b" :
                                             emailAnalyzer.spamScore >= 0.3 ? "#eab308" : "#22c55e"
                                border.width: 3

                                ColumnLayout {
                                    id: mainCardContent
                                    anchors.fill: parent
                                    anchors.margins: 30
                                    spacing: 15

                                    Rectangle {
                                        width: 100
                                        height: 100
                                        radius: 50
                                        color: "transparent"
                                        border.color: emailAnalyzer.spamScore >= 0.75 ? "#dc2626" :
                                                     emailAnalyzer.spamScore >= 0.5 ? "#f59e0b" :
                                                     emailAnalyzer.spamScore >= 0.3 ? "#eab308" : "#22c55e"
                                        border.width: 4
                                        Layout.alignment: Qt.AlignHCenter

                                        Text {
                                            anchors.centerIn: parent
                                            text: emailAnalyzer.spamScore >= 0.75 ? "✗" :
                                                  emailAnalyzer.spamScore >= 0.5 ? "⚠" :
                                                  emailAnalyzer.spamScore >= 0.3 ? "!" : "✓"
                                            font.pixelSize: 50
                                            color: emailAnalyzer.spamScore >= 0.75 ? "#dc2626" :
                                                   emailAnalyzer.spamScore >= 0.5 ? "#f59e0b" :
                                                   emailAnalyzer.spamScore >= 0.3 ? "#eab308" : "#22c55e"
                                        }
                                    }

                                    Text {
                                        text: emailAnalyzer.classification
                                        font.pixelSize: 32
                                        font.bold: true
                                        color: "white"
                                        Layout.alignment: Qt.AlignHCenter
                                        wrapMode: Text.WordWrap
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Text {
                                        text: "Spam Probability: " + Math.round(emailAnalyzer.spamScore * 100) + "%"
                                        font.pixelSize: 18
                                        color: "#94a3b8"
                                        Layout.alignment: Qt.AlignHCenter
                                    }
                                }
                            }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Threat Level"
                                font.pixelSize: 18
                                font.bold: true
                                color: "#e2e8f0"
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 30
                                color: "#334155"
                                radius: 15

                                Rectangle {
                                    width: parent.width * emailAnalyzer.spamScore
                                    height: parent.height
                                    color: emailAnalyzer.spamScore >= 0.75 ? "#dc2626" :
                                           emailAnalyzer.spamScore >= 0.5 ? "#f59e0b" :
                                           emailAnalyzer.spamScore >= 0.3 ? "#eab308" : "#22c55e"
                                    radius: 15

                                    Behavior on width {
                                        NumberAnimation { duration: 600; easing.type: Easing.OutCubic }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            color: "#1e293b"
                            radius: 15
                            implicitHeight: detailsContent.implicitHeight + 50

                            ColumnLayout {
                                id: detailsContent
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.margins: 25
                                spacing: 20

                                Text {
                                    text: "Detection Details"
                                    font.pixelSize: 20
                                    font.bold: true
                                    color: "#38bdf8"
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    columns: 2
                                    rowSpacing: 15
                                    columnSpacing: 40

                                    Text {
                                        text: "🔍 Spam Keywords:"
                                        font.pixelSize: 15
                                        color: "#94a3b8"
                                    }
                                    Text {
                                        text: emailAnalyzer.analysisResult.spamKeywords ?
                                              emailAnalyzer.analysisResult.spamKeywords.length + " found" : "0 found"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: emailAnalyzer.analysisResult.spamKeywords &&
                                               emailAnalyzer.analysisResult.spamKeywords.length > 0 ? "#f59e0b" : "#22c55e"
                                    }

                                    Text {
                                        text: "🔗 Suspicious Links:"
                                        font.pixelSize: 15
                                        color: "#94a3b8"
                                    }
                                    Text {
                                        text: emailAnalyzer.analysisResult.suspiciousLinks ?
                                              emailAnalyzer.analysisResult.suspiciousLinks.length + " detected" : "0 detected"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: emailAnalyzer.analysisResult.suspiciousLinks &&
                                               emailAnalyzer.analysisResult.suspiciousLinks.length > 0 ? "#dc2626" : "#22c55e"
                                    }

                                    Text {
                                        text: "⚡ Urgency Tactics:"
                                        font.pixelSize: 15
                                        color: "#94a3b8"
                                    }
                                    Text {
                                        text: emailAnalyzer.analysisResult.hasUrgency ? "Yes" : "No"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: emailAnalyzer.analysisResult.hasUrgency ? "#f59e0b" : "#22c55e"
                                    }

                                    Text {
                                        text: "🎣 Phishing Indicators:"
                                        font.pixelSize: 15
                                        color: "#94a3b8"
                                    }
                                    Text {
                                        text: emailAnalyzer.analysisResult.hasPhishingIndicators ? "Yes" : "No"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: emailAnalyzer.analysisResult.hasPhishingIndicators ? "#dc2626" : "#22c55e"
                                    }

                                    Text {
                                        text: "📢 Excessive Capitals:"
                                        font.pixelSize: 15
                                        color: "#94a3b8"
                                    }
                                    Text {
                                        text: emailAnalyzer.analysisResult.excessiveCapitals ? "Yes" : "No"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: emailAnalyzer.analysisResult.excessiveCapitals ? "#f59e0b" : "#22c55e"
                                    }

                                    Text {
                                        text: "❗ Excessive Punctuation:"
                                        font.pixelSize: 15
                                        color: "#94a3b8"
                                    }
                                    Text {
                                        text: emailAnalyzer.analysisResult.excessivePunctuation ? "Yes" : "No"
                                        font.pixelSize: 15
                                        font.bold: true
                                        color: emailAnalyzer.analysisResult.excessivePunctuation ? "#f59e0b" : "#22c55e"
                                    }
                                }
                            }
                        }
                    }
                }
            }
            }
        }
    }

    Connections {
        target: emailAnalyzer
        function onAnalysisCompleted() {
            mainStack.push(resultPage)
        }
    }
}
