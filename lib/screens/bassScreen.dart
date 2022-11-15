import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../main.dart';
import '../ble2.dart';
import '../audioBASS.dart';
import '../groove.dart';
import '../bass.dart';
import '../utils.dart';

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
  String _key = groove.key;
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
    HfMenuItem(text: '7', color: Colors.grey[100]),
    HfMenuItem(text: '8', color: Colors.grey[300]),
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

  final List<HfMenuItem> noteDropdownList = [
    HfMenuItem(text: '-', color: Colors.grey[100]),
    HfMenuItem(text: '1', color: Colors.grey[300]),
    HfMenuItem(text: 'b2', color: Colors.grey[100]),
    HfMenuItem(text: '2', color: Colors.grey[300]),
    HfMenuItem(text: 'b3', color: Colors.grey[100]),
    HfMenuItem(text: '3', color: Colors.grey[300]),
    HfMenuItem(text: '4', color: Colors.grey[100]),
    HfMenuItem(text: '5', color: Colors.grey[300]),
    HfMenuItem(text: 'b6', color: Colors.grey[100]),
    HfMenuItem(text: '6', color: Colors.grey[300]),
    HfMenuItem(text: 'b7', color: Colors.grey[100]),
    HfMenuItem(text: '7', color: Colors.grey[300]),
  ];

  @override
  initState() {
    super.initState();
    _beatsPerMeasure = groove.bpm;
    bpmString = groove.bpm.toString();
    _numberOfMeasures = groove.numMeasures;
    measuresString = groove.numMeasures.toString();
    _totalBeats = groove.bpm * groove.numMeasures;
    _key = groove.key;
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
      _result = Colors.blue[200];
    } else {
      _result = Colors.blue[800];
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
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Beats/measure'.tr,
                    style: Theme.of(context).textTheme.caption,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: bpmString,
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
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    buttonHeight: 40,
                    buttonWidth: 80,
                    itemHeight: 40,
                  ),
                ),
              ]), // Row
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Measures'.tr,
                    style: Theme.of(context).textTheme.caption,
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                  ),
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
                                style: const TextStyle(
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: measuresString,
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
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    buttonHeight: 40,
                    buttonWidth: 80,
                    itemHeight: 40,
                  ),
                ),
              ]), // Row

              // key dropdown
              Row(children: <Widget>[
                Container(
                  padding: EdgeInsets.all(10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Key of'.tr,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ), // Text
                DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: keyDropdownList
                        .map((item) => DropdownMenuItem<String>(
                              value: item.text,
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
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
                      return keyDropdownList
                          .map(
                            (item) => Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
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
                    value: _key,
                    onChanged: (String? newValue) {
                      setState(() {
                        _key = newValue!;
                        groove.changeKey(_key);
                      });
                    },
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    buttonHeight: 40,
                    buttonWidth: 80,
                    itemHeight: 40,
                  ),
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
                  color: Colors.blue[800],
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

            // print a list of tones in the selected scale
            Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text(
                'Tones:'.tr + scaleTones(_key),
                style: Theme.of(context).textTheme.caption,
              ),
            ), // Text

            // beat grid
            Container(
              padding: EdgeInsets.all(10),
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose "-" for no note, or numbers 1 through 7 plus flats for tones'
                    .tr,
                style: Theme.of(context).textTheme.caption,
              ),
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

                        child: DropdownButtonHideUnderline(
                          child: DropdownButton2(
                            items: noteDropdownList
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
                                          style: const TextStyle(
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                            selectedItemBuilder: (context) {
                              return noteDropdownList
                                  .map(
                                    (item) => Container(
                                      alignment: Alignment.center,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 0.0),
                                      child: Text(
                                        item.text,
                                        style: const TextStyle(
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList();
                            },
                            value: dropdownValue[index],
                            onChanged: (String? newValue) {
                              setState(() {
                                groove.addBassNote(index, newValue!, _key);
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
                            buttonWidth: 40,
                            itemHeight: 40,
                            isExpanded: false,
                          ),
                        ),

                        /*
                          child: DropdownButton<String>(
                            value: dropdownValue[index],
                            elevation: 24,
                            onChanged: (String? newValue) {
                              setState(() {
                                groove.addBassNote(index, newValue!, _key);
                                dropdownValue[index] = newValue;
                                groove.reset();
                              });
                            },
                            items: <String>[
                              '-','1','b2','2','b3','3','4','b5','5','b6','6',
                              'b7','7'
                            ].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                  value: value, child: Text(value));
                            }).toList(),
                          ) 
                          */
                        // DropdownButton
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
