import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
import 'package:shared_preferences/shared_preferences.dart';
//import 'ble.dart';   // flutter_reactive_ble version
import 'ble2.dart'; // flutter_blue version
//import 'mybool.dart';
import 'audio.dart';
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

  // flag indicating whether a metronome is used in Practice mode or not.
  // If set to true, a metronome tone (consisting of C4 and G4 on piano)
  // will be played at the selected tempo
  bool metronomeFlag = false;

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
        title: Text('Happy Feet - Practice Menu'.tr),
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
                    hfaudio.play(1, 15, 0, -1, 0);
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
            DropdownButton<String>(
              value: note,
              icon: const Icon(Icons.arrow_downward),
              iconSize: 24,
              elevation: 24,
              style: Theme.of(context).textTheme.headline4,
              onChanged: (String? newValue) {
                setState(() {
                  note = newValue!;
                  groove.initSingle(note);
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
                setState(() async {
                  metronomeFlag = value;
                  final _prefs = await SharedPreferences.getInstance();
                  await _prefs.setBool('metronomeFlag', value);
                  if (metronomeFlag) {
                    print('HF: metronome enabled');
                    Get.snackbar('Status'.tr, 'Metronome enabled.'.tr,
                        snackPosition: SnackPosition.BOTTOM);
                  } else {
                    print('HF: metronome disabled');
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
              color: Colors.blue[400],
              onPressed: () {
                Get.defaultDialog(
                  title: 'Metronome'.tr,
                  middleText:
                      'When enabled, a tone will be played at the selected tempo.'.tr,
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
                      color: Colors.white,
                      backgroundColor: groove.practiceColor),
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
              color: Colors.blue[400],
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
