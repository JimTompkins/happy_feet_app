// @dart-2.9
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colourPalette.dart';
import 'BluetoothBLEService.dart';
import 'BluetoothConnectionStateDTO.dart';
import 'bluetoothConnectionState.dart';
import 'midi.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Happy Feet',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

enum Mode { singleNote, alternatingNotes, groove, unknown }

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final MidiUtils midi = new MidiUtils();
  Mode? _character = Mode.singleNote;
  String note1 = 'Bass Drum';
  int midiNote1 = 60;
  String note2 = 'none';
  int midiNote2 = 0;
  int sequenceCount = 0;
  Mode playMode = Mode.singleNote;
  String? playModeString = 'Single Note';
  bool _playState = false;
  static BluetoothBLEService? _bluetoothBLEService;
  late StreamSubscription<List<int>> _dataReadCharacteristicSubscription;

  @override
  initState() {
    // initialize MIDI
    midi.unmute();
    rootBundle.load("assets/sounds/acoust_kits_1-4.sf2").then((sf2) {
      midi.prepare(sf2, "acoust_kits_1-4.sf2");
    });
    // initialize BLE
    if (_bluetoothBLEService == null) {
      _bluetoothBLEService = new BluetoothBLEService();
    }
    // Waiting for connecting to bluetooth signal.
    _bluetoothBLEService!.connectionStateStream
        .listen(_handleBluetoothConnection);

    _bluetoothBLEService!.isDeviceBluetoothOn();

    super.initState();
  }

  void _handleBluetoothConnection(BluetoothConnectionStateDTO connectionState) {
    print('HF: connectionState: $connectionState');
    if (connectionState.bluetoothConnectionState ==
        BluetoothConnectionState.DEVICE_CONNECTED) {
    }

    if (_bluetoothBLEService != null) {
      print('HF: connectionState: got bluetooth!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet'),
      ),
      body: Column(children: <Widget>[
        // Bluetooth heading
        Wrap(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text('BLUETOOTH',
                  style:
                      TextStyle(color: Colors.black, height: 1, fontSize: 15))),
        ]),

        //row of buttons with text below each
        Row(children: <Widget>[
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: IconButton(
                  icon: Icon(
                    Icons.bluetooth_searching,
                  ),
                  iconSize: 50,
                  color: Colors.blue,
                  splashColor: Colors.purple,
                  onPressed: () {
                    // Start scanning and make connection
                    _bluetoothBLEService!.startConnection();
                  }),
            ),
            Text('Connect',
                style: TextStyle(color: Colors.blue, height: 1, fontSize: 15))
          ]),
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: IconButton(
                icon: Icon(
                  Icons.bluetooth_disabled,
                ),
                iconSize: 50,
                color: Colors.grey,
                splashColor: Colors.purple,
                onPressed: () {
                  // stop the BLE connection
                  _bluetoothBLEService!.disconnectFromDevice();
                },
              ),
            ),
            Text('Disconnect',
                style: TextStyle(color: Colors.grey, height: 1, fontSize: 15))
          ]),
        ]),

        // Mode heading
        Wrap(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text('MODE',
                  style:
                      TextStyle(color: Colors.black, height: 1, fontSize: 15))),
        ]),

        // Mode selection dropdown list
        Column(
          children: <Widget>[
            Row(children: <Widget>[
              Container(
                padding: EdgeInsets.all(5),
                alignment: Alignment.center,
                child: Text('Play mode',
                    style:
                        TextStyle(color: Colors.blue, height: 1, fontSize: 15)),
              ),
              DropdownButton<String>(
                value: playModeString,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.deepPurple),
                underline: Container(
                  height: 2,
                  color: Colors.deepPurpleAccent,
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    playModeString = newValue;
                    switch (newValue) {
                      case 'Single Note':
                        {
                          playMode = Mode.singleNote;
                        }
                        break;
                      case 'Alternating Notes':
                        {
                          playMode = Mode.alternatingNotes;
                        }
                        break;
                      case 'Groove':
                        {
                          playMode = Mode.groove;
                        }
                        break;
                      default:
                        {
                          playMode = Mode.unknown;
                        }
                    }
                  });
                },
                items: <String>['Single Note', 'Alternating Notes', 'Groove']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ]),
          ],
        ),

        // Notes heading
        Wrap(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text('NOTES',
                  style:
                      TextStyle(color: Colors.black, height: 1, fontSize: 15))),
        ]),

        // instrument dropdowns
        Column(children: <Widget>[
          // first instrument row: the text "1st note" followed by dropdown pick list
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text('1st note',
                  style:
                      TextStyle(color: Colors.blue, height: 1, fontSize: 15)),
            ),
            DropdownButton<String>(
              value: note1,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple),
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  note1 = newValue!;
                  switch (note1) {
                    case 'Bass Drum':
                      {
                        midiNote1 = 60;
                      }
                      break;
                    case 'Kick Drum':
                      {
                        midiNote1 = 59;
                      }
                      break;
                    case 'Snare Drum':
                      {
                        midiNote1 = 40;
                      }
                      break;
                    case 'High Hat Cymbal':
                      {
                        midiNote1 = 70;
                      }
                      break;
                    case 'Cowbell':
                      {
                        midiNote1 = 80;
                      }
                      break;
                    default:
                      {
                        midiNote1 = 81;
                      }
                  }
                });
              },
              items: <String>[
                'Bass Drum',
                'Kick Drum',
                'Snare Drum',
                'High Hat Cymbal',
                'Cowbell'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ]),

          // second instrument row: the text "2nd note" followed by dropdown pick list
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text('2nd note',
                  style:
                      TextStyle(color: Colors.blue, height: 1, fontSize: 15)),
            ),
            DropdownButton<String>(
              value: note2,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.deepPurple),
              underline: Container(
                height: 2,
                color: Colors.deepPurpleAccent,
              ),
              onChanged: (String? newValue) {
                setState(() {
                  note2 = newValue!;
                  switch (note2) {
                    case 'Bass Drum':
                      {
                        midiNote2 = 60;
                      }
                      break;
                    case 'Kick Drum':
                      {
                        midiNote2 = 59;
                      }
                      break;
                    case 'Snare Drum':
                      {
                        midiNote2 = 40;
                      }
                      break;
                    case 'High Hat Cymbal':
                      {
                        midiNote2 = 70;
                      }
                      break;
                    case 'Cowbell':
                      {
                        midiNote2 = 80;
                      }
                      break;
                    default:
                      {
                        midiNote2 = 81;
                      }
                  }
                });
              },
              items: <String>[
                'none',
                'Bass Drum',
                'Kick Drum',
                'Snare Drum',
                'High Hat Cymbal',
                'Cowbell'
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ]),
        ]),

        // Play/pause button
        Wrap(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: FloatingActionButton(
                onPressed: (){
                  setState((){ _playState = !_playState;});
                   if (_playState) {
                     // disable beats
                     _bluetoothBLEService?.disableBeat();
                   } else {
                     // enable beats
                     _bluetoothBLEService?.enableBeat();
                   }

                   if (playMode == Mode.singleNote) {
                    midi.play(midiNote1);
                  } else if (playMode == Mode.alternatingNotes) {
                    if (sequenceCount.isEven) {
                      midi.play(midiNote1);
                    } else {
                      if (note2 != 'none') {
                        midi.play(midiNote2);
                      }
                    }
                    sequenceCount++;
                  }
                },   //onPressed
                tooltip: 'Enable beats',
                child: _playState?new Icon(Icons.pause):new Icon(Icons.play_circle_fill),
                ),
              ),
          ],
        ),
      ]),
    );
  } // widget
} // class

