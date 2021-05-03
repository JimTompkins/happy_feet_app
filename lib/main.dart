// @dart-2.9
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'colourPalette.dart';
import 'BluetoothBLEService.dart';
import 'BluetoothConnectionStateDTO.dart';
import 'bluetoothConnectionState.dart';
import 'midi.dart';
import 'groove.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Happy Feet',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.deepOrange[500],
        accentColor: Colors.blue[400],
        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headline1: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.bold),
          caption: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.normal),
          headline4: TextStyle(
              color: Colors.grey[700],
              fontSize: 15,
              height: 1,
              fontWeight: FontWeight.normal),
      ),),
      home: MyHomePage(),
    );
  }
}

enum Mode { singleNote, alternatingNotes, groove, unknown }

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

//
class _MyHomePageState extends State<MyHomePage> {
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
      print("HF: Bluetooth device connected.");
    }

    if (_bluetoothBLEService != null) {
      print('HF: connectionState: got bluetooth service!');
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
                  style: Theme.of(context).textTheme.headline1,
              )),
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
                  color: myColour,
                  splashColor: Colors.purple,
                  onPressed: () {
                    // Start scanning and make connection
                    _bluetoothBLEService!.startConnection();
                  }),
            ),
            Text('Connect',
              style: Theme.of(context).textTheme.caption,)
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
              style: Theme.of(context).textTheme.caption,)
          ]),
        ]),

        // Mode heading
        Wrap(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text('MODE',
                 style: Theme.of(context).textTheme.headline1,    )),
        ]),

        // Mode selection dropdown list
        Column(
          children: <Widget>[
            Row(children: <Widget>[
              Container(
                padding: EdgeInsets.all(5),
                alignment: Alignment.center,
                child: Text('Play mode',
                  style: Theme.of(context).textTheme.caption,),
              ),
              DropdownButton<String>(
                value: playModeString,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 24,
                style: Theme.of(context).textTheme.headline4,
                onChanged: (String? newValue) {
                  setState(() {
                    playModeString = newValue;
                    switch (newValue) {
                      case 'Single Note':
                        {
                          playMode = Mode.singleNote;
                          groove.resize(1,1);
                          groove.notes[0].midi = midiNote1;
                          groove.notes[0].name = note1;
                        }
                        break;
                      case 'Alternating Notes':
                        {
                          playMode = Mode.alternatingNotes;
                          groove.resize(2,1);
                          groove.notes[0].midi = midiNote1;
                          groove.notes[0].name = note1;
                          groove.notes[1].midi = midiNote2;
                          groove.notes[1].name = note2;
                        }
                        break;
                      case 'Groove':
                        {
                          playMode = Mode.groove;
                          Get.to(() => groovePage);
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
                style: Theme.of(context).textTheme.headline1,
              )),
        ]),

        // instrument dropdowns
        Column(children: <Widget>[
          // first instrument row: the text "1st note" followed by dropdown pick list
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text('1st note',
                style: Theme.of(context).textTheme.caption,),
            ),
            DropdownButton<String>(
              value: note1,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 24,
              style: Theme.of(context).textTheme.headline4,
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
                  groove.notes[0].midi = midiNote1;
                  groove.notes[0].name = note1;
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
                style: Theme.of(context).textTheme.caption,),
            ),
            DropdownButton<String>(
              value: note2,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 24,
              style: Theme.of(context).textTheme.headline4,
              onChanged: (String? newValue) {
                setState(() {
                  note2 = newValue!;
                  switch (note2) {
                    case 'none':
                      {
                        midiNote2 = 0;
                      }
                      break;
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
                  groove.notes[1].midi = midiNote2;
                  groove.notes[1].name = note2;
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
                },   //onPressed
                tooltip: 'Enable beats',
                child: _playState?
                   new Icon(Icons.pause, size: 25, color: Theme.of(context).primaryColor):
                   new Icon(Icons.play_circle_fill, size: 25, color: Theme.of(context).primaryColor),
                ),
              ),
          ],
        ),
      ]),
    );
  } // widget
} // class

// Groove page
GroovePage groovePage = new GroovePage();

// Stateful version of groove page
class GroovePage extends StatefulWidget {
  @override
  _GroovePageState createState() => _GroovePageState();
}

class _GroovePageState extends State<GroovePage> {
  int _beatsPerMeasure = 4;
  int _numberOfMeasures = 2;
  int _totalBeats = 8;
  List<String> dropdownValue = ['-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', '-', ];

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
      body: Center(
         child: ListView(
        children: <Widget>[
          // Define a groove heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text('DEFINE GROOVE',
                  style: Theme.of(context).textTheme.headline1,
                )),
          ]),

          // sliders for number of beats per measure and measures
          Column(children: <Widget>[
            Row(children: <Widget>[
              Text('Beats per measure',
                style: Theme.of(context).textTheme.caption,), // Text
              Slider(
                value: _beatsPerMeasure.toDouble(),
                min: 1,
                max: 8,
                divisions: 8,
                label: _beatsPerMeasure.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _beatsPerMeasure = value.toInt();
                    groove.resize(_beatsPerMeasure, _numberOfMeasures);
                    _totalBeats = _beatsPerMeasure * _numberOfMeasures;
                  });
                }, // setState, onChanged
              ), // Slider
            ]), // Row
            Row(children: <Widget>[
              Text('Number of measures',
                style: Theme.of(context).textTheme.caption,), // Text
              Slider(
                value: _numberOfMeasures.toDouble(),
                min: 1,
                max: 8,
                divisions: 8,
                label: _numberOfMeasures.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _numberOfMeasures = value.toInt();
                    groove.resize(_beatsPerMeasure, _numberOfMeasures);
                    _totalBeats = _beatsPerMeasure * _numberOfMeasures;
                  });
                }, // setState, onChanged
              ), // Slider
            ]), // Row
          ]), // Column

          // beat grid

          GridView.count(
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            primary: false,
            padding: const EdgeInsets.all(1),
            crossAxisSpacing: 1,
            mainAxisSpacing: 1,
            crossAxisCount: _beatsPerMeasure,
            children: List.generate(_totalBeats,(index) {
                return Center(
                   child: DropdownButton<String>(
                   value: dropdownValue[index],
                   onChanged: (String? newValue) {
                      setState(() {
                         groove.addInitialNote(index, newValue!);
                         dropdownValue[index] = newValue;
                      });
                   },
                   items: <String>['-','B', 'K', 'S', 'H', 'C']
                     .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                         value: value,
                         child: Text(value),
                         );
                      }).toList(),
                ) // DropdownButton
                ); // Center
             },) // List.generate
          ),   // GridView

          // Save groove heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text('SAVE GROOVE',
                  style: Theme.of(context).textTheme.headline1,
                )),
          ]),

          // load groove heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text('LOAD GROOVE',
                  style: Theme.of(context).textTheme.headline1,
                )),
          ]),  // Widget, wrap
        ],  // Widget
      ), // Listview
    ));
  }
} // class


