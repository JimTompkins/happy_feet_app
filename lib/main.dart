import 'dart:async';
import 'dart:io' show Platform;
//import 'package:flutter/foundation.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
//import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'mybool.dart';
import 'ble.dart';   // flutter_reactive_ble version
//import 'ble2.dart'; // flutter_blue version
import 'audio.dart';
import 'groove.dart';
import 'bass.dart';
import 'onetap.dart';
import 'practice.dart';
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
  /*
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
*/

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
        ),
      ),
      home: MyHomePage(),
      locale: Get.deviceLocale,
      fallbackLocale: Locale('en', 'US'),
      translations: Localization(),
    );
  }
}

enum Mode { singleNote, alternatingNotes, dualNotes, groove, bass, unknown }

// flag used to enable a test mode where the play button is used to play sounds
// rather than BLE notifies.  This is used to separate the testing of the
// audio from the BLE interface.
bool audioTestMode = false;

// flag used to enable multi mode.  Use multi mode if you have more than one
// HappyFeet.  In multi mode, it will show all of the HappyFeet discovered
// when connecting, and let you select which one you want to connect to.
bool multiMode = false;

// flag used to enable the foot switch.  When foot switch is enabled, you
// can move your foot quickly to either side while it is flat on the floor
// to enable or disable beats.
bool footSwitch = false;

// saved preference for language
String language = 'English';

