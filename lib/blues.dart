import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'utils.dart';
import 'appDesign.dart';
import 'sharedPrefs.dart';
import 'ble2.dart'; // flutter_blue version
import 'groove.dart';
import 'bass.dart';
import 'screens/settingsScreen.dart';

// blues page
BluesPage bluesPage = new BluesPage();

class Tablature {
  List<String> lines = ['', '', '', '', ''];

  Tablature() {
    lines = ['', '', '', '', '', ''];
  }

  void clear() {
    lines = ['', '', '', '', '', ''];
  }

  void add(int i, String s) {
    this.lines[i] = s;
  }

  // concatenate the list of tab lines into one string with newlines (\n)
  String concat() {
    String result = lines[0];
    for (int i = 1; i < lines.length; i++) {
      if (lines[i] != '') {
        result = result + '\n' + lines[i];
      }
    }
    return result;
  }
}

// Stateful version of blues page
class BluesPage extends StatefulWidget {
  @override
  _BluesPageState createState() => _BluesPageState();
}

class _BluesPageState extends State<BluesPage> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RxBool _playState = Get.find();
  BluesType type = BluesType.TwelveBar;
  String _typeName = '12 bar';
  String _keyName = 'E';
  Tablature _tab = new Tablature();
  String bar = '-';
  String nashville = '-';
  String chord = '-';
  List<String> nashvilleList = [];

  final List<HfMenuItem> keyDropdownList = [
    HfMenuItem(text: 'E', color: Colors.grey[100]),
    HfMenuItem(text: 'F', color: Colors.grey[300]),
    HfMenuItem(text: 'F#', color: Colors.grey[100]),
    HfMenuItem(text: 'G', color: Colors.grey[300]),
    HfMenuItem(text: 'G#', color: Colors.grey[100]),
    HfMenuItem(text: 'A', color: Colors.grey[300]),
    HfMenuItem(text: 'A#', color: Colors.grey[100]),
    HfMenuItem(text: 'B', color: Colors.grey[300]),
    HfMenuItem(text: 'C', color: Colors.grey[100]),
    HfMenuItem(text: 'C#', color: Colors.grey[300]),
    HfMenuItem(text: 'D', color: Colors.grey[100]),
    HfMenuItem(text: 'D#', color: Colors.grey[300]),
  ];

  final List<HfMenuItem> bluesDropdownList = [
    HfMenuItem(text: '12 bar'.tr, color: Colors.grey[100]),
    HfMenuItem(text: '12 bar quick change'.tr, color: Colors.grey[300]),
    HfMenuItem(text: '12 bar slow change'.tr, color: Colors.grey[100]),
  ];

  @override
  initState() {
    super.initState();

    groove.checkType('blues');
    createGroove(BluesType.TwelveBar, 'E');
  }

  // create a blues groove with the specified type
  createGroove(BluesType type, String key) {
    int i = 0;
    int keyNum = keys.indexWhere((element) => element == key);

    switch (type) {
      case BluesType.TwelveBar:
        if (kDebugMode) {
          print('HF: blues: 12 bar');
        }

        // TwelveBar: 4 per measure, 12 measures, 2 voices
        groove.initialize(4, 12, 2);
        groove.reset();
        // add bass and snare on alternating beats on voice 1
        for (i = 0; i < 48; i += 2) {
          groove.addInitialNote(i, 'b');
          groove.addInitialNote(i + 1, 'S');
        }
        // add the walking bass progression on voice 2
        // bar 1
        groove.addBassNote2(0, keyNum + 0);
        groove.addBassNote2(1, keyNum + 4);
        groove.addBassNote2(2, keyNum + 7);
        groove.addBassNote2(3, keyNum + 9);
        // bar 2
        groove.addBassNote2(4, keyNum + 10);
        groove.addBassNote2(5, keyNum + 9);
        groove.addBassNote2(6, keyNum + 7);
        groove.addBassNote2(7, keyNum + 4);
        // bar 3
        groove.addBassNote2(8, keyNum + 0);
        groove.addBassNote2(9, keyNum + 4);
        groove.addBassNote2(10, keyNum + 7);
        groove.addBassNote2(11, keyNum + 9);
        // bar 4
        groove.addBassNote2(12, keyNum + 10);
        groove.addBassNote2(13, keyNum + 9);
        groove.addBassNote2(14, keyNum + 7);
        groove.addBassNote2(15, keyNum + 4);
        // bar 5
        groove.addBassNote2(16, keyNum + 5);
        groove.addBassNote2(17, keyNum + 9);
        groove.addBassNote2(18, keyNum + 11);
        groove.addBassNote2(19, keyNum + 9);
        // bar 6
        groove.addBassNote2(20, keyNum + 5);
        groove.addBassNote2(21, keyNum + 5);
        groove.addBassNote2(22, keyNum + 4);
        groove.addBassNote2(23, keyNum + 2);
        // bar 7
        groove.addBassNote2(24, keyNum + 0);
        groove.addBassNote2(25, keyNum + 4);
        groove.addBassNote2(26, keyNum + 7);
        groove.addBassNote2(27, keyNum + 9);
        // bar 8
        groove.addBassNote2(28, keyNum + 10);
        groove.addBassNote2(29, keyNum + 9);
        groove.addBassNote2(30, keyNum + 7);
        groove.addBassNote2(31, keyNum + 4);
        // bar 9
        groove.addBassNote2(32, keyNum + 7);
        groove.addBassNote2(33, keyNum + 9);
        groove.addBassNote2(34, keyNum + 11);
        groove.addBassNote2(35, keyNum + 9);
        // bar 10
        groove.addBassNote2(36, keyNum + 7);
        groove.addBassNote2(37, keyNum + 5);
        groove.addBassNote2(38, keyNum + 4);
        groove.addBassNote2(39, keyNum + 2);
        // bar 11
        groove.addBassNote2(40, keyNum + 0);
        groove.addBassNote2(41, keyNum + 0);
        groove.addBassNote2(42, keyNum + 5);
        groove.addBassNote2(43, keyNum + 5);
        // bar 12
        groove.addBassNote2(44, keyNum + 7);
        groove.addBassNote2(45, keyNum + 5);
        groove.addBassNote2(46, keyNum + 4);
        groove.addBassNote2(47, keyNum + 2);
        _tab.clear();
        _tab.add(0, 'I  I  I I');
        _tab.add(1, 'IV IV I I');
        _tab.add(2, 'V  IV I V');
        nashvilleList = [
          'I',
          'I',
          'I',
          'I',
          'IV',
          'IV',
          'I',
          'I',
          'V',
          'IV',
          'I',
          'V'
        ];
        break;

      case BluesType.TwelveBarQuickChange:
        if (kDebugMode) {
          print('HF: blues: 12 bar quick change');
        }

        // TwelveBar: 4 per measure, 12 measures, 2 voices
        groove.initialize(4, 12, 2);
        groove.reset();
        // add bass and snare on alternating beats on voice 1
        for (i = 0; i < 48; i += 2) {
          groove.addInitialNote(i, 'b');
          groove.addInitialNote(i + 1, 'S');
        }
        // add the walking bass progression on voice 2
        _tab.clear();
        _tab.add(0, 'I  IV I I');
        _tab.add(1, 'IV IV I I');
        _tab.add(2, 'V  IV I V');
        nashvilleList = [
          'I',
          'IV',
          'I',
          'I',
          'IV',
          'IV',
          'I',
          'I',
          'V',
          'IV',
          'I',
          'V'
        ];
        break;

      case BluesType.TwelveBarSlowChange:
        if (kDebugMode) {
          print('HF: blues: 12 bar slow change');
        }

        // TwelveBar: 4 per measure, 12 measures, 2 voices
        groove.initialize(4, 12, 2);
        groove.reset();
        // add bass and snare on alternating beats on voice 1
        for (i = 0; i < 48; i += 2) {
          groove.addInitialNote(i, 'b');
          groove.addInitialNote(i + 1, 'S');
        }
        // add the walking bass progression on voice 2
        _tab.clear();
        _tab.add(0, 'I  I  I I');
        _tab.add(1, 'IV IV I I');
        _tab.add(2, 'V  V  I I');
        nashvilleList = [
          'I',
          'I',
          'I',
          'I',
          'IV',
          'IV',
          'I',
          'I',
          'V',
          'V',
          'I',
          'V'
        ];
        break;

      default:
        if (kDebugMode) {
          print('HF: error: undefined blues type');
        }
        break;
    }
  }

  // get the current bar (or measure) number
  String getBar() {
    return ((groove.index ~/ 4) + 1).toString();
  }

  // get the current bar's Nashville number by calculating the bar
  // and then looking it up in the nashvilleList.
  String getNashville() {
    int _bar = (groove.index ~/ 4);
    return nashvilleList[_bar];
  }

  // get the current bar's chord name by calculating the nashville
  // number and then converting that to an actual chord name using
  // the key.
  // 12 is the number of notes in the keys array.
  // 0, 5 and 7 are the offsets in semitones from the tonic for the
  // I, IV and V chords.
  String getChord() {
    int _bar = (groove.index ~/ 4);
    String _nashville = nashvilleList[_bar];
    int _keyNum = keys.indexWhere((element) => element == _keyName);
    String _chord = '-';
    switch (_nashville) {
      case 'I':
        _chord = keys[(_keyNum + 0) % 12];
        break;
      case 'IV':
        _chord = keys[(_keyNum + 5) % 12];
        break;
      case 'V':
        _chord = keys[(_keyNum + 7) % 12];
        break;
      default:
        break;
    }
    return _chord;
  }

  void updateInfo() {
    int _barNum = ((groove.index ~/ 4) + 1);
    bar = _barNum.toString();
    nashville = nashvilleList[_barNum];
    int _keyNum = keys.indexWhere((element) => element == _keyName);
    switch (nashville) {
      case 'I':
        chord = keys[(_keyNum + 0) % 12];
        break;
      case 'IV':
        chord = keys[(_keyNum + 5) % 12];
        break;
      case 'V':
        chord = keys[(_keyNum + 7) % 12];
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Blues Mode'.tr),
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
          elevation: 25,
          onPressed: () {
            if (_playState.value) {
              // disable beats
              _bluetoothBLEService.disableBeat();
              groove.cancelMeasureTimer();
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
          }, //onPressed
          tooltip: 'Enable beats'.tr,
          child: _playState.value
              ? new Icon(Icons.pause,
                  size: 50, color: Theme.of(context).primaryColor)
              : new Icon(Icons.music_note_outlined,
                  size: 50, color: Theme.of(context).primaryColor),
        ),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    sharedPrefs.autoMode
                        ? 'Blues mode: choose a type and a key, enable beats, tap your foot 4 times as a count-in, and then only on the first 1'
                            .tr
                        : 'Blues mode: choose a type and a key, enable beats, tap your foot 4 times as a count-in, and then only on the 1s'
                            .tr,
                    softWrap: true,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Type'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: bluesDropdownList
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
                      return bluesDropdownList
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
                    value: _typeName,
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
                        switch (newValue) {
                          case '12 bar':
                            type = BluesType.TwelveBar;
                            createGroove(type, _keyName);
                            break;
                          case '12 bar slow change':
                            type = BluesType.TwelveBarSlowChange;
                            createGroove(type, _keyName);
                            break;
                          case '12 bar quick change':
                            type = BluesType.TwelveBarQuickChange;
                            createGroove(type, _keyName);
                            break;
                          default:
                            if (kDebugMode) {
                              print('HF: unknown blues type');
                            }
                            break;
                        }
                        groove.oneTapStarted = false;
                        groove.cancelMeasureTimer();
                        if (kDebugMode) {
                          print("HF: blues type changed to $newValue");
                        }
                      });
                      _typeName = newValue!;
                    },
                  ),
                ),
              ),
            ]),
            Row(children: <Widget>[
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Pattern:'.tr,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.help,
                    ),
                    iconSize: 30,
                    color: AppColors.myButtonColor,
                    onPressed: () {
                      Get.defaultDialog(
                        title: 'Blues Pattern'.tr,
                        middleText:
                            'This is the sequence of chords noted with Nashville numbers.'
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _tab.concat(),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.courierPrime(
                    textStyle:
                        TextStyle(color: AppColors.h4Color, fontSize: 18),
                  ),
                ),
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Key'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: keyDropdownList
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
                      return keyDropdownList
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
                    value: _keyName,
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
                        _keyName = newValue!;
                        createGroove(type, _keyName);
                        groove.oneTapStarted = false;
                        groove.cancelMeasureTimer();
                        if (kDebugMode) {
                          print("HF: blues key changed to $newValue");
                        }
                      });
                    },
                  ),
                ),
              ),
            ]),

            // row of text elements showing the bar number, the nashville number
            // and the actual chord name
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                child: Column(children: <Widget>[
                  Text(
                    'Measure'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    getBar(),
                    style: TextStyle(fontSize: 50),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                child: Column(children: <Widget>[
                  Text(
                    'Nashville',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    getNashville(),
                    style: TextStyle(fontSize: 50),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 10.0),
                child: Column(children: <Widget>[
                  Text(
                    'Chord'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    getChord(),
                    style: TextStyle(
                      fontSize: 50,
                    ),
                  ),
                ]),
              ),
            ]),

            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Obx(
                  () => Text('Lead-in count:'.tr,
                      style: TextStyle(
                        color: groove.leadInDone.value
                            ? Colors.grey
                            : AppColors.h4Color,
                        fontSize: 16,
                      )),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Obx(
                  () => Text(groove.leadInString.value,
                      style: TextStyle(
                          color: groove.leadInDone.value
                              ? Colors.grey
                              : AppColors.captionColor,
                          fontSize: 32)),
                ),
              ),
            ]),
          ]), // Column
        ]),
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
        color: AppColors.bottomBarColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  } // Widget
} // class
