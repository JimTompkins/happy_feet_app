import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'ble2.dart'; // flutter_blue_plus version
//import 'audio.dart';
import 'audioBASS.dart'; // BASS version
import 'groove.dart';
import 'screens/grooveScreen.dart';
import 'screens/bassScreen.dart';
import 'screens/settingsScreen.dart';
import 'screens/multiConnectScreen.dart';
import 'screens/walkthroughScreen.dart';
import 'onetap.dart';
import 'practice.dart';
import 'localization.g.dart';
import 'utils.dart';
import 'appDesign.dart';
import 'sharedPrefs.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await sharedPrefs.init();
//  sharedPrefs.savedLanguage ;  // get the saved language if there is one
  //initPreferences();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    double screenWidth = window.physicalSize.width;
    if (kDebugMode) {
      print('HF: screen width = $screenWidth');
    }
    return GetMaterialApp(
      title: 'Happy Feet',
      theme: AppTheme.appTheme,
      home: sharedPrefs.showWalkthrough ? WalkthroughScreen() : MyHomePage(),
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

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    groove.initSingle(note1);

    sharedPrefs.savedLanguage ;  // get the saved language if there is one

    // prevent from going into sleep mode
    DeviceDisplayBrightness.keepOn(enabled: true);

    // delay the call to audio init since it includes a snackbar which (on iOS)
    // can't be displayed until the scaffold is built
    Future<Null>.delayed(Duration.zero, () {
      hfaudio.init();
    });

    //if (!sharedPrefs.audioTestMode) {
    // request needed permissions
    _checkPermission();

    // initialize BLE
    _bluetoothBLEService.init();
    //}
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
        print('HF: app moving to background');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet'),
        //backgroundColor: AppColors.scaffoldBackgroundColor,
        actions: <Widget>[
          Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  Get.to(() => settingsScreen);
                },
                child: Icon(Icons.settings, color: AppColors.settingsIconColor),
              )),
        ],
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          //foregroundColor: AppColors.settingsIconColor,
          elevation: 25,
          onPressed: () {
            if (sharedPrefs.audioTestMode) {
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
                  //_bluetoothBLEService.enableTestMode();
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
              } else {
                _playState.value = false;
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
                  style: AppTheme.appTheme.textTheme.displayLarge,
                )),
          ]),

          Row(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text(
                  'Connect'.tr,
                  style: AppTheme.appTheme.textTheme.displaySmall,
                )),
            Icon(Icons.bluetooth, size: 30, color: AppColors.settingsIconColor),
            Obx(
              () => Switch(
                  value: _bluetoothBLEService.isConnected.value,
                  activeColor: Colors.deepOrange[400],
                  activeTrackColor: Colors.deepOrange[200],
                  inactiveThumbColor: Colors.grey[600],
                  inactiveTrackColor: Colors.grey[400],
                  onChanged: (connectionRequested) {
                    setState(() {});
                    if (connectionRequested) {
                      // if already connected, do nothing
                      if (_bluetoothBLEService.isConnected.value) {
                      } else {
                        // else, initiate the connection process
                        _bluetoothBLEService.startConnection();
                        Get.snackbar('Status'.tr, 'connecting to Bluetooth'.tr,
                            snackPosition: SnackPosition.BOTTOM);
                        if (sharedPrefs.multiMode) {
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
                    } else {
                      // if already disconected, do nothing
                      if (!_bluetoothBLEService.isConnected.value) {
                      } else {
                        // else, initiate the disconnection process
                        _bluetoothBLEService.disconnectFromDevice();
                        setState(() {
                          _playState.value = false;
                        });
                      }
                    }
                  }),
            ),
          ]),

          // Mode heading
          Wrap(children: <Widget>[
            Container(
                padding: EdgeInsets.all(10),
                alignment: Alignment.centerLeft,
                child: Text(
                  'MODE'.tr,
                  style: AppTheme.appTheme.textTheme.displayLarge,
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
                    style: Theme.of(context).textTheme.displaySmall,
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
                                  style: AppTheme
                                      .appTheme.textTheme.headlineMedium,
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
                              color: AppColors.dropdownBackgroundColor,
                              child: Text(
                                item.text,
                                style: AppTheme.appTheme.textTheme.labelMedium,
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: playModeString,
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    buttonHeight: 40,
                    //buttonWidth: 200,
                    buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                    buttonDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(),
                      color: AppColors.dropdownBackgroundColor,
                    ),
                    itemHeight: 40,
                    dropdownDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(),
                    ),
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
                          /*
                          if (groove.bpm > 6) {  // this checks for an error
                            // when going from oneTap mode to groove mode
                            // since oneTap can have bpm up to 9
                            groove.reset();
                          }
                          */
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
                          /*
                          if (groove.bpm > 6) {  // this checks for an error
                            // when going from oneTap mode to bass mode
                            // since oneTap can have bpm up to 9
                            groove.reset();
                          }
                          */
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
                  style: Theme.of(context).textTheme.displayLarge,
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
                  style: Theme.of(context).textTheme.displaySmall,
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
                                style:
                                    AppTheme.appTheme.textTheme.headlineMedium,
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
                              style: AppTheme.appTheme.textTheme.labelMedium,
                            ),
                          ),
                        )
                        .toList();
                  },
                  value: note1,
                  dropdownPadding: EdgeInsets.zero,
                  itemPadding: EdgeInsets.zero,
                  buttonHeight: 40,
                  buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                  buttonDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(),
                    color: AppColors.dropdownBackgroundColor,
                  ),
                  itemHeight: 40,
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(),
                  ),
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
                    if (sharedPrefs.playOnClickMode) {
                      hfaudio.play(groove.notes[0].oggIndex, -1);
                    }
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
                  style: Theme.of(context).textTheme.displaySmall,
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
                                style:
                                    AppTheme.appTheme.textTheme.headlineMedium,
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
                              style: AppTheme.appTheme.textTheme.labelMedium,
                            ),
                          ),
                        )
                        .toList();
                  },
                  value: note2,
                  dropdownPadding: EdgeInsets.zero,
                  itemPadding: EdgeInsets.zero,
                  buttonHeight: 40,
                  buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                  buttonDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(),
                    color: AppColors.dropdownBackgroundColor,
                  ),
                  itemHeight: 40,
                  dropdownDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(),
                  ),
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
                    if (sharedPrefs.playOnClickMode) {
                      if (playMode == Mode.alternatingNotes) {
                        hfaudio.play(groove.notes[1].oggIndex, -1);
                      } else if (playMode == Mode.dualNotes) {
                        hfaudio.play(groove.notes2[0].oggIndex, -1);
                      } else if (playMode == Mode.singleNote) {
                        if (kDebugMode) {
                          print(
                              'HF: note two has not effect in single note mode.');
                        }
                      }
                    }
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
        color: AppColors.bottomBarColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  } // widget

} // class