// threshold between 0 and 100 for beat detection sensitivity
int beatThreshold = 50;

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String note1 = 'Bass drum';
  int index1 = 0;
  String note2 = 'none';
  int index2 = -1;
  int _testModeData = 0x00;
  Mode playMode = Mode.singleNote;
  String? playModeString = 'Single Note';
  RxBool _playState = Get.put(RxBool(false));
  static BluetoothBLEService _bluetoothBLEService =
      Get.put(BluetoothBLEService());
  bool _audioInitNeeded = false;

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      /*
      final status = await Permission.locationWhenInUse.request();
      if (status == PermissionStatus.granted) {
        print('HF: Permission granted');
      } else if (status == PermissionStatus.denied) {
        print(
            'HF: Permission denied. Show a dialog and again ask for the permission');
      } else if (status == PermissionStatus.permanentlyDenied) {
        print('HF: Take the user to the settings page.');
        await openAppSettings();
      }
      */
    } else if (Platform.isIOS) {
      // insert permission checks for iOS here
    }
  }

  @override
  initState() async {
    groove.initSingle(note1);

    // load saved preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    audioTestMode = prefs.getBool('audioTestMode') ?? false;
    multiMode = prefs.getBool('multiMode') ?? false;
    footSwitch = prefs.getBool('footSwitch') ?? false;
    language = prefs.getString('langugage') ?? 'English';

    // prevent from going into sleep mode
    DeviceDisplayBrightness.keepOn(enabled: true);

    // delay the call to audio init since it includes a snackbar which (on iOS)
    // can't be displayed until the scaffold is built
    Future<Null>.delayed(Duration.zero, () {
      hfaudio.init();
    });

    if (!audioTestMode) {
      // request needed permissions
      _checkPermission();

      // initialize BLE
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
            Icons.settings, // add custom icons also
          ),
        ),
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => infoPage);
                },
                child: Icon(Icons.more_vert),
              )),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 25,
          onPressed: () {
            if (audioTestMode) {
              groove.play(_testModeData);
              _testModeData ^= 0x40; // toggle bit 6, the sequence bit
            } else {
              if (_playState.value) {
                // disable beats
                _bluetoothBLEService.disableBeat();
                Get.snackbar('Status'.tr, 'beats disabled'.tr,
                    snackPosition: SnackPosition.BOTTOM);
              } else {
                if (_bluetoothBLEService.isBleConnected()) {
                  // enable beats
                  groove.reset();
                  _bluetoothBLEService.enableBeat();
                  //                       _bluetoothBLEService.enableTestMode();
                  Get.snackbar('Status'.tr, 'beats enabled'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                } else {
                  Get.snackbar('Error'.tr, 'connect to Bluetooth first'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                }
              }
            }
            setState(() {
              if (_bluetoothBLEService.isBleConnected()) {
                _playState.value = !_playState.value;
              }
            });
          }, //onPressed
          tooltip: 'Enable beats'.tr,
          child: _playState.value
              ? new Icon(Icons.pause,
                  size: 50, color: Theme.of(context).primaryColor)
              : new Icon(Icons.music_note_outlined,
                  size: 50, color: Theme.of(context).primaryColor),
        ),
      ),
      body: ListView(children: <Widget>[
        Column(children: <Widget>[
          // Bluetooth heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text(
                  'BLUETOOTH'.tr,
                  style: Theme.of(context).textTheme.headline1,
                )),
          ]),

          //row of buttons with text below each
          Row(children: <Widget>[
            Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                padding: EdgeInsets.all(5),
                alignment: Alignment.center,
                child: Obx(
                  () => IconButton(
                      icon: Icon(
                        Icons.bluetooth_searching,
                      ),
                      iconSize: 50,
                      color: _bluetoothBLEService.isConnected.value
                          ? Colors.grey
                          : Colors.deepOrange[400],
                      splashColor: Colors.purple,
                      onPressed: () {
                        // Start scanning and make connection
                        if (_bluetoothBLEService.isBleConnected()) {
                          Get.snackbar('Error'.tr, 'already connected'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                        } else {
                          Get.snackbar(
                              'Status'.tr, 'connecting to Bluetooth'.tr,
                              snackPosition: SnackPosition.BOTTOM);
                          _bluetoothBLEService.startConnection();
                          if (multiMode) {
                            // wait for the scan to complete
                            print('HF: waiting for scan to complete...');
                            _bluetoothBLEService.isScanComplete();
                            print('HF: ...done');
                            // if more than one device was found during the scan
                            if (_bluetoothBLEService.devicesList.length > 1) {
                              // go to the multi-connect screen...
                              Get.to(() => multiConnectPage);
                            }
                          }
                        }
                      }),
                ),
              ),
              Text(
                'Connect'.tr,
                style: Theme.of(context).textTheme.caption,
              )
            ]),
            Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Container(
                padding: EdgeInsets.all(5),
                alignment: Alignment.center,
                child: Obx(
                  () => IconButton(
                    icon: Icon(
                      Icons.bluetooth_disabled,
                    ),
                    iconSize: 50,
                    color: _bluetoothBLEService.isConnected.value
                        ? Colors.deepOrange[400]
                        : Colors.grey,
                    splashColor: Colors.purple,
                    onPressed: () {
                      // stop the BLE connection
                      if (_bluetoothBLEService.isBleConnected()) {
                        _bluetoothBLEService.disconnectFromDevice();
                        _playState.value = false;
                      } else {
                        Get.snackbar('Error'.tr, 'not connected'.tr,
                            snackPosition: SnackPosition.BOTTOM);
                      }
                      setState(() {
                        _playState.value = false;
                      });
                    },
                  ),
                ),
              ),
              Text(
                'Disconnect'.tr,
                style: Theme.of(context).textTheme.caption,
              )
            ]),
          ]),

          // Mode heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text(
                  'MODE'.tr,
                  style: Theme.of(context).textTheme.headline1,
                )),
          ]),

          // Mode selection dropdown list
          Column(
            children: <Widget>[
              Row(children: <Widget>[
                Container(
                  padding: EdgeInsets.all(5),
                  alignment: Alignment.center,
                  child: Text(
                    'Play mode'.tr,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                DropdownButton<String>(
                  value: playModeString,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 24,
                  style: Theme.of(context).textTheme.headline4,
                  onChanged: (String? newValue) {
                    setState(() {
                      print('HF: changed playmode to $newValue');
                      playModeString = newValue;
                      // if changing from bass mode to another mode...
                      if (newValue != 'Bass' && playMode == Mode.bass) {
                        _audioInitNeeded = true;
                        print(
                            'HF: audio init needed... changing from bass mode');
                        // or if changing to bass mode from another mode
                      } else if (newValue == 'Bass' && playMode != Mode.bass) {
                        _audioInitNeeded = true;
                        print('HF: audio init needed... changing to bass mode');
                      } else {
                        _audioInitNeeded = false;
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
                            groove.oneTap = false;
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
                            groove.oneTap = false;
                            Get.to(() => bassPage);
                          }
                          break;
                        case '1-tap':
                          {
                            if (playMode != Mode.groove) {
                              groove.clearNotes();
                            }
                            playMode = Mode.groove;
                            groove.oneTap = true;
                            Get.to(() => oneTapPage);
                            break;
                          }
                        case 'Practice':
                          {
                            if (playMode != Mode.groove) {
                              groove.clearNotes();
                            }
                            playMode = Mode.groove;
                            groove.practice = true;
                            Get.to(() => practicePage);
                            break;
                          }
                        default:
                          {
                            playMode = Mode.unknown;
                          }
                      }
                      if (_audioInitNeeded) {
                        hfaudio.init();
                        _audioInitNeeded = false;
                      }
                      String text = groove.toCSV('after changing play mode');
                      print("HF: $text");
                    });
                  },
                  items: <String>[
                    'Single Note'.tr,
                    'Alternating Notes'.tr,
                    'Dual Notes'.tr,
                    'Groove'.tr,
                    'Bass'.tr,
                    '1-tap'.tr,
                    'Practice'.tr,
                  ].map<DropdownMenuItem<String>>((String value) {
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
                child: Text(
                  'NOTES'.tr,
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
                child: Text(
                  '1st note'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
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
                  'Bass drum'.tr,
                  'Bass echo'.tr,
                  'Lo tom'.tr,
                  'Hi tom'.tr,
                  'Snare drum'.tr,
                  'Hi-hat cymbal'.tr,
                  'Cowbell'.tr,
                  'Tambourine'.tr,
                  'Fingersnap'.tr,
                  'Rim shot'.tr,
                  'Shaker'.tr,
                  'Woodblock'.tr,
                  'Brushes'.tr,
                  'Quijada'.tr,
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
                child: Text(
                  '2nd note'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
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
                  'none'.tr,
                  'Bass drum'.tr,
                  'Bass echo'.tr,
                  'Lo tom'.tr,
                  'Hi tom'.tr,
                  'Snare drum'.tr,
                  'Hi-hat cymbal'.tr,
                  'Cowbell'.tr,
                  'Tambourine'.tr,
                  'Fingersnap'.tr,
                  'Rim shot'.tr,
                  'Shaker'.tr,
                  'Woodblock'.tr,
                  'Brushes'.tr,
                  'Quijada'.tr,
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
            Obx(() => Text(groove.bpmString.value,
                style: TextStyle(color: groove.bpmColor, fontSize: 40))),
            Obx(() => Text(groove.indexString.value,
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
  int _testModeData = 0x00;
  bool _interpolate = groove.interpolate;
  var dropdownValue = groove.getInitials();
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RxBool _playState = Get.find();

  void loadGroove() {
    _beatsPerMeasure = groove.bpm;
    _numberOfMeasures = groove.numMeasures;
    _totalBeats = groove.bpm * groove.numMeasures * groove.voices;
    _voices = groove.voices;
    _interpolate = groove.interpolate;
    if (_interpolate) {
      groove.leadInCount = 4;
      print('HF: set lead-in counter to 4');
    } else {
      groove.leadInCount = 0;
    }
    groove.checkType('percussion');
    groove.printGroove();
    dropdownValue = groove.getInitials();
  }

  @override
  initState() {
    super.initState();
    loadGroove();
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
        case 0:
          _result = Colors.blue[400];
          break;
        case 1:
          _result = Colors.deepOrange[400];
          break;
        case 2:
          _result = Colors.blue[200];
          break;
        case 3:
          _result = Colors.deepOrange[200];
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
        title: Text('Happy Feet - Grooves'.tr),
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 25,
          onPressed: () {
            if (audioTestMode) {
              groove.play(_testModeData);
              _testModeData ^= 0x40; // toggle bit 6, the sequence bit
            } else {
              if (_playState.value) {
                // disable beats
                _bluetoothBLEService.disableBeat();
                Get.snackbar('Status'.tr, 'beats disabled'.tr,
                    snackPosition: SnackPosition.BOTTOM);
              } else {
                if (_bluetoothBLEService.isBleConnected()) {
                  // enable beats
                  groove.reset();
                  _bluetoothBLEService.enableBeat();
                  //                       _bluetoothBLEService.enableTestMode();
                  Get.snackbar('Status'.tr, 'beats enabled'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                } else {
                  Get.snackbar('Error'.tr, 'connect to Bluetooth first'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                }
              }
              setState(() {
                if (_bluetoothBLEService.isBleConnected()) {
                  _playState.value = !_playState.value;
                }
              });
            }
          }, //onPressed
          tooltip: 'Enable beats',
          child: _playState.value
              ? new Icon(Icons.pause,
                  size: 50, color: Theme.of(context).primaryColor)
              : new Icon(Icons.music_note_outlined,
                  size: 50, color: Theme.of(context).primaryColor),
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            // Define a groove heading
            Wrap(children: <Widget>[
              Container(
                  padding: EdgeInsets.all(10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DEFINE GROOVE'.tr,
                    style: Theme.of(context).textTheme.headline1,
                  )),
            ]),

            // sliders for number of beats per measure and measures
            Column(children: <Widget>[
              Row(children: <Widget>[
                Text(
                  'Beats/measure'.tr,
                  style: Theme.of(context).textTheme.caption,
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
                      groove.resize(
                          _beatsPerMeasure, _numberOfMeasures, _voices);
                      _totalBeats =
                          _beatsPerMeasure * _numberOfMeasures * _voices;
                      print(
                          'HF: changing number of beats per measure, _beatsPerMeasure = $_beatsPerMeasure, _totalBeats = $_totalBeats');
                      dropdownValue = groove.getInitials();
                    });
                  }, // setState, onChanged
                ), // Slider
              ]), // Row
              Row(children: <Widget>[
                Text(
                  'Measures'.tr,
                  style: Theme.of(context).textTheme.caption,
                ), // Text
                Slider(
                  value: _numberOfMeasures.toDouble(),
                  min: 1,
                  max: 12, // for 12 bar blues!
                  divisions: 12,
                  label: _numberOfMeasures.round().toString(),
                  onChanged: (double value) {
                    setState(() {
                      _numberOfMeasures = value.toInt();
                      groove.resize(
                          _beatsPerMeasure, _numberOfMeasures, _voices);
                      _totalBeats =
                          _beatsPerMeasure * _numberOfMeasures * _voices;
                      print(
                          'HF: changing number of measures, _numberOfMeasures = $_numberOfMeasures, _totalBeats = $_totalBeats');
                      dropdownValue = groove.getInitials();
                    });
                  }, // setState, onChanged
                ), // Slider
              ]), // Row
              // radio buttons for number of voices
              Row(children: <Widget>[
                Text('Voices'.tr, style: Theme.of(context).textTheme.caption),
                Radio(
                  value: 1,
                  groupValue: _voices,
                  activeColor: Colors.blue[400],
                  onChanged: (val) {
                    setState(() {
                      _voices = 1;
                      groove.resize(
                          _beatsPerMeasure, _numberOfMeasures, _voices);
                      _totalBeats =
                          _beatsPerMeasure * _numberOfMeasures * _voices;
                      print(
                          'HF: changing to 1 voice, _totalBeats = $_totalBeats');
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
                      groove.resize(
                          _beatsPerMeasure, _numberOfMeasures, _voices);
                      _totalBeats =
                          _beatsPerMeasure * _numberOfMeasures * _voices;
                      print(
                          'HF: changing to 2 voices, _totalBeats = $_totalBeats');
                      dropdownValue = groove.getInitials();
                    });
                  },
                ),
                Text('2'),
              ]),
              Row(children: <Widget>[
                Text(
                    'Offbeat', // note: no translation since I don't think machine translations are good
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
                          if (value) {
                            groove.leadInCount = 4;
                          } // if changing to interpolate mode, add a 4 beat lead-in
                        } else {
                          Get.snackbar(
                              'Notice'.tr,
                              'Offbeat mode can only be used with even number of beats per measure.'
                                  .tr,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      });
                    }),
                IconButton(
                  icon: Icon(
                    Icons.help,
                  ),
                  iconSize: 30,
                  color: Colors.blue[400],
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Offbeat mode'.tr,
                      middleText:
                          "In offbeat mode, sounds are played between beats.  Beats are shown in blue and offbeats in purple."
                              .tr,
                      textConfirm: 'OK',
                      onConfirm: () {
                        Get.back();
                      },
                    );
                  },
                ),
              ]),
            ]), // Column

            // beat grid
            Text(
              ' Choose "-" for no note, b for bass drum, B for bass echo, t for low tom, T for high tom, S for snare drum, H for hi-hat cymbal, M for taMbourine, C for cowbell, F for fingersnap, R for rim shot, A for shAker, W for woodblock, Q for quijada, U for brUshes '
                  .tr,
              style: Theme.of(context).textTheme.caption,
            ), // Text

            GridView.count(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                primary: false,
                padding: const EdgeInsets.all(1),
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                crossAxisCount: _beatsPerMeasure,
                children: List.generate(
                  _totalBeats,
                  (index) {
                    return Center(
                      child: Container(
                        decoration: new BoxDecoration(
                            color: noteColor(index),
                            border: Border.all(width: 1.0)),
                        child: DropdownButton<String>(
                          value: dropdownValue[index],
                          elevation: 24,
                          onChanged: (String? newValue) {
                            setState(() {
//                                String? _initial = initialMap[newValue!];
//                                groove.addInitialNote(index, _initial!);
//                                dropdownValue[index] = _initial;
//                                String? _initial = initialMap[newValue!];
                              groove.addInitialNote(index, newValue!);
                              dropdownValue[index] = newValue;
                            });
                          },
                          items: <String>[
                            /*
                            'none',
                            'Bass drum',
                            'Bass echo',
                            'Lo tom',
                            'Hi tom',
                            'Snare drum',
                            'Hi-hat cymbal',
                            'Tambourine',
                            'Cowbell',
                            'Fingersnap',
                            'Rim shot',
                            'Shaker',
                            'Woodblock',
                            'Quijada',
                            'Brushes',
                            */
                            '-',
                            'b',
                            'B',
                            't',
                            'T',
                            'S',
                            'H',
                            'M',
                            'C',
                            'F',
                            'R',
                            'A',
                            'W',
                            'Q',
                            'U',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ); // Center
                  },
                ) // List.generate
                ), // GridView

            // Save groove
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                ElevatedButton(
                    child: Text('Save groove'.tr),
                    onPressed: () {
                      Get.to(() => saveGroovePage);
                    }),
              ]),
            ]),

            // load groove
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                ElevatedButton(
                    child: Text('Load groove'.tr),
                    onPressed: () {
                      Get.to(() => loadGroovePage);
                    }),
              ]),
            ]), // Widget, wrap
          ], // Widget
        ), // Listview
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Obx(() => Text(groove.bpmString.value,
                style: TextStyle(color: groove.bpmColor, fontSize: 40))),
            Obx(() => Text(groove.indexString.value,
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
  int _testModeData = 0x00;
  bool _interpolate = groove.interpolate;
  String _key = groove.key;
  List<String> dropdownValue = groove.getInitials();
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RxBool _playState = Get.find();

  @override
  initState() {
    super.initState();
    _beatsPerMeasure = groove.bpm;
    _numberOfMeasures = groove.numMeasures;
    _totalBeats = groove.bpm * groove.numMeasures;
    _key = groove.key;
    _interpolate = groove.interpolate;
    if (_interpolate) {
      groove.leadInCount = 4;
      print('HF: set lead-in counter to 4');
    } else {
      groove.leadInCount = 0;
    }
    groove.checkType('bass');
    dropdownValue = groove.getInitials();
    print('HF: dropdownValue = $dropdownValue');
    groove.printGroove();
  }

  // return a colour to use for each gridview element based on its index
  // this is done to improve readability when entering notes into a bass groove.
  Color? rowColor(int index) {
    Color? _result;

    // alternate between two shades of blue for each measure
    if ((index ~/ _beatsPerMeasure) & 0x01 == 0x01) {
      _result = Colors.blue[200];
    } else {
      _result = Colors.blue[400];
    }

    // if in interpolate mode, use a separate colour for the back beats
    if (groove.interpolate && index.isOdd) {
      _result = Colors.deepPurple[200];
    }

    return _result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Bass'.tr),
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 25,
          onPressed: () {
            if (audioTestMode) {
              groove.play(_testModeData);
              _testModeData ^= 0x40; // toggle bit 6, the sequence bit
            } else {
              if (_playState.value) {
                // disable beats
                _bluetoothBLEService.disableBeat();
                Get.snackbar('Status'.tr, 'beats disabled'.tr,
                    snackPosition: SnackPosition.BOTTOM);
              } else {
                if (_bluetoothBLEService.isBleConnected()) {
                  // enable beats
                  groove.reset();
                  _bluetoothBLEService.enableBeat();
                  Get.snackbar('Status'.tr, 'beats enabled'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                } else {
                  Get.snackbar('Error'.tr, 'connect to Bluetooth first'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                }
              }
              setState(() {
                if (_bluetoothBLEService.isBleConnected()) {
                  _playState.value = !_playState.value;
                }
              });
            } // else
          }, //onPressed
          tooltip: 'Enable beats',
          child: _playState.value
              ? new Icon(Icons.pause,
                  size: 50, color: Theme.of(context).primaryColor)
              : new Icon(Icons.music_note_outlined,
                  size: 50, color: Theme.of(context).primaryColor),
        ),
      ),
      body: Center(
        child: ListView(
          children: <Widget>[
            // Define a groove heading
            Wrap(children: <Widget>[
              Container(
                  padding: EdgeInsets.all(10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'DEFINE BASS GROOVE'.tr,
                    style: Theme.of(context).textTheme.headline1,
                  )),
            ]),

            // sliders for number of beats per measure and measures
            Column(children: <Widget>[
              Row(children: <Widget>[
                Text(
                  ' Beats/measure'.tr,
                  style: Theme.of(context).textTheme.caption,
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
                      groove.resize(_beatsPerMeasure, _numberOfMeasures, 1);
                      dropdownValue = groove.getInitials();
                      _totalBeats = _beatsPerMeasure * _numberOfMeasures;
                    });
                  }, // setState, onChanged
                ), // Slider
              ]), // Row
              Row(children: <Widget>[
                Text(
                  ' Measures'.tr,
                  style: Theme.of(context).textTheme.caption,
                ), // Text
                Slider(
                  value: _numberOfMeasures.toDouble(),
                  min: 1,
                  max: 12, // for 12 bar blues!
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
                Text(
                  ' Key of '.tr,
                  style: Theme.of(context).textTheme.caption,
                ), // Text
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
                  items: <String>[
                    'E',
                    'F',
                    'F#',
                    'G',
                    'G#',
                    'A',
                    'A#',
                    'B',
                    'C',
                    'C#',
                    'D',
                    'D#'
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                Text(
                    'Offbeat', // note: no translation since I don't think machine translations are good
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
                          if (value) {
                            groove.leadInCount = 4;
                          } // if changing to interpolate mode, add a 4 beat lead-in
                        } else {
                          Get.snackbar(
                              'Notice'.tr,
                              'back beat mode can only be used with even number of beats per measure.'
                                  .tr,
                              snackPosition: SnackPosition.BOTTOM);
                        }
                      });
                    }),
                IconButton(
                  icon: Icon(
                    Icons.help,
                  ),
                  iconSize: 30,
                  color: Colors.blue[400],
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Offbeat mode'.tr,
                      middleText:
                          "In offbeat mode, sounds are played between beats.  Beats are shown in blue and offbeats in purple."
                              .tr,
                      textConfirm: 'OK',
                      onConfirm: () {
                        Get.back();
                      },
                    );
                  },
                ),
              ]),
            ]), // Column

            // print a list of tones in the selected scale
            Text(
              'Tones: '.tr + scaleTones(_key),
              style: Theme.of(context).textTheme.caption,
            ), // Text

            // beat grid
            Text(
              ' Choose "-" for no note, or numbers 1 through 7 plus flats for tones '
                  .tr,
              style: Theme.of(context).textTheme.caption,
            ), // Text

            GridView.count(
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                primary: false,
                padding: const EdgeInsets.all(1),
                crossAxisSpacing: 1,
                mainAxisSpacing: 1,
                crossAxisCount: _beatsPerMeasure,
                children: List.generate(
                  _totalBeats,
                  (index) {
                    return Center(
                      child: Container(
                          decoration: new BoxDecoration(
                              color: rowColor(index),
                              border: Border.all(width: 1.0)),
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
                            items: <String>[
                              '-',
                              '1',
                              'b2',
                              '2',
                              'b3',
                              '3',
                              '4',
                              'b5',
                              '5',
                              'b6',
                              '6',
                              'b7',
                              '7'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                  value: value, child: Text(value));
                            }).toList(),
                          ) // DropdownButton
                          ),
                    ); // Center
                  },
                ) // List.generate
                ), // GridView

            // Save groove
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                ElevatedButton(
                    child: Text('Save groove'.tr),
                    onPressed: () {
                      Get.to(() => saveGroovePage);
                    }),
              ]),
            ]),

            // load groove
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                ElevatedButton(
                    child: Text('Load groove'.tr),
                    onPressed: () {
                      Get.to(() => loadGroovePage);
                    }),
              ]),
            ]), // Widget, wrap
          ], // Widget
        ), // Listview
      ),
      bottomNavigationBar: BottomAppBar(
        child: new Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Obx(() => Text(groove.bpmString.value,
                style: TextStyle(color: groove.bpmColor, fontSize: 40))),
            Obx(() => Text(groove.indexString.value,
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
  Future<String>? _modelNumber;
  Future<String>? _firmwareRevision;
  Future<String>? _rssi;
  Future<String>? _bleAddress;
  Future<int>? _batteryVoltage;

  @override
  initState() {
    super.initState();
    _initPackageInfo();
    _modelNumber = _bluetoothBLEService.readModelNumber();
    _firmwareRevision = _bluetoothBLEService.readFirmwareRevision();
    _rssi = _bluetoothBLEService.readRSSI();
    _bleAddress = _bluetoothBLEService.readBleAddress();
    _batteryVoltage = _bluetoothBLEService.readBatteryVoltage();
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
        child: ListView(children: <Widget>[
          Column(
            children: <Widget>[
//              _infoTile('App name', _packageInfo.appName),
//              _infoTile('Package name', _packageInfo.packageName),
              _infoTile('App version'.tr, _packageInfo.version),
//              _infoTile('Build number', _packageInfo.buildNumber),
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Serial number:'.tr),
                ),
                Flexible(
                  // this widget is here so that text wrapping will work...
                  child: FutureBuilder<String>(
                      future: _bleAddress,
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
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
                              child: Text('${snapshot.data}', maxLines: 2),
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
                              child: Text('Error: ${snapshot.error}'.tr),
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
                              child: Text(
                                  '...'), // can't translate a string here...
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
                      }),
                )
              ]),
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('RSSI:'.tr),
                ),
                FutureBuilder<String>(
                    future: _rssi,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
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
                            child: Text('Result: ${snapshot.data}' + 'dB'),
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
                            child: Text('Error: ${snapshot.error}'.tr),
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
                            child:
                                Text('...'), // can't translate a string here...
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Model number:'.tr),
                ),
                FutureBuilder<String>(
                    future: _modelNumber,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
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
                            child: Text('Error: ${snapshot.error}'.tr),
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
                            child:
                                Text('...'), // can't translate a string here...
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Firmware revision'.tr),
                ),
                FutureBuilder<String>(
                    future: _firmwareRevision,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
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
                            child: Text('Error: ${snapshot.error}'.tr),
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
                            child: Text('...'),
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Battery charge level:'.tr),
                ),
                FutureBuilder<int>(
                    future: _batteryVoltage,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
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
                            child:
                                Text('Result: ${snapshot.data.toString()}%'.tr),
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
                            child: Text('Error: ${snapshot.error}'.tr),
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
                            child: Text('...'),
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
              Row(
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _launchURL,
                    child: new Text('Show HappyFeet homepage'.tr),
                  ),
                ],
              )
            ],
          ),
        ]),
      ),
    );
  } // Widget
} // class

