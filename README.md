# Bluetooth

Bluetooth state, devices and pairing for Omarchy. A bar widget, or a section
inside [Deck](https://github.com/mutex-solutions/omarchy-deck).

## Standalone

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-bluetooth --enable
```

Click the Bluetooth icon: My Devices and Nearby Devices, with the connected
device named, its battery shown, and an explicit Connect action on a device you
have not paired with.

## Inside Deck

```bash
omarchy plugin add https://github.com/mutex-solutions/omarchy-bluetooth
```

Then add the section to Deck's registry:

```json
{ "id": "bluetooth", "title": "Bluetooth",
  "file": "/home/YOU/.config/omarchy/plugins/mutex-solutions.bluetooth/deck/Section.qml",
  "page": "/home/YOU/.config/omarchy/plugins/mutex-solutions.bluetooth/deck/Page.qml" }
```

`install-bundle.sh` in the Deck repo does this for every section at once.

## How it is built

| File | Role |
| --- | --- |
| `State.qml` | adapter state, device groups, connect and pair |
| `deck/Section.qml` | the five members Deck reads |
| `deck/Page.qml` | the panel content |
| `Panel.qml` | the standalone bar widget and its popup |

Device state comes from Quickshell's `Bluetooth` service. Power and device
actions go through Omarchy's own helpers, `omarchy-bluetooth-power` and
`omarchy-bluetooth-device`, which own the rfkill and trust sequences. Writing
BlueZ properties directly would look correct and fail exactly where it matters.

The footer opens Omarchy's Bluetooth panel for anything this plugin does not
implement.

## Requirements

Omarchy 4.x with BlueZ.

## Licence

MIT. See [LICENSE](LICENSE).
