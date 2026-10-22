# Changelog

## 0.1.2

- The tile glyph is a Material icon, matching the other Deck tiles.

## 0.1.1

- Connecting a device now routes audio to it, as the stock Bluetooth panel
  does: the matching PipeWire sink is found by BlueZ address or device name,
  retried for a moment while the link comes up, then made the default through
  `omarchy-audio-output-set-default`. The sink matching follows the stock
  panel's properties list, so renamed and vendor-named sinks still match.

## 0.1.0

First release.

- Standalone Omarchy bar widget: Bluetooth state, My Devices and Nearby Devices,
  connect, disconnect, and pair for an unknown device.
- Deck section (`deck/Section.qml` + `deck/Page.qml`) sharing one state object.
- Discovery follows the UI: enabled while the panel or page is open, cleared
  when it closes.
