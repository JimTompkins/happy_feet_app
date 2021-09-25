import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble.dart';
import 'audio.dart';
import 'groove.dart';
import 'bass.dart';
import 'saveAndLoad.dart';
import 'localization.g.dart';

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
        secondaryHeaderColor: Colors.blue[400],
//        accentColor: Colors.blue[400],
//        fontFamily: 'Roboto',
        textTheme: TextTheme(
          headline1: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 20,
              height: 1,
              fontWeight: FontWeight.bold),
          caption: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.normal),
          headline2: TextStyle(
              color: Colors.blue[400],
              fontSize: 16,
              height: 1,
              fontWeight: FontWeight.normal),
          headline3: TextStyle(
              color: Colors.deepOrange[500],
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
      locale: Get.deviceLocale,
      fallbackLocale: Locale('en', 'US'),
      translations: Localization(),
    );
  }
}

enum Mode { singleNote, alternatingNotes, dualNotes, groove, bass, unknown }

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class MyBool {
   bool x = false;

   MyBool(bool val) {
     x = val;
   }
}

class _MyHomePageState extends State<MyHomePage> {
  String note1 = 'Bass drum';
  int index1 = 0;
  String note2 = 'none';
  int index2 = -1;
  int sequenceCount = 0;
  Mode playMode = Mode.singleNote;
  String? playModeString = 'Single Note';
  MyBool _playState = Get.put(MyBool(false));
  static BluetoothBLEService _bluetoothBLEService = Get.put(BluetoothBLEService());

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
     hfaudio.init();

     groove.initSingle(note1);

     // request needed permissions
     _checkPermission();

