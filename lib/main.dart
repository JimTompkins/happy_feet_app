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
import 'bass.dart';

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
//        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headline1: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.bold),
          caption: TextStyle(
              color: Theme.of(context).accentColor,
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.normal),
          headline4: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.normal),
      ),),
      home: MyHomePage(),
    );
  }
}

enum Mode { singleNote, alternatingNotes, groove, bass, unknown }

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
        leading: GestureDetector(
          onTap: () {
            Get.to(() => menuPage);
            },
          child: Icon(
            Icons.menu,  // add custom icons also
          ),
        ),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => infoPage);
                },
                child: Icon(
                    Icons.more_vert
                ),
              )
          ),
        ],
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
                  _playState = false;
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
                    // if changing back from bass mode to another other mode...
                    if (newValue != 'Bass' && playMode == Mode.bass) {
                      // ...reload the drumkit sf2 file
                      rootBundle.load("assets/sounds/acoust_kits_1-4.sf2").then((sf2) {
                        midi.prepare(sf2, "acoust_kits_1-4.sf2");
                      });
                    }
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
                          if (playMode != Mode.groove) {
                            groove.clearNotes();
                          }
                          playMode = Mode.groove;
                          Get.to(() => groovePage);
                        }
                        break;
                      case 'Bass':
                        {
                          if (playMode != Mode.bass) {
                            rootBundle.load("assets/sounds/bass.sf2").then((sf2) {
                              midi.prepare(sf2, "bass.sf2");
                            });
                            groove.clearNotes();
                          }
                          playMode = Mode.bass;
                          Get.to(() => bassPage);
                        }
                        break;
                      default:
                        {
                          playMode = Mode.unknown;
                        }
                    }
                  });
                },
                items: <String>['Single Note', 'Alternating Notes', 'Groove', 'Bass']
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
                    case 'Tambourine':
                      {
                        midiNote1 = 78;
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
                'Cowbell',
                'Tambourine'
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
                    case 'Tambourine':
                      {
                        midiNote2 = 78;
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
                'Cowbell',
                'Tambourine',
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
                foregroundColor: Theme.of(context).accentColor,
                elevation: 25,
                onPressed: (){
                   if (_playState) {
                     // disable beats
                     _bluetoothBLEService?.disableBeat();
                   } else {
                     // enable beats
                     _bluetoothBLEService?.enableBeat();
                   }
                   setState((){ _playState = !_playState;});
                },   //onPressed
                tooltip: 'Enable beats',
                child: _playState?
                   new Icon(Icons.pause, size: 50, color: Theme.of(context).primaryColor):
                   new Icon(Icons.music_note_outlined, size: 50, color: Theme.of(context).primaryColor),
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
  int _beatsPerMeasure = groove.bpm;
  int _numberOfMeasures = groove.numMeasures;
  int _totalBeats = groove.bpm * groove.numMeasures;
  final dropdownValue = groove.getInitials();

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
              Text('Beats/measure',
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
              Text('Measures',
                style: Theme.of(context).textTheme.caption,), // Text
              Slider(
                value: _numberOfMeasures.toDouble(),
                min: 1,
                max: 12,   // for 12 bar blues!
                divisions: 12,
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
          Text(' Choose "-" for no note, B for bass drum, K for kick drum, S for snare drum, H for hi-hat cymbal, T for tambourine, C for cowbell ',
            style: Theme.of(context).textTheme.caption,), // Text

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
                  child: Container(
                    decoration: new BoxDecoration(
                      border: Border.all(width: 1.0)
                    ),
                   child: DropdownButton<String>(
                   value: dropdownValue[index],
                   elevation: 24,
                   onChanged: (String? newValue) {
                      setState(() {
                         groove.addInitialNote(index, newValue!);
                         dropdownValue[index] = newValue;
                      });
                   },
                   items: <String>['-','B', 'K', 'S', 'H', 'T', 'C']
                     .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                         value: value,
                         child: Text(value),
                         );
                      }).toList(),
                ),
                  ),
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

 // Bass page
 BassPage bassPage = new BassPage();

 // Stateful version of bass page
 class BassPage extends StatefulWidget {
   @override
   _BassPageState createState() => _BassPageState();
 }

 class _BassPageState extends State<BassPage> {
   int _beatsPerMeasure = groove.bpm;
   int _numberOfMeasures = groove.numMeasures;
   int _totalBeats = groove.bpm * groove.numMeasures;
   String? key = 'E';
   final dropdownValue = groove.getInitials();

   @override
   initState() {
     super.initState();
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
         appBar: AppBar(
           title: Text("Happy Feet - Bass"),
         ),
         body: Center(
           child: ListView(
             children: <Widget>[
               // Define a groove heading
               Wrap(children: <Widget>[
                 Container(
                     padding: EdgeInsets.all(10),
                     alignment: Alignment.centerLeft,
                     child: Text('DEFINE BASS GROOVE',
                       style: Theme.of(context).textTheme.headline1,
                     )),
               ]),

               // sliders for number of beats per measure and measures
               Column(children: <Widget>[
                 Row(children: <Widget>[
                   Text(' Beats/measure',
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
                   Text(' Measures',
                     style: Theme.of(context).textTheme.caption,), // Text
                   Slider(
                     value: _numberOfMeasures.toDouble(),
                     min: 1,
                     max: 12,   // for 12 bar blues!
                     divisions: 12,
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
               // key dropdown
               Row(children: <Widget>[
                 Text(' Key of ',
                   style: Theme.of(context).textTheme.caption,), // Text
                 DropdownButton<String>(
                   value: key,
                   icon: const Icon(Icons.arrow_downward),
                   iconSize: 24,
                   elevation: 24,
                   style: Theme.of(context).textTheme.headline4,
                   onChanged: (String? newValue) {
                     setState(() {
                       key = newValue;
                     });
                   },
                   items: <String>['E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B',
                     'C', 'C#', 'D', 'D#'].map<DropdownMenuItem<String>>((String value) {
                     return DropdownMenuItem<String>(
                       value: value,
                       child: Text(value),
                     );
                   }).toList(),
                 ),
               ]),
               ]), // Column

               // beat grid
               Text(' Choose "-" for no note, or Roman numerals I through VII for scale tones ',
                 style: Theme.of(context).textTheme.caption,), // Text

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
                         child: Container(
                            decoration: new BoxDecoration(
                               border: Border.all(width: 1.0)
                               ),
                         child: DropdownButton<String>(
                           value: dropdownValue[index],
                           elevation: 24,
                           onChanged: (String? newValue) {
                             setState(() {
                               groove.addBassNote(index, newValue!, key);
                               dropdownValue[index] = newValue;
                             });
                           },
                           items: <String>['-', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'].map<DropdownMenuItem<String>>((String value) {
                             return DropdownMenuItem<String>(
                               value: value,
                               child: Text(value),
                             );
                           }).toList(),
                         ) // DropdownButton
                       ),
                     );// Center
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

// info page
InfoPage infoPage = new InfoPage();

// Stateful version of Info page
class InfoPage extends StatefulWidget {
  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
 String modelNumber = '';

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text("Happy Feet - Info Menu"),
    ),
    body: Center(
      child: ListView(
        children: <Widget>[
        Column(
          children: <Widget>[
            Row(children: <Widget>[
              TextButton(
                child: Text('Read model number'),
                onPressed: () {
                  //modelNumber = _bluetoothBLEService?.readModelNumber();
                  modelNumber = 'model number';
                }
              ),
              Text(modelNumber),
            ]),
          ],
        ),
      ]),
    ),
    );
  }  // Widget
} // class


// menu page
MenuPage menuPage = new MenuPage();

// Stateful version of menu page
class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _detectionThreshold = 128;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Happy Feet - Config Menu"),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Text('Detection threshold',
                style: Theme.of(context).textTheme.caption,), // Text
              Slider(
                value: _detectionThreshold.toDouble(),
                min: 1,
                max: 255,
                divisions: 255,
                label: _detectionThreshold.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _detectionThreshold = value.toInt();
                    //_bluetoothBLEService?.writeThreshold(_detectionThreshold & 0xFF);
                  });
                }, // setState, onChanged
              ), // Slider
            ]), // Row
          ]), // Column
        ]),
        ),
      );
  }  // Widget
} // class

