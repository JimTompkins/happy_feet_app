import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'mybool.dart';
//import 'ble.dart';   // flutter_reactive_ble version
import 'ble2.dart'; // flutter_blue version
import 'groove.dart';

// Latin page
LatinPage latinPage = new LatinPage();

// Stateful version of latin page
class LatinPage extends StatefulWidget {
  @override
  _LatinPageState createState() => _LatinPageState();
}

class _LatinPageState extends State<LatinPage> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RhythmType type = RhythmType.bossanova;
  String _rhythmName = 'Bossa Nova';
  MyBool _playState = Get.find();

  @override
  initState() {
    super.initState();

    groove.checkType('percussion');
    createGroove(RhythmType.bossanova);
  }

  // create a groove with the specified rhythm
  createGroove(RhythmType type) {
    int i = 0;
    switch (type) {
      case RhythmType.bossanova:
        print('HF: latin: bossa nova groove');
        Get.snackbar('Status'.tr, 'Latin rhythm: Bossa Nova'.tr,
            snackPosition: SnackPosition.BOTTOM);
        groove.resize(8, 2, 2); // 8 beats per measure, 2 measures, 2 voices
        //measure 1, voice 1: 0-7
        //measure 1, voice 2: 8-15
        //measure 2, voice 1: 16-23
        //measure 2, voice 2: 24-31

        // hi-hat all all 1/8 notes on voice 1
        for (i = 0; i < 8; i++) {
          groove.addInitialNote(i, 'F'); // changed from H to F for testing
        }
        for (i = 16; i < 24; i++) {
          groove.addInitialNote(i, 'F'); // changed from H to F for testing
        }

        // use voice 2 for bass drum and woodblock (clave)
        groove.addInitialNote(8, 'B');
        groove.addInitialNote(9, '-');
        groove.addInitialNote(10, '-');
        groove.addInitialNote(11, 'W');
        groove.addInitialNote(12, 'B');
        groove.addInitialNote(13, '-');
        groove.addInitialNote(14, 'W');
        groove.addInitialNote(15, 'B');
        groove.addInitialNote(24, 'B');
        groove.addInitialNote(25, '-');
        groove.addInitialNote(26, 'W');
        groove.addInitialNote(27, '-');
        groove.addInitialNote(28, 'B');
        groove.addInitialNote(29, 'W');
        groove.addInitialNote(30, '-');
        groove.addInitialNote(31, 'B');
        break;

      case RhythmType.samba:
        print('HF: latin: test groove');
        Get.snackbar('Status'.tr, 'Latin rhythm: samba'.tr,
            snackPosition: SnackPosition.BOTTOM);

        // test groove: 4 beats per measure, 1 measure, 1 voice
        groove.resize(4, 1, 1);
        groove.addInitialNote(0, 'B');
        groove.addInitialNote(1, 'K');
        groove.addInitialNote(2, 'B');
        groove.addInitialNote(3, 'S');

        break;

      case RhythmType.salsa:
        Get.snackbar('Status'.tr, 'Latin rhythm: salsa'.tr,
            snackPosition: SnackPosition.BOTTOM);
        break;

      default:
        print('HF: error: undefined Latin rhythm type');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Latin Menu'.tr),
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Theme.of(context).colorScheme.secondary,
        elevation: 25,
        onPressed: () {
          if (_playState.x) {
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
              _playState.x = !_playState.x;
            }
          });
        }, //onPressed
        tooltip: 'Enable beats'.tr,
        child: _playState.x
            ? new Icon(Icons.pause,
                size: 50, color: Theme.of(context).primaryColor)
            : new Icon(Icons.music_note_outlined,
                size: 50, color: Theme.of(context).primaryColor),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Rhythm'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: DropdownButton<String>(
                  value: _rhythmName,
                  icon: const Icon(Icons.arrow_downward),
                  iconSize: 24,
                  elevation: 24,
                  style: Theme.of(context).textTheme.headline4,
                  onChanged: (String? newValue) {
                    setState(() {
                      switch (newValue) {
                        case 'Bossa Nova':
                          type = RhythmType.bossanova;
                          createGroove(type);
                          break;
                        case 'Samba':
                          type = RhythmType.samba;
                          createGroove(type);
                          break;
                        case 'Salsa':
                          type = RhythmType.salsa;
                          createGroove(type);
                          break;
                        default:
                          print('HF: unknown latin rhythm type');
                          break;
                      }
                      print("HF: latin rhythm changed to $newValue");
                    });
                    _rhythmName = newValue!;
                  },
                  items: <String>['Bossa Nova', 'Samba', 'Salsa']
                      .map<DropdownMenuItem<String>>((String value) {
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
                  'Lead-in count:'.tr,
                  style: Theme.of(context).textTheme.caption,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Obx(() => Text(groove.leadInString.value,
                    style: Theme.of(context).textTheme.caption),
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
        color: Colors.blue[400],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  } // Widget
} // class