     // initialize BLE
    _bluetoothBLEService.init();

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
        floatingActionButton: FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 25,
          onPressed: (){
            if (_playState.x) {
              // disable beats
              _bluetoothBLEService.disableBeat();
              Get.snackbar('Status', 'beats disabled', snackPosition: SnackPosition.BOTTOM);
            } else {
              if (_bluetoothBLEService.isBleConnected()) {
                // enable beats
                groove.reset();
                _bluetoothBLEService.enableBeat();
//                       _bluetoothBLEService.enableTestMode();
                Get.snackbar('Status', 'beats enabled', snackPosition: SnackPosition.BOTTOM);
              } else {
                Get.snackbar('Error', 'connect to Bluetooth first', snackPosition: SnackPosition.BOTTOM);
              }
            }
            setState((){
              if (_bluetoothBLEService.isBleConnected()) {
                _playState.x = !_playState.x;
              }
            });
          },   //onPressed
          tooltip: 'Enable beats'.tr,
          child: _playState.x?
          new Icon(Icons.pause, size: 50, color: Theme.of(context).primaryColor):
          new Icon(Icons.music_note_outlined, size: 50, color: Theme.of(context).primaryColor),
        ),
      body:
          ListView(children: <Widget>[
        Column(children: <Widget>[
        // Bluetooth heading
        Wrap(children: <Widget>[
          Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text('BLUETOOTH'.tr,
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
              child: Obx(()=>
                  IconButton(
                  icon: Icon(
                    Icons.bluetooth_searching,
                  ),
                  iconSize: 50,
                  color: _bluetoothBLEService.isConnected.value? Colors.grey: Colors.deepOrange[400],
                  splashColor: Colors.purple,
                  onPressed: () {
                    // Start scanning and make connection
                    if (_bluetoothBLEService.isBleConnected()) {
                      Get.snackbar('Error'.tr, 'already connected'.tr, snackPosition: SnackPosition.BOTTOM);
                    } else {
                      Get.snackbar('Status'.tr, 'connecting to Bluetooth'.tr, snackPosition: SnackPosition.BOTTOM);
                      _bluetoothBLEService.startConnection();
                    }
                  }),
                  ),
            ),
            Text('Connect'.tr,
              style: Theme.of(context).textTheme.caption,)
          ]),
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Obx(()=>
              IconButton(
                icon: Icon(
                  Icons.bluetooth_disabled,
                ),
                iconSize: 50,
                color: _bluetoothBLEService.isConnected.value? Colors.deepOrange[400]: Colors.grey,
                splashColor: Colors.purple,
                onPressed: () {
                  // stop the BLE connection
                  if (_bluetoothBLEService.isBleConnected()) {
                    Get.snackbar('Status', 'disconnecting Bluetooth', snackPosition: SnackPosition.BOTTOM);
                    _bluetoothBLEService.disconnectFromDevice();
                    _playState.x = false;
                  } else {
                    Get.snackbar('Error', 'not connected', snackPosition: SnackPosition.BOTTOM);
                  }
                },
              ),
            ),),
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
                          groove.initSingle(note1);
                        }
                        break;
                      case 'Alternating Notes':
                        {
                          playMode = Mode.alternatingNotes;
                          groove.initAlternating(note1, note2);
                        }
                        break;
                      case 'Dual Notes':
                        {
                          playMode = Mode.dualNotes;
                          groove.initDual(note1, note2);
                        }
                        break;
                      case 'Groove':
                        {
                          groove.reset();
                          if (playMode != Mode.groove) {
                            groove.clearNotes();
                          }
                          playMode = Mode.groove;
                          Get.to(() => groovePage);
                        }
                        break;
                      case 'Bass':
                        {
                          groove.voices = 1;
                          groove.reset();
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
                    String text = groove.toCSV('after changing play mode');
                    print("HF: $text");
                  });
                },
                items: <String>['Single Note', 'Alternating Notes', 'Dual Notes', 'Groove', 'Bass']
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
                  switch (playMode) {
                    case Mode.singleNote:
                      groove.initSingle(note1);
                      break;
                    case Mode.alternatingNotes:
                      groove.initAlternating(note1, note2);
                      break;
                    case Mode.dualNotes:
                      groove.initDual(note1, note2);
                      break;
                    case Mode.groove:
                    case Mode.bass:
                    case Mode.unknown:
                    default:
                      break;
                  }
                  String text = groove.toCSV('after changing note 1');
                  print("HF: $text");
                });
              },
              items: <String>[
                'Bass drum',
                'Kick drum',
                'Snare drum',
                'Hi-hat cymbal',
                'Cowbell',
                'Tambourine',
                'Fingersnap',
                'Rim shot',
                'Shaker',
                'Woodblock',
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
                  switch (playMode) {
                    case Mode.singleNote:
                      groove.initSingle(note1);
                      break;
                    case Mode.alternatingNotes:
                      groove.initAlternating(note1, note2);
                      break;
                    case Mode.dualNotes:
                      groove.initDual(note1, note2);
                      break;
                    case Mode.groove:
                    case Mode.bass:
                    case Mode.unknown:
                    default:
                      break;
                  }
                  String text = groove.toCSV('after changing note 2');
                  print("HF: $text");

                });
              },
              items: <String>[
                'none',
                'Bass drum',
                'Kick drum',
                'Snare drum',
                'Hi-hat cymbal',
                'Cowbell',
                'Tambourine',
                'Fingersnap',
                'Rim shot',
                'Shaker',
                'Woodblock',
              ].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ]),
        ]),

      ]),

    ]),

      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Obx(()=> Text(groove.bpmString.value,
                style: TextStyle(color: Colors.white, fontSize: 40))),
            Obx(()=> Text(groove.indexString.value,
                style: TextStyle(color: Colors.white, fontSize: 40))),
          ],

        ),
        shape: CircularNotchedRectangle(),
        color: Colors.blue[400],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
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
  int _voices = groove.voices;
  bool _interpolate = groove.interpolate;
  var dropdownValue = groove.getInitials();
  static BluetoothBLEService _bluetoothBLEService = Get.find();
