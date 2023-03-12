import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
//import 'package:google_fonts/google_fonts.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'utils.dart';
import 'appDesign.dart';
import 'sharedPrefs.dart';
import 'ble2.dart'; // flutter_blue version
import 'groove.dart';
import 'screens/settingsScreen.dart';

// blues page
BluesPage bluesPage = new BluesPage();

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
    HfMenuItem(text: '12 bar shuffle'.tr, color: Colors.grey[300]),
    HfMenuItem(text: '12 bar quick 4'.tr, color: Colors.grey[100]),
  ];

  @override
  initState() {
    super.initState();

    groove.checkType('percussion');
    groove.checkType('bass');
    createGroove(BluesType.TwelveBar, 'E');
  }

  // create a blues groove with the specified type
  createGroove(BluesType type, String key) {
    int i = 0;
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
        groove.addBassNote2(0, 0);
        break;

      default:
        if (kDebugMode) {
          print('HF: error: undefined blues type');
        }
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
                        ? 'blues mode: choose a type and a key, enable beats, tap your foot 4 times as a count-in, and then only on the first 1'
                            .tr
                        : 'blues mode: choose a type and a key, enable beats, tap your foot 4 times as a count-in, and then only on the 1s'
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
                          case '12 Bar':
                            type = BluesType.TwelveBar;
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

/*
            Row(children: <Widget>[
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Tab:',
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
                        title: 'Tablature'.tr,
                        middleText:
                            "Tablature is a simplified form of music notation.  See www.drumtabs.org for more details."
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
              /*
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
              ), */
            ]),
*/
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
