# happy_feet_app

This is the companion app to work with HappyFeet, the foot-mounted Bluetooth drum machine thingy!

See the [HappyFeet webpage](https://happyfeet-music.com) for more details.

This page gives an overview of the construction of the app.

## Main Packages Used
| Purpose  | Android package used | iOS package used |
|----------|----------------------|------------------|
| BLE interface | flutter_reactive_ble | flutter_blue <sup>1</sup> |
| audio player  | flutter_ogg_piano | soundpool <sup>2</sup> |

### Notes
1. flutter_reactive_ble did not work on iOS.  It would scan, connect and do writes but notifies did not work.
2. flutter_ogg_piano did not work for iOS.  Also tried audioplayers/audiocache for iOS but the latency was too long.  Even with soundpool,
   the latency is 70ms (on iPhone 6).

## BLE Interface

The app interfaces to HappyFeet over Bluetooth Low Energy (BLE) using a service called HappyFeet with these characteristics:

| Characteristic | Properties | Size | Usage |
|----------------|------------|------|-------|
| char 1 | read | 1 byte | battery voltage as percentage of 3.3V |
| char2 | read | 1 byte | used to show results of reading the accelerometer IC's whoAmI register, 'Y' for OK and 'N' for NOK |
| char3 | write | 1 byte | used to set beat detection threshold |
| char4 | notify | 1 byte | send beat information: heartbeat flag (bit 7), sequence number (bit 6), foot enable (bit 5)  |
| char6 | read, write | 1 byte | enable beats (bit 0), disconnect (bit 6), enable test mode (bit 7) |

### Notes
- the sequence number is a bit that toggles between 0 and 1 on each notify sent.  With this method, the app can tell if any notifies have been lost, 
  or at least if an odd number of notifies have been lost.  In future, this could be expanded to be a multi-bit value which would 
  give better detection.
- the heartbeat flag indicates that this notify is a regular heartbeat used to keep the BLE connection alive.  Heartbeats are sent every 5s
  if no beats are happening.
- the enable beats flag turns on (1) and off (0) the sending of notifies.
- the disconnect bit causes a BLE disconnect when set to 1.  This is currently not used since it would not re-connect after disconnecting using this method.
- the enable test mode flag turns on (1) and off (0) a test mode.  When test mode is enabled, Happy Feet will send a notify every 500ms regardless
  of the detection of actual beats.
- the beat detection threshold is a...

## Wishlist
- cloud storage/sharing of grooves
- lower latency audio on iOS
- OAD: over-air-download for HappyFeet firmware updates.  HappyFeet uses the Texas Instruments CC26xx family of BLE microcontrollers which do have
  software libraries to support OAD.  There is currently no Flutter package for TI OAD, although there are Android apps that do it. Also Nordic          Semiconductor has a Flutter package to update their micros.
  
