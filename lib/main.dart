 // @dart-2.9
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:provider/provider.dart';
import 'colourPalette.dart';
 import 'package:permission_handler/permission_handler.dart';
//import 'BluetoothBLEService.dart';
//import 'BluetoothConnectionStateDTO.dart';
//import 'bluetoothConnectionState.dart';
import 'ble.dart';
import 'oggPiano.dart';
import 'groove.dart';
import 'bass.dart';
import 'saveAndLoad.dart';



 _launchURL() async {
   const url = 'https://happyfeet-music.com';
   if (await canLaunch(url)) {
     await launch(url);
   } else {
     throw 'Could not launch $url';
   }
 }

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

class _MyHomePageState extends State<MyHomePage> {
  Mode? _character = Mode.singleNote;
  String note1 = 'Bass Drum';
  int index1 = 0;
  String note2 = 'none';
  int index2 = -1;
  int sequenceCount = 0;
  Mode playMode = Mode.singleNote;
  String? playModeString = 'Single Note';
  bool _playState = false;
  bool _connectedState = false;
  static BluetoothBLEService _bluetoothBLEService = new BluetoothBLEService();

  Future<void> _checkPermission() async {
   final status = await Permission.locationWhenInUse.request();
    if (status == PermissionStatus.granted) {
      print('HF: Permission granted');
    } else if (status == PermissionStatus.denied) {
      print('HF: Permission denied. Show a dialog and again ask for the permission');
    } else if (status == PermissionStatus.permanentlyDenied) {
      print('HF: Take the user to the settings page.');
      await openAppSettings();
    }
  }


