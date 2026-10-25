# ble_chat

Chat with people nearby over Bluetooth Low Energy. No internet and no server: one
phone **hosts** a room, others **find** it by name and **join** with a 6-digit code.

The native Bluetooth layer is **Android only** for now (Kotlin). iOS has no handlers yet.

## How it works

```
Host phone                                   Guest phones
──────────                                   ────────────
Advertises "Lab-42 · A7K2"  ───────────────▶ Scan for the name, list rooms
Runs a GATT server (1 service,               Pick a room, enter the 6-digit code
  1 characteristic)                          Connect, discover services,
◀─────────────── write (message) ──────────  turn on notifications
Relays it as a notification ───────────────▶ Everyone else receives it
```

- **Room label:** a room is shown as `Name · CODE`. The 4-character `CODE` tells apart
  rooms that share a name. It is public.
- **Join code:** a separate 6-digit code, made by the host for each room and shown on the
  host screen. It is never advertised. The guest sends it after connecting.
  **The host does not check it yet** (see [Not done yet](#not-done-yet)).
- **Capacity:** 2 to 5 people including the host. Rooms advertise how many are in, so
  full rooms show as **FULL** and can't be opened.

## Project layout

```
lib/
  business_logic/   blocs and cubits (one folder per feature)
  domain/           entities and repository interfaces
  data/             repository implementations (platform channels)
  presentation/     screens/ and common/ widgets
  theme/            colours, palette, ThemeData
  common/           constants and small helpers
android/app/src/main/kotlin/.../ble_chat/
  AdvertiserHandler.kt   host: advertising + GATT server
  ScannerHandler.kt      guest: scanning
  ConnectHandler.kt      guest: GATT client, send / receive
  Utils.kt, Constants.kt message and advertisement formats, UUIDs
  MainActivity.kt        registers the channels, releases handlers on exit
```

### State management

`flutter_bloc`. Each feature has a bloc that listens to a repository stream and turns
native reports into state. The pattern is the same everywhere:

1. Subscribe to the native event stream **before** calling the native method.
2. Wrap every native message in an internal bloc event, so only handlers emit.
3. A pure `_stateFor(event)` maps (state, event) to the next state.

| Bloc | Job |
| --- | --- |
| `BluetoothPermissionCubit` | Permissions and whether the radio is on (global) |
| `HostSessionBloc` | Start hosting (3 steps), people count, close the room |
| `ScanSessionBloc` | Scan, smooth signal, mark rooms gone, list results |
| `ConnectSessionBloc` | Connect to a room as a guest (chat messages to follow) |

Each bloc is created by the route that owns it, so it is closed with that route.

## Platform channels

All native calls reply once; progress and failures come as events on the matching
`EventChannel`. Failures are sent as stream errors with a code, and the repository turns
them into events.

| Channel (`…/methods`, `…/events`) | Methods |
| --- | --- |
| `bleAdvertiser` | `start`, `stop`, `updatePeople`, `send` |
| `bleScanner` | `scan`, `stop` |
| `connect` | `connect`, `disconnect`, `send` |
| `bluetoothPermission`, `bluetoothState` | permissions, radio state, `sdkInt` |

## Bluetooth details

### Advertisement (host)

One manufacturer-data block, company id `0xFFFF` (reserved for testing), in the
advertising packet itself so scanners can **filter in hardware**:

| Byte | Meaning |
| --- | --- |
| 0 | marker `0x4C` (scans filter on company id + this byte) |
| 1 | people in the room |
| 2 | max people |
| 3–6 | 4-character room code (ASCII) |
| 7… | room name (UTF-8, 16 characters at most) |

The packet holds 24 payload bytes, so the name limit is a hard one. The room is never put
in the phone's Bluetooth name. Advertising data can't change in place, so the host
**restarts advertising** when the people count changes. Advertising stops by itself after
60 seconds, both from an app timer and from the system's own timeout (the system one still
works if Android freezes the app).

### GATT server (host)

- Service `0000feed-…`, characteristic `0000beef-…` (read / write / notify) with a CCCD.
- Guests write messages to the characteristic. The host **must** answer each write with
  `sendResponse`, or the guest is disconnected after about 30 seconds.
- A guest receives messages only after it writes the CCCD (turns notifications on). The host
  keeps a `subscribers` set and relays each message to everyone except its sender.

### Message format

```
8 bytes  random message id (made by the sender, shown as 16 hex characters)
1 byte   sender name length (name: 20 bytes at most)
n bytes  sender name (UTF-8)
rest     message text
```

A write or notification can carry **MTU − 3** bytes. The guest asks for an MTU of 247 on
connect (Android 17 does it automatically); the host tracks each guest's MTU. Longer
messages are rejected with `message_too_long`.

### Scanning (guest)

Hardware filter on the company id + marker. The room name is matched in the app
(contains, case-insensitive) against the name part only. The scan runs 10 seconds; if
rooms are found it keeps going up to 60 seconds so signal strength stays live. Signal is
smoothed (moving average) and only updates the UI when the bars would change. A room not
heard from for 5 seconds is marked **not available**.

## Permissions

| Android | Needs |
| --- | --- |
| 12 and up | `BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` |
| 11 and older | **Location** (a scan finds nothing without it) and the Location switch on |

## Lifecycle

- Going to the background keeps the connection, advertising and scan running.
- Handlers are released when the activity and Flutter engine are destroyed
  (`MainActivity.cleanUpFlutterEngine`): advertising, the GATT server and its guests,
  scans and the handler threads are stopped.
- If Android kills the process, the Bluetooth stack closes the GATT server; guests see a
  lost connection after a few seconds (nothing is sent). There is no foreground service,
  so a backgrounded host can be frozen or killed by the system.

## Not done yet

- **Checking the 6-digit code.** The host makes and shows it; the guest UI collects it.
  The check (a separate write-only characteristic, an `authenticated` set, 3 tries, a
  timeout, refusing chat writes and subscriptions until it passes, and limiting pending
  connections) is not written. Until then anyone nearby who finds the room can join.
- Host-to-guests notifications have no queue: a burst can drop messages.
- iOS native layer.
- Stale GATT callbacks from an old connection after a quick reconnect.

## Development

```
flutter pub get
flutter analyze lib
flutter run                 # two Android phones are needed: a phone can't see its own room
cd android && ./gradlew :app:compileDebugKotlin
```

Commits follow Conventional Commits (`commitlint`, `husky`); releases and
`CHANGELOG.md` are generated by `semantic-release`, so don't edit the changelog by hand.