//  static bool _playState = Get.find();
  MyBool _playState = Get.find();

  @override
  initState() {
    super.initState();
    _beatsPerMeasure = groove.bpm;
    _numberOfMeasures = groove.numMeasures;
    _totalBeats = groove.bpm * groove.numMeasures * groove.voices;
    _voices = groove.voices;
    _interpolate = groove.interpolate;
    if (_interpolate) {
      groove.leadInCount = 4;
      print('HF: set lead-in counter to 4');
    } else { groove.leadInCount = 0; }
    groove.checkType('percussion');
    groove.printGroove();
    dropdownValue = groove.getInitials();
  }

  // return a colour to use for each gridview element based on its index
  // this is done to improve readability when entering notes into a groove.
  Color? noteColor(int index) {
    Color? _result;
    if (groove.voices == 1) {
      if ((index ~/ _beatsPerMeasure) & 0x01 == 0x01) {
        _result = Colors.blue[200];
      } else {
        _result = Colors.blue[400];
      }
    } else if (groove.voices == 2) {
      switch ((index ~/ _beatsPerMeasure) & 0x03) {
        case 0: _result = Colors.blue[400];
           break;
        case 1: _result = Colors.deepOrange[400];
          break;
        case 2: _result = Colors.blue[200];
          break;
        case 3: _result = Colors.deepOrange[200];
          break;
      }
    }
    // if in interpolate mode, use a separate colour for the back beats
    if (groove.interpolate && index.isOdd) {
       _result = Colors.deepPurple[200];
    }

    return _result;
  }

  @override
  Widget build(BuildContext context) {
//    dropdownValue = groove.getInitials();
    return Scaffold(
      appBar: AppBar(
        title: Text("Happy Feet - Grooves"),
      ),
        floatingActionButton: FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 25,
          onPressed: (){
            if (_playState.x) {
              // disable beats
              _bluetoothBLEService.disableBeat();
              Get.snackbar('Status', 'beats disabled', snackPosition: SnackPosition.BOTTOM);
            } else {
              if (_bluetoothBLEService.isBleConnected()) {
                // enable beats
                groove.reset();
                _bluetoothBLEService.enableBeat();
//                       _bluetoothBLEService.enableTestMode();
                Get.snackbar('Status', 'beats enabled', snackPosition: SnackPosition.BOTTOM);
              } else {
                Get.snackbar('Error', 'connect to Bluetooth first', snackPosition: SnackPosition.BOTTOM);
              }
            }
            setState((){
              if (_bluetoothBLEService.isBleConnected()) {
                _playState.x = !_playState.x;
              }
            });
          },   //onPressed
          tooltip: 'Enable beats',
          child: _playState.x?
          new Icon(Icons.pause, size: 50, color: Theme.of(context).primaryColor):
          new Icon(Icons.music_note_outlined, size: 50, color: Theme.of(context).primaryColor),
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
                    groove.resize(_beatsPerMeasure, _numberOfMeasures, _voices);
                    _totalBeats = _beatsPerMeasure * _numberOfMeasures * _voices;
                    print('HF: changing number of beats per measure, _beatsPerMeasure = $_beatsPerMeasure, _totalBeats = $_totalBeats');
                    dropdownValue = groove.getInitials();
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
                    groove.resize(_beatsPerMeasure, _numberOfMeasures, _voices);
                    _totalBeats = _beatsPerMeasure * _numberOfMeasures * _voices;
                    print('HF: changing number of measures, _numberOfMeasures = $_numberOfMeasures, _totalBeats = $_totalBeats');
                    dropdownValue = groove.getInitials();
                  });
                }, // setState, onChanged
              ), // Slider
            ]), // Row
            // radio buttons for number of voices
            Row(children:<Widget>[
              Text('Voices',
              style: Theme.of(context).textTheme.caption),
              Radio(
                value: 1,
                groupValue: _voices,
                activeColor: Colors.blue[400],
                onChanged: (val) {
                  setState(() {
                    _voices = 1;
                    groove.resize(_beatsPerMeasure, _numberOfMeasures, _voices);
                    _totalBeats = _beatsPerMeasure * _numberOfMeasures * _voices;
                    print('HF: changing to 1 voice, _totalBeats = $_totalBeats');
                    dropdownValue = groove.getInitials();
                  });
                },
              ),
              Text('1'),
              Radio(
                value: 2,
                groupValue: _voices,
                activeColor: Colors.deepOrange[500],
                onChanged: (val) {
                  setState(() {
                    _voices = 2;
                    groove.resize(_beatsPerMeasure, _numberOfMeasures, _voices);
                    _totalBeats = _beatsPerMeasure * _numberOfMeasures * _voices;
                    print('HF: changing to 2 voices, _totalBeats = $_totalBeats');
                    dropdownValue = groove.getInitials();
                  });
                },
              ),
              Text('2'),
              Text('  Backbeat',
                  style: Theme.of(context).textTheme.caption),
              Switch(
                value: _interpolate,
                onChanged: (value) {
                  setState(() {
                    // check if the number of beats per measure is even.  If not, open a snackbar
                    // and don't set interpolate mode
                    if (_beatsPerMeasure.isEven) {
                      _interpolate = value;
                      groove.interpolate = value;
                      if (value) { groove.leadInCount = 4; } // if changing to interpolate mode, add a 4 beat lead-in
                    } else {
                      Get.snackbar('Notice', 'back beat mode can only be used with even number of beats per measure.', snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                }
              ),
            ]
            )
          ]), // Column

          // beat grid
          Text(' Choose "-" for no note, B for bass drum, K for kick drum, S for snare drum, H for hi-hat cymbal, T for tambourine, C for cowbell, F for fingersnap, R for rim shot, A for shAker, W for woodblock ',
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
                      color: noteColor(index),
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
                   items: <String>['-','B', 'K', 'S', 'H', 'T', 'C', 'F', 'R', 'A', 'W']
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
              ElevatedButton(
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
              ElevatedButton(
                  child: Text('Load groove'),
                  onPressed: () {
                    Get.to(() => loadGroovePage);
                  }
              ),
            ]),
          ]),  // Widget, wrap
        ],  // Widget
      ), // Listview
    ),

      bottomNavigationBar: BottomAppBar(
    child: new Row(
    mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Obx(()=> Text(groove.bpmString.value,
            style: TextStyle(color: Colors.white, fontSize: 40))),
        Obx(()=> Text(groove.indexString.value,
            style: TextStyle(color: Colors.white, fontSize: 40))),
      ],

    ),
    shape: CircularNotchedRectangle(),
    color: Colors.blue[400],
    ),
    floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

    );
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
   String _key = groove.key;
   List<String> dropdownValue = groove.getInitials();
   static BluetoothBLEService _bluetoothBLEService = Get.find();
   MyBool _playState = Get.find();

   @override
   initState() {
     super.initState();
     _beatsPerMeasure = groove.bpm;
     _numberOfMeasures = groove.numMeasures;
     _totalBeats = groove.bpm * groove.numMeasures;
     _key = groove.key;
     groove.checkType('bass');
     dropdownValue = groove.getInitials();
     print('HF: dropdownValue = $dropdownValue');
     groove.printGroove();
   }

   // return a colour to use for each gridview element based on its index
   // this is done to improve readability when entering notes into a bass groove.
   Color? rowColor(int index) {
     return ((index ~/ _beatsPerMeasure)&0x01==0x01)? Colors.blue[200] : Colors.blue[400];
  }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
         appBar: AppBar(
           title: Text("Happy Feet - Bass"),
         ),
       floatingActionButton: FloatingActionButton(
         foregroundColor: Theme.of(context).colorScheme.secondary,
         elevation: 25,
         onPressed: (){
           if (_playState.x) {
             // disable beats
             _bluetoothBLEService.disableBeat();
             Get.snackbar('Status', 'beats disabled', snackPosition: SnackPosition.BOTTOM);
           } else {
             if (_bluetoothBLEService.isBleConnected()) {
               // enable beats
               groove.reset();
               _bluetoothBLEService.enableBeat();
               Get.snackbar('Status', 'beats enabled', snackPosition: SnackPosition.BOTTOM);
             } else {
               Get.snackbar('Error', 'connect to Bluetooth first', snackPosition: SnackPosition.BOTTOM);
             }
           }
           setState((){
             if (_bluetoothBLEService.isBleConnected()) {
               _playState.x = !_playState.x;
             }
           });
         },   //onPressed
         tooltip: 'Enable beats',
         child: _playState.x?
         new Icon(Icons.pause, size: 50, color: Theme.of(context).primaryColor):
         new Icon(Icons.music_note_outlined, size: 50, color: Theme.of(context).primaryColor),
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
                         groove.resize(_beatsPerMeasure, _numberOfMeasures, 1);
                         dropdownValue = groove.getInitials();
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
                         groove.resize(_beatsPerMeasure, _numberOfMeasures, 1);
                         dropdownValue = groove.getInitials();
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
                   value: _key,
                   icon: const Icon(Icons.arrow_downward),
                   iconSize: 24,
                   elevation: 24,
                   style: Theme.of(context).textTheme.headline4,
                   onChanged: (String? newValue) {
                     setState(() {
                       _key = newValue!;
                       groove.changeKey(_key);
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

               // print a list of tones in the selected scale
               Text('Tones: ' + scaleTones(_key),
                 style: Theme.of(context).textTheme.caption,), // Text

               // beat grid
               Text(' Choose "-" for no note, or Roman numerals I through VII plus flats for tones ',
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
                               color: rowColor(index),
                               border: Border.all(width: 1.0)
                               ),
                         child: DropdownButton<String>(
                           value: dropdownValue[index],
                           elevation: 24,
                           onChanged: (String? newValue) {
                             setState(() {
                               groove.addBassNote(index, newValue!, _key);
                               dropdownValue[index] = newValue;
                             });
                           },
//                           items: <String>['-', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'].map<DropdownMenuItem<String>>((String value) {
                             items: <String>['-', 'I', 'bII', 'II', 'bIII', 'III', 'IV', 'bV','V', 'bVI', 'VI', 'bVII', 'VII'].map<DropdownMenuItem<String>>((String value) {
                             return DropdownMenuItem<String>(
                               value: value,
                               child: Text(value)
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
                        ElevatedButton(
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
                   ElevatedButton(
                       child: Text('Load groove'),
                       onPressed: () {
                         Get.to(() => loadGroovePage);
                       }
                   ),
                 ]),
               ]),  // Widget, wrap
             ],  // Widget
           ), // Listview
         ),

       bottomNavigationBar: BottomAppBar(
         child: new Row(
           mainAxisSize: MainAxisSize.max,
           mainAxisAlignment: MainAxisAlignment.spaceBetween,
           children: <Widget>[
             Obx(()=> Text(groove.bpmString.value,
                 style: TextStyle(color: Colors.white, fontSize: 40))),
             Obx(()=> Text(groove.indexString.value,
                 style: TextStyle(color: Colors.white, fontSize: 40))),
           ],

         ),
         shape: CircularNotchedRectangle(),
         color: Colors.blue[400],
       ),
       floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

     );
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
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  Future<String>? modelNumber;

  @override
  initState() {
    super.initState();
    _initPackageInfo();
    modelNumber = _bluetoothBLEService.readModelNumber();
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
     subtitle: Text(subtitle.isEmpty ? '??' : subtitle),
   );
 }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
        title: Text('Happy Feet - Info Menu'.tr),
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
//              ElevatedButton(
                Text('Model number:'.tr),
