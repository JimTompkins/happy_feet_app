# happy_feet_app

This is the companion app to work with HappyFeet, the foot-mounted Bluetooth drum machine thingy!

See the [HappyFeet webpage](https://happyfeet-music.com) for more details.

This page gives an overview of the construction of the app.

## Main Packages Used
| Purpose  | Android package used | iOS package used |
|----------|----------------------|------------------|
| audio player  | flutter_ogg_piano | soundpool <sup>1</sup> |

flutter_blue_plus is used for the BLE interface.

The BASS audio library from un4seen Developments is used for audio.  It is wrapped in a Flutter package called flutter_bass.  Note that BASS is a commercial product with licensing requirements.  See un4seen's website for details.  Prior to using BASS, we tried several audio packages:

- flutter_ogg_piano worked well for Android but does not have an implementation for iOS.  
- audioplayers/audiocache worked for iOS but the latency was too long (>200ms)
- soundpool had better latency (70ms on iPhone 6) but still not acceptable

## BLE Interface

The app interfaces to HappyFeet over Bluetooth Low Energy (BLE) using a service called HappyFeet with these characteristics:

| Characteristic | Properties | Size | Usage |
|----------------|------------|------|-------|
| char 1 | read | 1 byte | battery voltage as percentage of 3.3V |
| char2 | read | 1 byte | used to show results of reading the accelerometer IC's whoAmI register, 'Y' for OK and 'N' for NOK |
| char3 | write | 1 byte | used to set beat detection threshold |
| char4 | notify | 1 byte | send beat information: heartbeat flag (bit 7), sequence number (bit 6), foot enable (bit 5)  |
| char6 | read, write | 1 byte | enable beats (bit 0), foot-tapping style (bit 1), disconnect (bit 6), enable test mode (bit 7) |

### Notes
- the sequence number is a bit that toggles between 0 and 1 on each notify sent.  With this method, the app can tell if any notifies have been lost, 
  or at least if an odd number of notifies have been lost.  In future, this could be expanded to be a multi-bit value which would 
  give better detection.
- the heartbeat flag indicates that this notify is a regular heartbeat used to keep the BLE connection alive.  Heartbeats are sent every 5s
  if no beats are happening.
- the enable beats flag turns on (1) and off (0) the sending of notifies.
- the foot-tapping style bit tells the embedded hardware to assume either toe-tapping (0, the default) or
  heel-tapping (1).
- the disconnect bit causes a BLE disconnect when set to 1.  This is currently not used since it would not re-connect after disconnecting using this method.
- the enable test mode flag turns on (1) and off (0) a test mode.  When test mode is enabled, Happy Feet will send a notify every 500ms regardless
  of the detection of actual beats.
- the beat detection threshold is a...

## Groove .csv format definition
Grooves are saved to and loaded from comma separated variable (CSV) files with
the fields defined as follows:
- 0 = groove format version
- 1 = description of groove
- 2 = beats per measure
- 3 = number of measures
- 4 = number of voices
- 5 = interpolate flag (0 = no interpolation, 1 = with interpolation)
- 6 = groove type e.g. percussion or bass
- 7 = key (only used for bass grooves)
- 8:6+BPM x measures x 3 = 1st voice notes
For each note, the following fields are used:
- number: the number reference of this note
- note name e.g. cowbell
- initial e.g. 'c' for cowbell
A similar list is provided for the 2nd note voices:
- ??:??+BPM x measures x 3 = 2nd voice notes

## Wishlist
- cloud storage/sharing of grooves
- lower latency audio on iOS.  This was improved greatly by changing the audio engine to the 
BASS library from un4seen developments.
- OAD: over-air-download for HappyFeet firmware updates.  HappyFeet uses the Texas Instruments CC26xx family of BLE microcontrollers which do have
  software libraries to support OAD.  There is currently no Flutter package for TI OAD, although there are Android apps that do it. Also Nordic          Semiconductor has a Flutter package to update their micros.
  
