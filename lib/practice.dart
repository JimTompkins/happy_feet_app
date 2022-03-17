import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_spinbox/flutter_spinbox.dart';
//import 'mybool.dart';
import 'ble.dart';   // flutter_reactive_ble version
//import 'ble2.dart'; // flutter_blue version
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
        child: Column(children: <Widget>[
          Container(
            padding: EdgeInsets.all(5),
            alignment: Alignment.center,
            child: Text(
              'Choose a sound, set the tempo, enable beats and tap your foot.'.tr,
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

          SpinBox(
            min: 40,
            max: 180,
            step: 2,
            value: groove.targetTempo.toDouble(),
            enableInteractiveSelection: false,
            /*
            validator: (value) {
              print('HF: practice mode spinbox validator: $value');
              int x = value.toInt();
              if (x > 180) {
                x = 180;
              } else if (x < 40) {
                x = 40;
              }
              return (x.toString());
            }, */
            onChanged: (value) {
              print('HF: practice mode tempo set to $value.toInt()');
              setState(() {
                groove.targetTempo.value = value.toInt();
              });
            },
            decoration: InputDecoration(labelText: 'Tempo [BPM]'.tr),
          ),
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Measured tempo'.tr,
              ),
            ),
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Obx(
                () => Text(
                  groove.practiceBPM.value.toStringAsFixed(1),
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
          ]),
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Error:'.tr,
              ),
            ),
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Obx(
                () => Text(
                  (-groove.targetTempo.value.toDouble() + groove.practiceBPM.value)
                      .toStringAsFixed(1),
                  style: TextStyle(fontSize: 40),
                ),
              ),
            ),
          ]),
          Row(children: <Widget>[
            Container(
              padding: EdgeInsets.all(5),
              alignment: Alignment.center,
              child: Text(
                'Streak count:'.tr,
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
                    title: 'Streak count'.tr,
                    middleText:
                        "Number of successive beats that are close to the target BPM."
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
