import QtQuick
import Quickshell
import Quickshell.Bluetooth

// Bluetooth state. One instance, shared by the standalone bar widget and Deck.
//
// Toggling goes through omarchy-bluetooth-power: BlueZ never persists Powered,
// and a plain `bluetoothctl power on` fails while an rfkill soft block is set.
// Device actions go through omarchy-bluetooth-device, which owns the trust and
// pairing sequence. Writing BlueZ properties directly would look right and fail
// on the paths this plugin exists to handle.
Item {
  id: s

  readonly property var adapter: Bluetooth.defaultAdapter
  readonly property bool active: !!adapter && adapter.enabled
  readonly property string label: "Bluetooth"
  readonly property string icon: "ᛒ"

  readonly property var devices: {
    var src = Bluetooth.devices ? Bluetooth.devices.values : []
    var out = []
    for (var i = 0; i < src.length; i++) if (src[i] && src[i].address) out.push(src[i])
    out.sort(function(a, b) {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      return String(a.name || "").localeCompare(String(b.name || ""))
    })
    return out
  }

  function known(d) {
    return !!(d && (d.paired || d.bonded || d.trusted))
  }

  readonly property var mine: {
    var out = []
    for (var i = 0; i < devices.length; i++) if (known(devices[i])) out.push(devices[i])
    return out
  }

  readonly property var nearby: {
    var out = []
    for (var i = 0; i < devices.length; i++) if (!known(devices[i])) out.push(devices[i])
    return out
  }

  readonly property var connected: {
    for (var i = 0; i < devices.length; i++) if (devices[i].connected) return devices[i]
    return null
  }

  readonly property string detail: {
    if (!active) return "off"
    return connected ? String(connected.name || connected.address || "connected") : "on"
  }

  function toggle() {
    Quickshell.execDetached(["omarchy-bluetooth-power", active ? "off" : "on"])
  }

  function setScanning(on) {
    if (adapter && adapter.enabled) adapter.discovering = !!on
  }

  function deviceLabel(d) {
    if (!d) return ""
    return String(d.deviceName || d.name || d.address || "?")
  }

  function command(d) {
    if (!d) return ""
    if (d.connected) return "disconnect"
    return known(d) ? "connect" : "pair"
  }

  function activate(d) {
    if (!d || !d.address) return
    Quickshell.execDetached(["omarchy-bluetooth-device", command(d), String(d.address)])
  }
}
