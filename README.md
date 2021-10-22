# happy_feet_app

This is the companion app to work with Happy Feet, the foot-mounted Bluetooth drum machine thingy!

See the [Happy Feet webpage](https://happyfeet-music.com) for more details.

This page gives an overview of the construction of the app.

## Packages Used
| Purpose  | Android package used | iOS package used |
|----------|----------------------|------------------|
| BLE interface | flutter_reactive_ble | flutter_blue |
| audio player  | flutter_ogg_piano | soundpool |

## BLE Interface

The app interfaces to Happy Feet over Bluetooth Low Energy (BLE) using a service called HappyFeet with these characteristics:

| Characteristic | Properties | Size | Usage |
|----------------|------------|------|-------|
| char3 | write | 1 byte | used to set beat detection threshold |
| char4 | notify | 1 byte | send beat information: sequence number (bit 6), heartbeat flag (bit 7) |
| char6 | read, write | 1 byte | enable beats (bit 0), enable test mode (bit 7) |