// Groove page

// Stateful version of groove page
class GroovePage extends StatefulWidget {
  @override
  _GroovePageState createState() => _GroovePageState();
}

class _GroovePageState extends State<GroovePage> {
  int _beatsPerMeasure = 1;
  int _numberOfMeasures = 1;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Happy Feet - Grooves"),
      ),
      body: Column(
        children: <Widget>[
          // Define a groove heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text('DEFINE GROOVE',
                    style: TextStyle(
                        color: Colors.blue, height: 1, fontSize: 15))),
          ]),

          // beats per measure slider
          Column(children: <Widget>[
            Row(children: <Widget>[
              Text('Beats per measure',
                  style: TextStyle(
                      color: Colors.blue, height: 1, fontSize: 15) // TextStyle
                  ), // Text
              Slider(
                value: _beatsPerMeasure.toDouble(),
                min: 1,
                max: 8,
                divisions: 8,
                label: _beatsPerMeasure.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _beatsPerMeasure = value.toInt();
                  });
                }, // setState, onChanged
              ), // Slider
            ]), // Row
            Row(children: <Widget>[
              Text('Number of measures',
                  style: TextStyle(
                      color: Colors.blue, height: 1, fontSize: 15) // TextStyle
                  ), // Text
              Slider(
                value: _numberOfMeasures.toDouble(),
                min: 1,
                max: 8,
                divisions: 8,
                label: _numberOfMeasures.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _numberOfMeasures = value.toInt();
                  });
                }, // setState, onChanged
              ), // Slider
            ]), // Row
          ]), // Column

          // Save groove heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text('SAVE GROOVE',
                    style: TextStyle(
                        color: Colors.blue, height: 1, fontSize: 15))),
          ]),

          // load groove heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text('LOAD GROOVE',
                    style: TextStyle(
                        color: Colors.blue, height: 1, fontSize: 15))),
          ]),
        ],
      ),
    );
  }
} // class


