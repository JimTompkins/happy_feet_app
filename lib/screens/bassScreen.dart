import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../main.dart';
import '../ble2.dart';
import '../audioBASS.dart';
import '../groove.dart';
//import '../bass.dart';
import '../utils.dart';
import '../appDesign.dart';
import '../sharedPrefs.dart';
import 'settingsScreen.dart';
import 'saveGrooveScreen.dart';
import 'loadGrooveScreen.dart';

// Bass page
BassScreen bassScreen = new BassScreen();

// Stateful version of bass page
class BassScreen extends StatefulWidget {
  @override
  _BassScreenState createState() => _BassScreenState();
}

class _BassScreenState extends State<BassScreen> {
  int _beatsPerMeasure = groove.bpm;
  int _numberOfMeasures = groove.numMeasures;
  int _totalBeats = groove.bpm * groove.numMeasures;
  int _testModeData = 0x00;
  bool _interpolate = groove.interpolate;
  //String _key = groove.key;
  List<String> dropdownValue = groove.getInitials();
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RxBool _playState = Get.find();
  String? bpmString;
  String? measuresString;

  final List<HfMenuItem> bpmDropdownList = [
    HfMenuItem(text: '1', color: Colors.grey[100]),
    HfMenuItem(text: '2', color: Colors.grey[300]),
    HfMenuItem(text: '3', color: Colors.grey[100]),
    HfMenuItem(text: '4', color: Colors.grey[300]),
    HfMenuItem(text: '5', color: Colors.grey[100]),
    HfMenuItem(text: '6', color: Colors.grey[300]),
    // number of beats per measure limited to 6 since 8
    // causes a rendering overflow...
    //HfMenuItem(text: '7', color: Colors.grey[100]),
    //HfMenuItem(text: '8', color: Colors.grey[300]),
  ];

  final List<HfMenuItem> numMeasuresDropdownList = [
    HfMenuItem(text: '1', color: Colors.grey[100]),
    HfMenuItem(text: '2', color: Colors.grey[300]),
    HfMenuItem(text: '3', color: Colors.grey[100]),
    HfMenuItem(text: '4', color: Colors.grey[300]),
    HfMenuItem(text: '5', color: Colors.grey[100]),
    HfMenuItem(text: '6', color: Colors.grey[300]),
    HfMenuItem(text: '7', color: Colors.grey[100]),
    HfMenuItem(text: '8', color: Colors.grey[300]),
    HfMenuItem(text: '9', color: Colors.grey[100]),
    HfMenuItem(text: '10', color: Colors.grey[300]),
    HfMenuItem(text: '11', color: Colors.grey[100]),
    HfMenuItem(text: '12', color: Colors.grey[300]),
  ];

  final List<HfMenuItem> allNoteDropdownList = [
    HfMenuItem(text: '-', color: Colors.grey[100]),
    HfMenuItem(text: 'E1', color: Colors.grey[300]),
    HfMenuItem(text: 'F1', color: Colors.grey[100]),
    HfMenuItem(text: 'F#1', color: Colors.grey[300]),
    HfMenuItem(text: 'G1', color: Colors.grey[100]),
    HfMenuItem(text: 'G#1', color: Colors.grey[300]),
    HfMenuItem(text: 'A1', color: Colors.grey[100]),
    HfMenuItem(text: 'A#1', color: Colors.grey[300]),
    HfMenuItem(text: 'B1', color: Colors.grey[100]),
    HfMenuItem(text: 'C2', color: Colors.grey[300]),
    HfMenuItem(text: 'C#2', color: Colors.grey[100]),
    HfMenuItem(text: 'D2', color: Colors.grey[300]),
    HfMenuItem(text: 'D#2', color: Colors.grey[100]),
    HfMenuItem(text: 'E2', color: Colors.grey[300]),
    HfMenuItem(text: 'F2', color: Colors.grey[100]),
    HfMenuItem(text: 'F#2', color: Colors.grey[300]),
    HfMenuItem(text: 'G2', color: Colors.grey[100]),
    HfMenuItem(text: 'G#2', color: Colors.grey[300]),
    HfMenuItem(text: 'A2', color: Colors.grey[100]),
    HfMenuItem(text: 'A#2', color: Colors.grey[300]),
    HfMenuItem(text: 'B2', color: Colors.grey[100]),
    HfMenuItem(text: 'C3', color: Colors.grey[300]),
    HfMenuItem(text: 'C#3', color: Colors.grey[100]),
    HfMenuItem(text: 'D3', color: Colors.grey[300]),
    HfMenuItem(text: 'D#3', color: Colors.grey[100]),
  ];

  @override
  initState() {
    super.initState();
    if (groove.bpm > 6) {
      // check for an out of range bpm i.e. > 6
      // this can happen if coming from oneTap to bass mode
      groove.bpm = 6;
    }
    _beatsPerMeasure = groove.bpm;
    bpmString = groove.bpm.toString();
    _numberOfMeasures = groove.numMeasures;
    measuresString = groove.numMeasures.toString();
    _totalBeats = groove.bpm * groove.numMeasures;
    _interpolate = groove.interpolate;
    if (_interpolate) {
      groove.leadInCount = 4;
      if (kDebugMode) {
        print('HF: set lead-in counter to 4');
      }
    } else {
      groove.leadInCount = 0;
    }
    groove.checkType('bass');
    dropdownValue = groove.getInitials();
    if (kDebugMode) {
      print('HF: dropdownValue = $dropdownValue');
    }
    groove.printGroove();
  }

