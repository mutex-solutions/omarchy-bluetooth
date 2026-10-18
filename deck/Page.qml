import QtQuick
import Quickshell
import qs.Commons

// Bluetooth page, rendered by Deck and by this plugin's own popup.
//
// Follows macOS System Settings: My Devices and Nearby Devices as separate
// groups, a second line carrying "Connected, 78%", and an explicit Connect
// action on a nearby device rather than click-anywhere.
Item {
  id: page

  property var state: null
  property var host: null

  implicitHeight: col.implicitHeight

  onStateChanged: if (state) state.setScanning(true)
  Component.onDestruction: if (state) state.setScanning(false)

  component Caps: Text {
    color: Util.alpha(Color.foreground, 0.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    font.letterSpacing: 1.5
  }

  component Rule: Rectangle {
    width: parent ? parent.width : 0
    height: 1
    color: Util.alpha(Color.foreground, 0.1)
  }

  component Head: Item {
    id: head
    property string glyph: ""
    property string title: ""
    property string value: ""
    property int gap: 0
    width: parent ? parent.width : 0
    height: Style.space(22) + gap

    Item {
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.bottom: parent.bottom
      height: Style.space(22)

      Text {
        id: headGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(14)
        text: head.glyph
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      Text {
        anchors.left: headGlyph.right
        anchors.leftMargin: Style.space(6)
        anchors.verticalCenter: parent.verticalCenter
        text: head.title.toUpperCase()
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.letterSpacing: 1.5
      }

      Text {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        text: head.value
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }
  }

  component DeviceRow: Item {
    id: row
    property var dev: null
    property bool showConnect: false

    width: parent ? parent.width : 0
    height: Style.space(38)

    readonly property bool connected: dev ? dev.connected === true : false
    readonly property bool paired: dev ? (dev.paired || dev.bonded || dev.trusted) === true : false
    readonly property bool hasBattery: dev ? (dev.battery > 0) : false

    Rectangle {
      anchors.fill: parent
      radius: Style.cornerRadius
      color: row.connected
        ? Util.alpha(Color.accent, Style.selectedFillAlpha)
        : (hover.containsMouse ? Util.alpha(Color.foreground, Style.hoverFillAlpha) : "transparent")
      border.width: row.connected ? 1 : 0
      border.color: Util.alpha(Color.accent, 0.5)
    }

    Text {
      id: glyph
      anchors.left: parent.left
      anchors.leftMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(14)
      text: "ᛒ"
      color: row.connected ? Color.accent : Util.alpha(Color.foreground, 0.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Column {
      anchors.left: glyph.right
      anchors.leftMargin: Style.space(8)
      anchors.right: action.left
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      spacing: 1

      Text {
        width: parent.width
        text: page.state ? page.state.deviceLabel(row.dev) : ""
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: row.connected
        elide: Text.ElideRight
      }

      Text {
        width: parent.width
        visible: row.connected || row.paired
        text: row.connected
          ? ("Connected" + (row.hasBattery ? ", " + row.dev.battery + "%" : ""))
          : "Paired"
        color: Util.alpha(Color.foreground, 0.5)
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }

    Rectangle {
      id: action
      anchors.right: parent.right
      anchors.rightMargin: Style.space(8)
      anchors.verticalCenter: parent.verticalCenter
      visible: row.showConnect
      width: Style.space(58)
      height: Style.space(22)
      radius: Style.cornerRadius
      color: Util.alpha(Color.accent, Style.selectedFillAlpha)
      border.width: 1
      border.color: Util.alpha(Color.accent, 0.55)

      Text {
        anchors.centerIn: parent
        text: "Connect"
        color: Color.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }
    }

    MouseArea {
      id: hover
      anchors.fill: parent
      hoverEnabled: true
      cursorShape: Qt.PointingHandCursor
      onClicked: if (page.state && row.dev) page.state.activate(row.dev)
    }
  }

  Column {
    id: col
    width: parent.width
    spacing: Style.space(2)

    // ---- hero ----
    Item {
      width: parent.width
      height: Style.space(44)

      Text {
        id: heroGlyph
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: Style.space(30)
        text: "ᛒ"
        color: page.state && page.state.active ? Color.foreground : Util.alpha(Color.foreground, 0.4)
        font.family: Style.font.family
        font.pixelSize: Style.font.display
        horizontalAlignment: Text.AlignHCenter
      }

      Column {
        anchors.left: heroGlyph.right
        anchors.leftMargin: Style.space(10)
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
          width: parent.width
          text: page.state && page.state.connected
            ? page.state.deviceLabel(page.state.connected)
            : (page.state && page.state.active ? "No device connected" : "Bluetooth off")
          color: Color.foreground
          font.family: Style.font.family
          font.pixelSize: Style.font.title
          font.bold: true
          elide: Text.ElideRight
        }

        Caps {
          width: parent.width
          text: page.state && page.state.active ? "BLUETOOTH" : "DISABLED"
        }
      }
    }

    Rule { }

    // ---- my devices ----
    Head {
      visible: page.state && page.state.active
      glyph: "ᛒ"
      title: "My devices"
      value: page.state ? String(page.state.mine.length) : ""
      gap: Style.space(4)
    }

    Text {
      visible: page.state && page.state.active && page.state.mine.length === 0
      width: parent.width
      height: Style.space(26)
      verticalAlignment: Text.AlignVCenter
      leftPadding: Style.space(8)
      text: "No devices"
      color: Util.alpha(Color.foreground, 0.4)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }

    Repeater {
      model: page.state && page.state.active ? page.state.mine : []
      delegate: DeviceRow { required property var modelData; dev: modelData }
    }

    // ---- nearby ----
    Head {
      visible: page.state && page.state.active && page.state.nearby.length > 0
      glyph: "ᛒ"
      title: "Nearby devices"
      value: page.state ? String(page.state.nearby.length) : ""
      gap: Style.space(6)
    }

    Repeater {
      model: page.state && page.state.active ? page.state.nearby : []
      delegate: DeviceRow { required property var modelData; dev: modelData; showConnect: true }
    }

    Rule { }

    Text {
      width: parent.width
      height: Style.space(26)
      verticalAlignment: Text.AlignVCenter
      leftPadding: Style.space(8)
      text: "Open Omarchy Bluetooth settings"
      color: Util.alpha(Color.foreground, 0.5)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["omarchy-shell", "shell", "summon", "omarchy.bluetooth", "{}"])
      }
    }
  }
}
