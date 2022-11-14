import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'ble2.dart'; // flutter_blue_plus version
//import 'audio.dart';
import 'audioBASS.dart'; // BASS version
import 'groove.dart';
import 'screens/grooveScreen.dart';
import 'screens/bassScreen.dart';
import 'screens/settingsScreen.dart';
import 'screens/infoScreen.dart';
import 'onetap.dart';
import 'practice.dart';
import 'saveAndLoad.dart';
import 'localization.g.dart';
import 'utils.dart';

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
        secondaryHeaderColor: Colors.blue[800],
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
              color: Colors.blue[800],
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

// flag used to enable toe or heel tapping
bool heelTap = false;

// saved preference for language
String savedLanguage = '';
String language = '';

// threshold between 0 and 100 for beat detection sensitivity
int beatThreshold = 50;

// flag used to enable auto mode in 1-tap mode.  When auto mode is enabled,
// 1-tap mode only needs you to do the 4 beat lead-in and then tap the first 1.
// It will play the selected groove automatically using the tempo set during
// the lead-in.
bool autoMode = false;

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
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

  final List<HfMenuItem> playModeDropdownList = [
    HfMenuItem(text: 'Single Note', color: Colors.grey[100]),
    HfMenuItem(text: 'Alternating Notes', color: Colors.grey[300]),
    HfMenuItem(text: 'Dual Notes', color: Colors.grey[100]),
    HfMenuItem(text: 'Groove', color: Colors.grey[300]),
    HfMenuItem(text: 'Bass', color: Colors.grey[100]),
    HfMenuItem(text: '1-tap', color: Colors.grey[300]),
    HfMenuItem(text: 'Practice', color: Colors.grey[100]),
  ];

  final List<HfMenuItem> firstNoteDropdownList = [
    HfMenuItem(text: 'Bass drum'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Bass echo'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Lo tom'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Hi tom'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Snare drum'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Hi-hat cymbal'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Cowbell'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Tambourine'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Fingersnap'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Rim shot'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Shaker'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Woodblock'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Brushes'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Quijada'.tr, color: Colors.grey[300]),
  ];

  final List<HfMenuItem> secondNoteDropdownList = [
    HfMenuItem(text: 'none'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Bass drum'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Bass echo'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Lo tom'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Hi tom'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Snare drum'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Hi-hat cymbal'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Cowbell'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Tambourine'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Fingersnap'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Rim shot'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Shaker'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Woodblock'.tr, color: Colors.grey[100]),
    HfMenuItem(text: 'Brushes'.tr, color: Colors.grey[300]),
    HfMenuItem(text: 'Quijada'.tr, color: Colors.grey[100]),
  ];

  Future<void> _checkPermission() async {
    if (Platform.isAndroid) {
      Permission.bluetoothScan.request();
      Permission.bluetoothConnect.request();
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
      // not used
    }
  }

  initPreferences() async {
    // get the current language
    Locale _locale = Get.deviceLocale!;
    var _langCode = _locale.languageCode;
    // convert languageCode to text name of language
    switch (_langCode) {
      case 'en':
        {
          language = 'English';
        }
        break;
      case 'fr':
        {
          language = 'Français';
        }
        break;
      case 'de':
        {
          language = 'Deutsch';
        }
        break;
      case 'es':
        {
          language = 'Español';
        }
        break;
      case 'it':
        {
          language = 'Italiano';
        }
        break;
      case 'pt':
        {
          language = 'Português';
        }
        break;
      case 'nl':
        {
          language = 'Nederlands';
        }
        break;
      case 'uk':
        {
          language = 'Українська';
        }
        break;
    }

    // load saved preferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    audioTestMode = prefs.getBool('audioTestMode') ?? false;
    multiMode = prefs.getBool('multiMode') ?? false;
    footSwitch = prefs.getBool('footSwitch') ?? false;
    autoMode = prefs.getBool('autoMode') ?? false;
    heelTap = prefs.getBool('heelTap') ?? false;
    savedLanguage = prefs.getString('language') ?? '';
    if (savedLanguage != '') {
      if (kDebugMode) {
        print('HF: found saved language $savedLanguage');
      }
      switch (savedLanguage) {
        case 'English':
          _locale = Locale('en', 'US');
          break;
        case 'Français':
          _locale = Locale('fr', 'FR');
          break;
        case 'Deutsch':
          _locale = Locale('de', 'DE');
          break;
        case 'Español':
          _locale = Locale('es', 'ES');
          break;
        case 'Italiano':
          _locale = Locale('it', 'IT');
          break;
        case 'Português':
          _locale = Locale('pt', 'PT');
          break;
        case 'Nederlands':
          _locale = Locale('nl', 'NL');
          break;
        case 'Українська':
          _locale = Locale('uk', 'UK');
          break;
        default:
          _locale = Locale('en', 'US');
          break;
      }
      Get.updateLocale(_locale);
      language = savedLanguage;
      if (kDebugMode) {
        print('HF: updating language to $savedLanguage');
      }
    }
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    groove.initSingle(note1);

    // initialize the saved preferences.  Note that this function call was added to prevent
    // an error message due to awaits inside initState().  This showed up for the first time
    // after upgrading to flutter 3.0.1
    initPreferences();

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
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.inactive) return;

    // close BLE connection when the app is detached
    if (state == AppLifecycleState.detached) {
      if (_bluetoothBLEService.isBleConnected()) {
        _bluetoothBLEService.disconnectFromDevice();
        _playState.value = false;
      }
      return;
    }

    final isBackground = state == AppLifecycleState.paused;

    if (isBackground) {
      // when the app moves to the background...
      if (kDebugMode) {
        print('HF: saving preferences when app goes to background');
      }

      final _prefs = await SharedPreferences.getInstance();
      _prefs.setString('language', language);
      _prefs.setBool('audioTestMode', audioTestMode);
      _prefs.setBool('multiMode', multiMode);
      _prefs.setBool('autoMode', autoMode);
      _prefs.setBool('footSwitch', footSwitch);
      _prefs.setBool('heelTap', heelTap);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet'),
        leading: GestureDetector(
          onTap: () {
            Get.to(() => settingsScreen);
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
                  Get.to(() => infoScreen);
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
                            if (kDebugMode) {
                              print('HF: waiting for scan to complete...');
                            }
                            _bluetoothBLEService.isScanComplete();
                            if (kDebugMode) {
                              print('HF: ...done');
                            }
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
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: playModeDropdownList
                        .map((item) => DropdownMenuItem<String>(
                              value: item.text,
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 5.0),
                                color: item.color,
                                child: Text(
                                  item.text,
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ))
                        .toList(),
                    selectedItemBuilder: (context) {
                      return playModeDropdownList
                          .map(
                            (item) => Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              child: Text(
                                item.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: playModeString,
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    buttonHeight: 40,
                    itemHeight: 40,
                    onChanged: (String? newValue) {
                      setState(() {
                        if (kDebugMode) {
                          print('HF: changed playmode to $newValue');
                        }
                        playModeString = newValue;
                        // if changing from bass mode to another mode...
                        if (newValue != 'Bass' && playMode == Mode.bass) {
                          _audioInitNeeded = true;
                          if (kDebugMode) {
                            print(
                                'HF: audio init needed... changing from bass mode');
                          }
                          // or if changing to bass mode from another mode
                        } else if (newValue == 'Bass' &&
                            playMode != Mode.bass) {
                          _audioInitNeeded = true;
                          if (kDebugMode) {
                            print(
                                'HF: audio init needed... changing to bass mode');
                          }
                        } else {
                          _audioInitNeeded = false;
                        }
                        if (newValue == 'Single Note') {
                          playMode = Mode.singleNote;
                          groove.type = GrooveType.percussion;
                          groove.initSingle(note1);
                        } else if (newValue == 'Alternating Notes') {
                          playMode = Mode.alternatingNotes;
                          groove.type = GrooveType.percussion;
                          groove.initAlternating(note1, note2);
                        } else if (newValue == 'Dual Notes') {
                          playMode = Mode.dualNotes;
                          groove.type = GrooveType.percussion;
                          groove.initDual(note1, note2);
                        } else if (newValue == 'Groove') {
                          groove.reset();
                          groove.type = GrooveType.percussion;
                          if (playMode != Mode.groove) {
                            groove.clearNotes();
                          }
                          playMode = Mode.groove;
                          groove.oneTap = false;
                          Get.to(() => grooveScreen);
                        } else if (newValue == 'Bass') {
                          groove.type = GrooveType.bass;
                          groove.voices = 1;
                          groove.reset();
                          if (playMode != Mode.bass) {
                            groove.clearNotes();
                          }
                          playMode = Mode.bass;
                          groove.oneTap = false;
                          Get.to(() => bassScreen);
                        } else if (newValue == '1-tap') {
                          groove.clearNotes();
                          groove.type = GrooveType.percussion;
                          playMode = Mode.groove;
                          groove.oneTap = true;
                          Get.to(() => oneTapPage);
                        } else if (newValue == 'Practice') {
                          if (playMode != Mode.groove) {
                            groove.clearNotes();
                          }
                          playMode = Mode.groove;
                          groove.type = GrooveType.percussion;
                          groove.practice = true;
                          _bluetoothBLEService.disableBeat();
                          Get.to(() => practicePage);
                        } else {
                          playMode = Mode.unknown;
                          if (kDebugMode) {
                            print('HF: error: unknown play mode');
                          }
                        }
                        if (_audioInitNeeded) {
                          hfaudio.init();
                          _audioInitNeeded = false;
                        }
                        String text = groove.toCSV('after changing play mode');
                        if (kDebugMode) {
                          print("HF: $text");
                        }
                      });
                    },
                  ),
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
              DropdownButtonHideUnderline(
                child: DropdownButton2(
                  items: firstNoteDropdownList
                      .map((item) => DropdownMenuItem<String>(
                            value: item.text,
                            child: Container(
                              alignment: AlignmentDirectional.centerStart,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              color: item.color,
                              child: Text(
                                item.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                  selectedItemBuilder: (context) {
                    return firstNoteDropdownList
                        .map(
                          (item) => Container(
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Text(
                              item.text,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                        .toList();
                  },
                  value: note1,
                  dropdownPadding: EdgeInsets.zero,
                  itemPadding: EdgeInsets.zero,
                  buttonHeight: 40,
                  itemHeight: 40,
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
                      if (kDebugMode) {
                        print("HF: $text");
                      }
                    });
                  },
                ),
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
              DropdownButtonHideUnderline(
                child: DropdownButton2(
                  items: secondNoteDropdownList
                      .map((item) => DropdownMenuItem<String>(
                            value: item.text,
                            child: Container(
                              alignment: AlignmentDirectional.centerStart,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 5.0),
                              color: item.color,
                              child: Text(
                                item.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                  selectedItemBuilder: (context) {
                    return secondNoteDropdownList
                        .map(
                          (item) => Container(
                            alignment: Alignment.center,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            child: Text(
                              item.text,
                              style: const TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                        .toList();
                  },
                  value: note2,
                  dropdownPadding: EdgeInsets.zero,
                  itemPadding: EdgeInsets.zero,
                  buttonHeight: 40,
                  itemHeight: 40,
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
                      if (kDebugMode) {
                        print("HF: $text");
                      }
                    });
                  },
                ),
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
                  'Select an available HappyFeet:'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
                IconButton(
                  icon: Icon(
                    Icons.help,
                  ),
                  iconSize: 30,
                  color: Colors.blue[800],
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
                      _rssi = _bluetoothBLEService
                          .rssiMap[_bluetoothBLEService.devicesList[index]];

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
                            _bluetoothBLEService.rssi =
                                _bluetoothBLEService.rssiMap[
                                    _bluetoothBLEService.devicesList[index]]!;
                            if (kDebugMode) {
                              print(
                                  'HF: connecting to selected device $_bluetoothBLEService.devicesList[index].id.toString()');
                            }
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