// menu page
MenuPage menuPage = new MenuPage();

// Stateful version of menu page
class MenuPage extends StatefulWidget {
  @override
  _MenuPageState createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  int _detectionThreshold = 50;
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  String lang = language;
  var locale = Get.deviceLocale!;
//  var locale = Locale('en', 'US');
//  var locale: Get.deviceLocale;

  @override
  initState() {
    lang = language;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Settings Menu'.tr),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Angle'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ), // Text
//              Text(' - '), // Text
              Image.asset(
                 'assets/images/Shallow.png',
                 width: 20,
                 height: 40,
                 color: Colors.deepOrange[400],
                 fit: BoxFit.contain,
                 semanticLabel: 'Shallow',
              ),  // Image
              Slider(
                value: _detectionThreshold.toDouble(),
                min: 0,
                max: 100,
                divisions: 10,
                label: _detectionThreshold.round().toString(),
                onChanged: (double value) {
                  setState(() {
                    _detectionThreshold = value.toInt();
                  });
                },
                onChangeEnd: (double value) {
                  setState(() {
                    if (!_bluetoothBLEService.isConnected()) {
                      // can't reset sensitivity if BLE is not connected
                      Get.snackbar(
                          'Error:'.tr, 'You must be connected to adjust.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      _detectionThreshold = value.toInt();
                      _bluetoothBLEService.writeThreshold(_detectionThreshold);
                    }
                  });
                }, // setState, onChanged
              ),
//              Text(' + ',), // Text// Slider
              Image.asset(
                 'assets/images/Steep.png',
                 width: 20,
                 height: 40,
                 color: Colors.deepOrange[400],
                 fit: BoxFit.contain,
                 semanticLabel: 'Steep',
              ),  // Image
            ]),
            Row(children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if (!_bluetoothBLEService.isConnected()) {
                      // can't reset sensitivity if BLE is not connected
                      Get.snackbar('Error:'.tr,
                          'You must be connected to reset to default.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      _detectionThreshold = 50;
                      _bluetoothBLEService
                          .writeThreshold(_detectionThreshold & 0xFF);
                    }
                  });
                },
                child: new Text('Reset sensitivity to default'.tr),
              ),
            ]), // Row
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Change language'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: lang,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 24,
                  style: Theme.of(context).textTheme.headline4,
                  onChanged: (String? newValue) {
                    setState(() async {
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
                        case 'Nederlands':
                          locale = Locale('nl', 'NL');
                          break;
                        case 'Українська':
                          locale = Locale('uk', 'UK');
                          break;
                        default:
                          locale = Locale('en', 'US');
                          break;
                      }
                      lang = newValue!;
                      Get.updateLocale(locale);
                      final _prefs = await SharedPreferences.getInstance();
                      await _prefs.setString('langugage', newValue);
                      print("HF: language changed to $newValue");
                    });
                  },
                  items: <String>[
                    'English',
                    'Français',
                    'Deutsch',
                    'Español',
                    'Italiano',
                    'Português',
                    'Nederlands',
                    'Українська',
                  ].map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
              ),
              // Text
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Audio test mode'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Switch(
                value: audioTestMode,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() async {
                    if (_bluetoothBLEService.isConnected() && value) {
                      // can't turn on audio test mode if BLE is connected
                      Get.snackbar('Error:'.tr,
                          'You cannot use audio test mode if connected.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      audioTestMode = value;
                      final _prefs = await SharedPreferences.getInstance();
                      await _prefs.setBool('audioTestMode', value);
                      if (audioTestMode) {
                        print('HF: audio test mode enabled');
                        Get.snackbar('Status'.tr, 'Audio test mode enabled.'.tr,
                            snackPosition: SnackPosition.BOTTOM);
                      } else {
                        print('HF: audio test mode disabled');
                        Get.snackbar(
                            'Status'.tr, 'Audio test mode disabled.'.tr,
                            snackPosition: SnackPosition.BOTTOM);
                      }
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 30,
                color: Colors.blue[400],
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Audio test mode'.tr,
                    middleText:
                        "In audio test mode, tap the music note button to play the next note."
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Multi mode'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Switch(
                value: multiMode,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() async {
                    multiMode = value;
                    final _prefs = await SharedPreferences.getInstance();
                    await _prefs.setBool('multiMode', value);
                    if (multiMode) {
                      print('HF: multi mode enabled');
                      Get.snackbar('Status'.tr, 'Multi mode enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      print('HF: multi mode disabled');
                      Get.snackbar('Status'.tr, 'Multi mode disabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 30,
                color: Colors.blue[400],
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Multi mode'.tr,
                    middleText:
                        'Use multi mode if you have more than one HappyFeet.'
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Foot switch'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Switch(
                value: footSwitch,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() async {
                    footSwitch = value;
                    final _prefs = await SharedPreferences.getInstance();
                    await _prefs.setBool('footSwitch', value);
                    if (footSwitch) {
                      print('HF: foot switch enabled');
                      Get.snackbar('Status'.tr, 'Foot switch enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      print('HF: foot switch disabled');
                      Get.snackbar('Status'.tr, 'Foot switch disabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 30,
                color: Colors.blue[400],
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Foot switch'.tr,
                    middleText:
                        'When the foot switch is enabled, you can enable or disable beats by moving your foot quickly to either side while flat on the floor.'
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
          ]), // Column
        ]),
      ),
    );
  } // Widget
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
        title: Text('Happy Feet - Save Groove'.tr),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: ListView(children: <Widget>[
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <
              Widget>[
            Text(
              'Enter groove name: '.tr,
              style: Theme.of(context).textTheme.caption,
            ),
            TextFormField(
              controller: _filenameController,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                new FilteringTextInputFormatter(RegExp("[a-z0-9_]"),
                    allow: true)
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  Get.snackbar(
                      'Missing or invalid file name:'.tr,
                      'Please enter a file name with only letters, numbers and underscores.'
                          .tr,
                      snackPosition: SnackPosition.BOTTOM);
                  return 'Please enter a file name';
                } else {
                  return null;
                }
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            Text(
              'Enter a description of the groove: '.tr,
              style: Theme.of(context).textTheme.caption,
            ),
            TextFormField(
              controller: _descriptionController,
              inputFormatters: [
                new FilteringTextInputFormatter(RegExp(","), allow: false)
              ],
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            ElevatedButton(
                child: Text('Save groove'.tr),
                onPressed: () {
                  grooveStorage.writeGroove(
                      _filenameController.text, _descriptionController.text);
                  Get.snackbar('Status:'.tr, 'groove saved'.tr,
                      snackPosition: SnackPosition.BOTTOM);
                  // go back to previous screen
                  Get.back(closeOverlays: true);
                }),
          ]),
        ]),
      ),
    );
  } // Widget
} // class