  // return a colour to use for each gridview element based on its index
  // this is done to improve readability when entering notes into a bass groove.
  Color? rowColor(int index) {
    Color? _result;

    // alternate between two shades of blue for each measure
    if ((index ~/ _beatsPerMeasure) & 0x01 == 0x01) {
//      _result = Colors.blue[200];
      _result = Colors.grey[400];
    } else {
//      _result = Colors.blue[800];
      _result = AppColors.dropdownBackgroundColor;
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
        title: Text('Bass'.tr),
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
                    style: Theme.of(context).textTheme.displayLarge,
                  )),
            ]),

            // sliders for number of beats per measure and measures
            Column(children: <Widget>[
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Beats/measure'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: bpmDropdownList
                        .map((item) => DropdownMenuItem<String>(
                              value: item.text,
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                      return bpmDropdownList
                          .map(
                            (item) => Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                item.text,
                                style: AppTheme.appTheme.textTheme.labelMedium,
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: bpmString,
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
                    onChanged: (value) {
                      setState(() {
                        bpmString = value as String;
                        _beatsPerMeasure = int.parse(bpmString!);
                        groove.resize(_beatsPerMeasure, _numberOfMeasures, 1);
                        _totalBeats = _beatsPerMeasure * _numberOfMeasures;
                        if (kDebugMode) {
                          print(
                              'HF: changing number of beats per measure, _beatsPerMeasure = $_beatsPerMeasure, _totalBeats = $_totalBeats');
                        }
                        dropdownValue = groove.getInitials();
                      });
                    },
                  ),
                ),
              ]), // Row
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Measures'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: numMeasuresDropdownList
                        .map((item) => DropdownMenuItem<String>(
                              value: item.text,
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                      return numMeasuresDropdownList
                          .map(
                            (item) => Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                item.text,
                                style: AppTheme.appTheme.textTheme.labelMedium,
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: measuresString,
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
                    onChanged: (value) {
                      setState(() {
                        measuresString = value as String;
                        _numberOfMeasures = int.parse(measuresString!);
                        groove.resize(_beatsPerMeasure, _numberOfMeasures, 1);
                        _totalBeats = _beatsPerMeasure * _numberOfMeasures;
                        if (kDebugMode) {
                          print(
                              'HF: changing number of measures, _numberOfMeasures = $_numberOfMeasures, _totalBeats = $_totalBeats');
                        }
                        dropdownValue = groove.getInitials();
                      });
                    },
                  ),
                ),
              ]), // Row

              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      'Offbeat', // note: no translation since I don't think machine translations are good
                      style: Theme.of(context).textTheme.bodySmall),
                ),
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
                  color: AppColors.myButtonColor,
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Offbeat mode'.tr,
                      middleText:
                          "In offbeat mode, sounds are played between beats. Beats are shown in blue and offbeats in purple."
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
            Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose "-" for no note, or any bass note from E1 to D#3'.tr,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ), // Text

            GridView.count(
                childAspectRatio: 2.0,
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
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(width: 1.0)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2(
                            items: allNoteDropdownList
                                .map((item) => DropdownMenuItem<String>(
                                      value: item.text,
                                      child: Container(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 1.0),
                                        color: item.color,
                                        child: Text(
                                          item.text,
                                          style: AppTheme.appTheme.textTheme
                                              .headlineMedium,
                                        ),
                                      ),
                                    ))
                                .toList(),
                            selectedItemBuilder: (context) {
                              return allNoteDropdownList
                                  .map(
                                    (item) => Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0),
                                      child: Text(
                                        item.text,
                                        style: AppTheme
                                            .appTheme.textTheme.labelMedium,
                                      ),
                                    ),
                                  )
                                  .toList();
                            },
                            value: dropdownValue[index],
                            onChanged: (String? newValue) {
                              setState(() {
                                groove.addBassNote(index, newValue!);
                                dropdownValue[index] = newValue;
                                groove.reset();
                              });
                              if (playOnClickMode) {
                                hfaudio.play(groove.notes[index].oggIndex, -1);
                              }
                            },
                            dropdownPadding: EdgeInsets.zero,
                            itemPadding: EdgeInsets.zero,
                            buttonHeight: 40,
                            itemHeight: 40,
                            dropdownDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(),
                            ),
                            isExpanded: false,
                          ),
                        ),
                      ),
                    ); // Center
                  },
                ) // List.generate
                ), // GridView

            // Save groove
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      child: Text(
                        'Save groove'.tr,
                        style: AppTheme.appTheme.textTheme.bodySmall,
                      ),
                      onPressed: () {
                        Get.to(() => saveGroovePage);
                      }),
                ),
              ]),
            ]),

            // load groove
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      child: Text(
                        'Load groove'.tr,
                        style: AppTheme.appTheme.textTheme.bodySmall,
                      ),
                      onPressed: () {
                        Get.to(() => loadGroovePage);
                      }),
                ),
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
        color: AppColors.bottomBarColor,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
} // class