  @override
  initState() {
     oggpiano.init();

     // request needed permissions
     _checkPermission();

     // initialize BLE
    if (_bluetoothBLEService != null) {
      _bluetoothBLEService.init();
   }
    super.initState();
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

//        Text(bleStatusText(BleStatus), style: Theme.of(context).textTheme.caption),
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
                    if (_bluetoothBLEService.isBleConnected()) {
                      Get.snackbar('Error', 'already connected', snackPosition: SnackPosition.BOTTOM);
                    } else {
                      Get.snackbar('Status', 'connecting to Bluetooth', snackPosition: SnackPosition.BOTTOM);
                      _bluetoothBLEService.startConnection();
                    }
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
                  if (_bluetoothBLEService.isBleConnected()) {
                    Get.snackbar('Status', 'disconnecting Bluetooth', snackPosition: SnackPosition.BOTTOM);
                    _bluetoothBLEService.disconnectFromDevice();
                    _playState = false;
                  } else {
                    Get.snackbar('Error', 'not connected', snackPosition: SnackPosition.BOTTOM);
                  }
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
                    }
                    switch (newValue) {
                      case 'Single Note':
                        {
                          playMode = Mode.singleNote;
                          groove.resize(1,1);
                          groove.notes[0].oggIndex = index1;
                          groove.notes[0].name = note1;
                        }
                        break;
                      case 'Alternating Notes':
                        {
                          playMode = Mode.alternatingNotes;
                          groove.resize(2,1);
                          groove.notes[0].oggIndex = index1;
                          groove.notes[0].name = note1;
                          groove.notes[1].oggIndex = index2;
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
                        index1 = 0;
                      }
                      break;
                    case 'Kick Drum':
                      {
                        index1 = 1;
                      }
                      break;
                    case 'Snare Drum':
                      {
                        index1 = 2;
                      }
                      break;
                    case 'High Hat Cymbal':
                      {
                        index1 = 3;
                      }
                      break;
                    case 'Cowbell':
                      {
                        index1 = 4;
                      }
                      break;
                    case 'Tambourine':
                      {
                        index1 = 5;
                      }
                      break;
                    default:
                      {
                        index1 = -1;
                      }
                  }
                  groove.notes[0].oggIndex = index1;
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
                        index2 = -1;
                      }
                      break;
                    case 'Bass Drum':
                      {
                        index2 = 0;
                      }
                      break;
                    case 'Kick Drum':
                      {
                        index2 = 1;
                      }
                      break;
                    case 'Snare Drum':
                      {
                        index2 = 2;
                      }
                      break;
                    case 'High Hat Cymbal':
                      {
                        index2 = 3;
                      }
                      break;
                    case 'Cowbell':
                      {
                        index2 = 4;
                      }
                      break;
                    case 'Tambourine':
                      {
                        index2 = 5;
                      }
                      break;
                    default:
                      {
                        index2 = -1;
                      }
                  }
                  groove.notes[1].oggIndex = index2;
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
                     _bluetoothBLEService.disableBeat();
                     Get.snackbar('Status', 'beats disabled', snackPosition: SnackPosition.BOTTOM);
                   } else {
                     if (_bluetoothBLEService.isBleConnected()) {
                       // enable beats
                       _bluetoothBLEService.enableBeat();
                       Get.snackbar('Status', 'beats enabled', snackPosition: SnackPosition.BOTTOM);
                     } else {
                       Get.snackbar('Error', 'connect to Bluetooth first', snackPosition: SnackPosition.BOTTOM);
                     }
                    }
                   setState((){
                     if (_bluetoothBLEService.isBleConnected()) {
                       _playState = !_playState;
                     }
                   });
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
  var dropdownValue = groove.getInitials();

  @override
  initState() {
    super.initState();
    _beatsPerMeasure = groove.bpm;
    _numberOfMeasures = groove.numMeasures;
    _totalBeats = groove.bpm * groove.numMeasures;
    groove.checkType('percussion');
    groove.printGroove();
    dropdownValue = groove.getInitials();
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

          // Save groove
          Wrap(children: <Widget>[
            Row(children: <Widget>[
              TextButton(
                  child: Text('Save groove'),
                  onPressed: () {
                    Get.to(() => saveGroovePage);
                  }
              ),
            ]),
          ]),

          // load groove
          Wrap(children: <Widget>[
            Row(children: <Widget>[
              TextButton(
                  child: Text('Load groove'),
                  onPressed: () {
                    Get.to(() => loadGroovePage);
                  }
              ),
            ]),
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
   String? key = groove.key;
   List<String> dropdownValue = groove.getInitials();

   @override
   initState() {
     super.initState();
     _beatsPerMeasure = groove.bpm;
     _numberOfMeasures = groove.numMeasures;
     _totalBeats = groove.bpm * groove.numMeasures;
     key = groove.key;
     groove.checkType('bass');
     dropdownValue = groove.getInitials();
     print('HF: dropdownValue = $dropdownValue');
     groove.printGroove();
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
                       groove.key = newValue;
                       groove.changeKey(key);
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
                 // print a list of tones in the selected scale
                 Text('Scale tones: ' + scaleTones(key),
                   style: Theme.of(context).textTheme.caption,), // Text
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

               // Save groove
               Wrap(children: <Widget>[
                     Row(children: <Widget>[
                        TextButton(
                           child: Text('Save groove'),
                           onPressed: () {
                             Get.to(() => saveGroovePage);
                           }
                        ),
                    ]),
               ]),

               // load groove
               Wrap(children: <Widget>[
                 Row(children: <Widget>[
                   TextButton(
                       child: Text('Load groove'),
                       onPressed: () {
                         Get.to(() => loadGroovePage);
                       }
                   ),
                 ]),
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
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  Future<String?>? modelNumber;

  @override
  initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  Widget _infoTile(String title, String subtitle) {
   return ListTile(
     title: Text(title),
     subtitle: Text(subtitle.isEmpty ? 'Not set' : subtitle),
   );
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
//              _infoTile('App name', _packageInfo.appName),
//              _infoTile('Package name', _packageInfo.packageName),
              _infoTile('App version', _packageInfo.version),
//              _infoTile('Build number', _packageInfo.buildNumber),
            Row(children: <Widget>[
              ElevatedButton(
                child: Text('Read model number'),
                onPressed: () {
//                  modelNumber = _bluetoothBLEService?.readModelNumber();
//                   _bluetoothBLEService?.readWhoAmI();
                }
              ),
//              Text(modelNumber),
               Text('???'),
            ]),
           Row(children: <Widget>[
             ElevatedButton(
               onPressed: _launchURL,
               child: new Text('Show HappyFeet homepage'),
             ),
           ],)
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

 // save groove page
 SaveGroovePage saveGroovePage = new SaveGroovePage();

 // Stateful version of saveGroovePage page
 class SaveGroovePage extends StatefulWidget {
   @override
   _SaveGroovePageState createState() => _SaveGroovePageState();
 }

 class _SaveGroovePageState extends State<SaveGroovePage> {
   final TextEditingController _filenameController = TextEditingController();
   final TextEditingController _descriptionController = TextEditingController();

   @override
   initState() {
     super.initState();
     _filenameController.addListener(() {
       final String text = _filenameController.text.toLowerCase();
       _filenameController.value = _filenameController.value.copyWith(
         text: text,
         selection:
         TextSelection(baseOffset: text.length, extentOffset: text.length),
         composing: TextRange.empty,
       );
     });
     _descriptionController.addListener(() {
       final String text = _descriptionController.text;
       _descriptionController.value = _descriptionController.value.copyWith(
         text: text,
         selection:
         TextSelection(baseOffset: text.length, extentOffset: text.length),
         composing: TextRange.empty,
       );
     });
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text("Happy Feet - Save Groove"),
       ),
       body: Container(
         alignment: Alignment.center,
         padding: const EdgeInsets.all(6),
         child: ListView(
             children: <Widget>[
               Column(
                 crossAxisAlignment : CrossAxisAlignment.start,
                 children: <Widget>[
                   Text('Enter groove name: ',
                       style: Theme.of(context).textTheme.caption,),
                   TextFormField(
                       controller: _filenameController,
                       textCapitalization: TextCapitalization.none,
                       inputFormatters: [new FilteringTextInputFormatter(RegExp("[a-z0-9_]"), allow: true)],
                       validator: (value) {
                         if (value == null || value.isEmpty) {
                           Get.snackbar('Missing or invalid file name:',
                               'Please enter a file name with only letters, numbers and underscores.',
                               snackPosition: SnackPosition.BOTTOM);
                           return 'Please enter a file name';
                         } else {
                           return null;
                         }
                       },
                       decoration: const InputDecoration(border: OutlineInputBorder()),
                     ),
                   Text('Enter a description of the groove: ',
                     style: Theme.of(context).textTheme.caption,),
                   TextFormField(
                     controller: _descriptionController,
                     inputFormatters: [new FilteringTextInputFormatter(RegExp(","), allow: false)],
                     decoration: const InputDecoration(border: OutlineInputBorder()),
                   ),
                     ElevatedButton(
                         child: Text('Save groove'),
                         onPressed: () {
                           grooveStorage.writeGroove(_filenameController.text, _descriptionController.text);
                           Get.snackbar('Status:','groove saved', snackPosition: SnackPosition.BOTTOM);
                           // go back to previous screen
                           // go back to previous screen
                           switch(groove.type) {
                             case GrooveType.percussion: {
                               Get.to(() => groovePage);
                               break;
                             }
                             case GrooveType.bass: {
                               Get.to(() => bassPage);
                               break;
                             }
                             default: {
                               Get.to(() => groovePage);
                               break;
                             }
                           }
                         }
                     ),
                   ]),
               ]),
             ),
       );
   }  // Widget
 } // class

 // load groove page
 LoadGroovePage loadGroovePage = new LoadGroovePage();

 // Stateful version of loadGroovePage page
 class LoadGroovePage extends StatefulWidget {
   @override
   _LoadGroovePageState createState() => _LoadGroovePageState();
 }

 class _LoadGroovePageState extends State<LoadGroovePage> {

   @override
   initState() {
     super.initState();
     grooveStorage.listofSavedGrooves();
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text("Happy Feet - Load Groove"),
       ),
       body: Center(
         child: ListView(
             children: <Widget>[
               Column(
                 children: <Widget>[
                   Text('Saved grooves: ',
                     style: Theme.of(context).textTheme.caption,),
                   Text(grooveStorage.grooveFileNames.toString(),
                     style: Theme.of(context).textTheme.caption,),
                   Expanded(
                     child: ListView.builder(
                       itemCount: grooveStorage.grooveFileNames.length,
                       itemBuilder: (BuildContext context, int index) {
                         return Text(grooveStorage.grooveFileNames[index].toString());
                       }
                     )
                   ),
                   Row(children: <Widget>[
                     ElevatedButton(
                         child: Text('Load groove'),
                         onPressed: () {
                           grooveStorage.readGroove('xxx');
                           Get.snackbar('Loaded groove', groove.description, snackPosition: SnackPosition.BOTTOM);
                           // go back to previous screen
                           switch(groove.type) {
                             case GrooveType.percussion: {
                               Get.to(() => groovePage);
                               break;
                             }
                             case GrooveType.bass: {
                               Get.to(() => bassPage);
                               break;
                             }
                             default: {
                               Get.to(() => groovePage);
                               break;
                             }
                           }
                         }
                     ),
                   ]),
                 ],
               ),
             ]),
       ),
     );
   }  // Widget
 } // class