// load groove page
LoadGroovePage loadGroovePage = new LoadGroovePage();

// Stateful version of loadGroovePage page
class LoadGroovePage extends StatefulWidget {
  @override
  _LoadGroovePageState createState() => _LoadGroovePageState();
}

class _LoadGroovePageState extends State<LoadGroovePage> {
  Future<List>? _grooveList;

  @override
  initState() {
    super.initState();
    _grooveList = grooveStorage.listOfSavedGrooves();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Load Groove'.tr),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Text(
              'Saved grooves: '.tr,
              style: Theme.of(context).textTheme.caption,
            ),
            Flexible(
                child: FutureBuilder(
                    future: _grooveList,
                    builder: (context, snapshot) {
                      if (_grooveList == null) {
                        // no saved grooves found
                        return Text('No saved grooves found.'.tr);
                      } else {
                        return ListView.builder(
                            itemCount: grooveStorage.grooveFileNames.length,
                            itemBuilder: (BuildContext context, int index) {
                              return ListTile(
                                  title: Text(
                                      grooveStorage.grooveFileNames[index]),
                                  trailing: Icon(Icons.file_upload),
                                  onTap: () {
                                    // load the selected groove
                                    var name =
                                        grooveStorage.grooveFileNames[index];
                                    grooveStorage.readGroove(name);
                                    Get.snackbar('Load status'.tr,
                                        'Loaded groove '.tr + name,
                                        snackPosition: SnackPosition.BOTTOM);
                                    // go back to previous screen
                                    Get.back(closeOverlays: true);
                                    /*
                                    if (groove.type == GrooveType.percussion) {
                                      Get.offAll(groovePage);
                                    } else if (groove.type == GrooveType.bass) {
                                      Get.offAll(bassPage);
                                    }
                                    */
                                  });
                            });
                      }
                    })),
          ],
        ),
      ),
    );
  } // Widget
} // class