//                onPressed: () {
//                  modelNumber = _bluetoothBLEService.readModelNumber();
//                }
//              ),
              FutureBuilder<String>(
                future: modelNumber,
                builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
                  List<Widget> children;
                  if (snapshot.hasData) {
                    children = <Widget>[
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Result: ${snapshot.data}'.tr),
                      )
                    ];
                  } else if (snapshot.hasError) {
                    children = <Widget>[
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text('Error: ${snapshot.error}'),
                      )
                    ];
                  } else {
                    children = const <Widget>[
                      SizedBox(
                        child: CircularProgressIndicator(),
                        width: 60,
                        height: 60,
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('Awaiting result...'),
                      )
                    ];
                  }
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: children,
                    ),
                  );
                })
            ]),
           Row(children: <Widget>[
             ElevatedButton(
               onPressed: _launchURL,
               child: new Text('Show HappyFeet homepage'.tr),
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
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  String lang = 'English';
  var locale = Get.deviceLocale!;
//  var locale = Locale('en', 'US');
//  var locale: Get.deviceLocale;

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Config Menu'.tr),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Text('Detection threshold'.tr,
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
                    _bluetoothBLEService.writeThreshold(_detectionThreshold & 0xFF);
                  });
                }, // setState, onChanged
              ), // Slider
            ]),
            Row(children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _detectionThreshold = 128;
                    _bluetoothBLEService.writeThreshold(_detectionThreshold & 0xFF);
                  });
                  },
                child: new Text('Reset threshold to default'.tr),
              ),
            ]),// Row
            Row(children: <Widget>[
              Text('Change language'.tr,
                style: Theme.of(context).textTheme.caption,),
              DropdownButton<String>(
                value: lang,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 24,
                elevation: 24,
                style: Theme.of(context).textTheme.headline4,
                onChanged: (String? newValue) {
                  setState(() {
                    switch (newValue) {
                      case 'English':
                        locale = Locale('en', 'US');
                        break;
                      case 'Français':
                        locale = Locale('fr', 'FR');
                        break;
                      case 'Deutsch':
                        locale = Locale('de', 'DE');
                        break;
                      case 'Español':
                        locale = Locale('es', 'ES');
                        break;
                      case 'Italiano':
                        locale = Locale('it', 'IT');
                        break;
                      case 'Português':
                        locale = Locale('pt', 'PT');
                        break;
                      default:
                        locale = Locale('en', 'US');
                        break;
                    }
                    lang = newValue!;
                    Get.updateLocale(locale);
                    print("HF: language changed to $newValue");
                  });
                },
                items: <String>['English','Français','Deutsch','Español','Italiano','Português']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              // Text
            ])
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
     grooveStorage.listOfSavedGrooves();
   }

   @override
   Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(
         title: Text("Happy Feet - Load Groove"),
       ),
       body: Container(
           alignment: Alignment.center,
           padding: const EdgeInsets.all(6),
         child: Column(
                 children: <Widget>[
                   Text('Saved grooves: ',
                     style: Theme.of(context).textTheme.caption,),
                   Flexible(
                     child: ListView.builder(
                       itemCount: grooveStorage.grooveFileNames.length,
                       itemBuilder: (BuildContext context, int index) {
                         return ListTile(
                             title: Text(grooveStorage.grooveFileNames[index]),
                             trailing: Icon(Icons.file_upload),
                             onTap: () {
                               // load the selected groove
                               var name = grooveStorage.grooveFileNames[index];
                               grooveStorage.readGroove(name);
                               Get.snackbar('Load status', 'Loaded groove ' + name, snackPosition: SnackPosition.BOTTOM);
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
                         );
                       }
                     )
                   ),
                 ],
               ),
             ),
       );
   }  // Widget
 } // class

