import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire

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
  readonly property string icon: "󰂯"

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
    if (!adapter || !adapter.enabled) return
    // Only write on a real change: BlueZ answers a redundant start with
    // "Operation already in progress", which Quickshell logs as a warning.
    if (on && !adapter.discovering) adapter.discovering = true
    else if (!on && adapter.discovering) adapter.discovering = false
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

  // The stock panel routes audio to the device it just connected. Follow it:
  // the sink appears a moment after the link, so retry a few times, then hand
  // the choice to omarchy-audio-output-set-default.
  property var pendingAudioDevice: null
  property int audioAttempts: 0

  function normalizedAddress(value) {
    return String(value || "").trim().toLowerCase().replace(/[^0-9a-f]/g, "")
  }

  function nodeText(node) {
    var props = (node && node.ready && node.properties) ? node.properties : {}
    return [
      node ? node.name : "", node ? node.description : "",
      node ? node.nickname : "", node ? node.nick : "",
      props["node.name"], props["node.description"], props["node.nick"],
      props["device.name"], props["device.description"],
      props["device.product.name"], props["device.alias"],
      props["device.string"], props["api.bluez5.address"]
    ].join(" ").toLowerCase()
  }

  function bluetoothAudioSink(d) {
    if (!d) return null
    var nodes = Pipewire.nodes ? Pipewire.nodes.values : []
    var address = normalizedAddress(d.address)
    var label = deviceLabel(d).toLowerCase()
    for (var i = 0; i < nodes.length; i++) {
      var node = nodes[i]
      if (!node || !node.isSink || node.isStream) continue
      var text = nodeText(node)
      if (address !== "" && normalizedAddress(text).indexOf(address) !== -1) return node
      if (label !== "" && text.indexOf(label) !== -1) return node
    }
    return null
  }

  function scheduleAudioOutputSwitch(d) {
    pendingAudioDevice = d ? { address: d.address || "", name: d.name || "",
                               deviceName: d.deviceName || "" } : null
    audioAttempts = 0
    if (pendingAudioDevice) audioSwitchTimer.restart()
  }

  function switchPendingAudioOutput() {
    if (!pendingAudioDevice) return
    var sink = bluetoothAudioSink(pendingAudioDevice)
    if (sink) {
      Pipewire.preferredDefaultAudioSink = sink
      Quickshell.execDetached(["omarchy-audio-output-set-default",
        String(sink.id), String(sink.name)])
      pendingAudioDevice = null
      audioSwitchTimer.stop()
      return
    }
    audioAttempts += 1
    if (audioAttempts >= 8) { pendingAudioDevice = null; return }
    audioSwitchTimer.restart()
  }

  Timer {
    id: audioSwitchTimer
    interval: 250
    onTriggered: s.switchPendingAudioOutput()
  }

  function activate(d) {
    if (!d || !d.address) return
    var action = command(d)
    Quickshell.execDetached(["omarchy-bluetooth-device", action, String(d.address)])
    if (action !== "disconnect") scheduleAudioOutputSwitch(d)
  }
}