// multi-connect page
MultiConnectPage multiConnectPage = new MultiConnectPage();

// Stateful version of multiConnectPage page
class MultiConnectPage extends StatefulWidget {
  @override
  _MultiConnectPageState createState() => _MultiConnectPageState();
}

class _MultiConnectPageState extends State<MultiConnectPage> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  int? _rssi = 0;
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Multi-connect'.tr),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Text(
                  'Select an available HappyFeet: '.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
                IconButton(
                  icon: Icon(
                    Icons.help,
                  ),
                  iconSize: 30,
                  color: Colors.blue[400],
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Multi mode'.tr,
                      middleText:
                          'Nearby HappyFeet are listed from closest to furthest as shown by RSSI'
                              .tr,
                      textConfirm: 'OK',
                      onConfirm: () {
                        Get.back();
                      },
                    );
                  },
                ),
              ],
            ),
            Flexible(
                child: ListView.builder(
                    itemCount: _bluetoothBLEService.devicesList.length,
                    itemBuilder: (BuildContext context, int index) {
                      if (Platform.isAndroid) {
                        _rssi = _bluetoothBLEService.rssiMap[
                            _bluetoothBLEService.devicesList[index].id];
                      } else if (Platform.isIOS) {
                        _rssi = _bluetoothBLEService
                            .rssiMap[_bluetoothBLEService.devicesList[index]];
                      }
                      return ListTile(
                          title: Text(_bluetoothBLEService.devicesList[index].id
                              .toString()),
                          trailing: Text(_rssi.toString() + 'dB'),
                          onTap: () {
                            // connect to the selected HappyFeet
                            _bluetoothBLEService.targetDevice =
                                _bluetoothBLEService.devicesList[index];
                            _bluetoothBLEService.connectToDevice();
                            _bluetoothBLEService.bleAddress =
                                _bluetoothBLEService.devicesList[index].id
                                    .toString();
                            if (Platform.isAndroid) {
                              _bluetoothBLEService.rssi = _bluetoothBLEService
                                      .rssiMap[
                                  _bluetoothBLEService.devicesList[index].id]!;
                            } else if (Platform.isIOS) {
                              _bluetoothBLEService.rssi =
                                  _bluetoothBLEService.rssiMap[
                                      _bluetoothBLEService.devicesList[index]]!;
                            }
                            print(
                                'HF: connecting to selected device $_bluetoothBLEService.devicesList[index].id.toString()');
                            Get.snackbar('Bluetooth status'.tr,
                                'connecting to Bluetooth '.tr,
                                snackPosition: SnackPosition.BOTTOM);
                            // go back to previous screen
                            Get.back(closeOverlays: true);
                          });
                    })),
          ],
        ),
      ),
    );
  } // Widget
} // class

