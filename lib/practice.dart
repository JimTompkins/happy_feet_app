import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'ble2.dart'; // flutter_blue version
import 'main.dart';
import 'utils.dart';
import 'appDesign.dart';
import 'audioBASS.dart';
import 'groove.dart';

// Practice page
PracticePage practicePage = new PracticePage();

// Stateful version of Practice page
class PracticePage extends StatefulWidget {
  @override
  _PracticePageState createState() => _PracticePageState();
}

class _PracticePageState extends State<PracticePage> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RxBool _playState = Get.find();
  String note = 'Bass drum';
  Timer? _metronomeTimer;

  final List<HfMenuItem> noteDropdownList = [
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

  @override
  initState() {
    super.initState();
    groove.checkType('percussion');
    groove.initSingle('Bass drum');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Practice Mode'.tr),
      ),
      floatingActionButton: Obx(
        () => FloatingActionButton(
          foregroundColor: Theme.of(context).colorScheme.secondary,
          elevation: 25,
          onPressed: () {
            if (_playState.value) {
              // disable beats
              _bluetoothBLEService.disableBeat();
              Get.snackbar('Status'.tr, 'beats disabled'.tr,
                  snackPosition: SnackPosition.BOTTOM);
              if (metronomeFlag) {
                // stop the metronome tone timer
                if (_metronomeTimer != null) {
                  _metronomeTimer!.cancel();
                }
              }
            } else {
              if (_bluetoothBLEService.isBleConnected()) {
                // enable beats
                groove.reset();
                _bluetoothBLEService.enableBeat();
                if (metronomeFlag) {
                  // start a timer to play the metronome tone at the
                  // chosen tempo
                  var periodInMs = 60000.0 / groove.targetTempo.value;
                  _metronomeTimer = Timer.periodic(
                      Duration(milliseconds: periodInMs.toInt()), (timer) {
                    // play the metronome sound
                    hfaudio.play(15, -1);
                  });
                }
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
        child: Column(children: <Widget>[
          Container(
            padding: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: Text(
              'Choose a sound, set the tempo, enable beats and tap your foot.'
                  .tr,
            ),
          ),

          // first row: the text "Sound" followed by dropdown pick list
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Sound'.tr,
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton2(
                items: noteDropdownList
                    .map((item) => DropdownMenuItem<String>(
                          value: item.text,
                          child: Container(
                            alignment: AlignmentDirectional.centerStart,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 5.0),
                            color: item.color,
                            child: Text(
                              item.text,
                              style: AppTheme.appTheme.textTheme.headline4,
                            ),
                          ),
                        ))
                    .toList(),
                selectedItemBuilder: (context) {
                  return noteDropdownList
                      .map(
                        (item) => Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: Text(
                            item.text,
                            style: AppTheme.appTheme.textTheme.labelMedium,
                          ),
                        ),
                      )
                      .toList();
                },
                value: note,
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
                    note = newValue!;
                    groove.initSingle(note);
                  });
                  if (playOnClickMode) {
                    hfaudio.play(groove.notes[0].oggIndex, -1);
                  }
                },
              ),
            ),
          ]),

          // second row: metronome switch
          Row(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Metronome'.tr,
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            Switch(
              value: metronomeFlag,
              activeColor: Colors.deepOrange[400],
              activeTrackColor: Colors.deepOrange[200],
              inactiveThumbColor: Colors.grey[600],
              inactiveTrackColor: Colors.grey[400],
              onChanged: (value) {
                setState(() {
                  metronomeFlag = value;
                  if (metronomeFlag) {
                    if (kDebugMode) {
                      print('HF: metronome enabled');
                    }
                    Get.snackbar('Status'.tr, 'Metronome enabled.'.tr,
                        snackPosition: SnackPosition.BOTTOM);
                  } else {
                    if (kDebugMode) {
                      print('HF: metronome disabled');
                    }
                    Get.snackbar('Status'.tr, 'Metronome disabled.'.tr,
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
              color: AppColors.myButtonColor,
              onPressed: () {
                Get.defaultDialog(
                  title: 'Metronome'.tr,
                  middleText:
                      'When enabled, a tone will be played at the selected tempo.'
                          .tr,
                  textConfirm: 'OK',
                  onConfirm: () {
                    Get.back();
                  },
                );
              },
            ),
          ]),

          // third row: tempo spinbox
          SpinBox(
            min: 40,
            max: 180,
            step: 2,
            value: groove.targetTempo.toDouble(),
            keyboardType:
                TextInputType.numberWithOptions(signed: true, decimal: false),
            textInputAction:
                TextInputAction.done, // this doesn't work as expected

            validator: (value) {
//              print('HF: practice mode spinbox validator: $value');
              int x = int.parse(value!);
              if (x > 180) {
                return ('BPM should be 180 or less.'.tr);
              } else if (x < 40) {
                return ('BPM should be 40 or more.'.tr);
              } else {
                return (null);
              }
            },
            onChanged: (value) {
//              print('HF: practice mode tempo set to $value');
              setState(() {
                groove.targetTempo.value = value.toInt();
              });
            },
            decoration: InputDecoration(labelText: 'Tempo [BPM]'.tr),
          ),

          // fourth row: measured tempo
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Measured tempo:'.tr,
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Obx(
                () => Text(
                  groove.practiceBPM.value.toStringAsFixed(1),
                  style: TextStyle(
                      fontSize: 40,
                      color: AppColors.captionColor),
                ),
              ),
            ),
          ]),

          // fifth row: error from target tempo
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Error:'.tr,
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Obx(
                () => Text(
                  (-groove.targetTempo.value.toDouble() +
                          groove.practiceBPM.value)
                      .toStringAsFixed(1),
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
          ]),

          // sixth row: streak counter
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Streak count:'.tr,
                style: Theme.of(context).textTheme.caption,
              ),
            ),
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Obx(
                () => Text(
                  (groove.practiceStreak5.value.toString()),
                  style: TextStyle(fontSize: 40),
                ),
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
                  title: 'Streak count:'.tr,
                  middleText:
                      'Number of successive beats that are close to the target tempo.'
                          .tr,
                  textConfirm: 'OK',
                  onConfirm: () {
                    Get.back();
                  },
                );
              },
            ),
          ]),
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
        color: Colors.blue[400],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  } // Widget
} // class
