import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'mybool.dart';
//import 'ble.dart';   // flutter_reactive_ble version
import 'ble2.dart'; // flutter_blue version
import 'groove.dart';

// 1-tap page
OneTapPage oneTapPage = new OneTapPage();

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

// Stateful version of 1-tap page
class OneTapPage extends StatefulWidget {
  @override
  _OneTapPageState createState() => _OneTapPageState();
}

class _OneTapPageState extends State<OneTapPage> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  RxBool _playState = Get.find();
  RhythmType type = RhythmType.rock1;
  String _rhythmName = 'Rock 1';
  Tablature _tab = new Tablature();

  @override
  initState() {
    super.initState();

    groove.checkType('percussion');
    createGroove(RhythmType.rock1);
  }

  // create a groove with the specified rhythm
  createGroove(RhythmType type) {
    int i = 0;
    switch (type) {
      case RhythmType.rock1:
        print('HF: 1-tap: rock1');
        Get.snackbar('Status'.tr, '1-tap rhythm: rock1'.tr,
            snackPosition: SnackPosition.BOTTOM);

        // rock groove1: 4 beats per measure, 1 measure, 1 voice
        groove.initialize(4, 1, 1);
        groove.reset();
        groove.addInitialNote(0, 'b');
        groove.addInitialNote(1, 'S');
        groove.addInitialNote(2, 'b');
        groove.addInitialNote(3, 'S');
        _tab.clear();
        _tab.add(0, 'b|o---o---|');
        _tab.add(1, 'S|--o---o-|');
        _tab.add(2, ' |1+2+3+4+|');
        _tab.add(3, 'b=bass,S=snare');
        break;

      case RhythmType.rock2:
        print('HF: 1-tap: rock2');
        Get.snackbar('Status'.tr, '1-tap rhythm: rock2'.tr,
            snackPosition: SnackPosition.BOTTOM);

        // rock groove1: 8 beats per measure, 1 measure, 2 voices
        groove.initialize(8, 1, 2);
        groove.reset();
        //measure 1, voice 1: 0-7
        //measure 1, voice 2: 8-15

        // hi-hat all 1/8 notes on voice 1
        for (i = 0; i < 8; i++) {
          groove.addInitialNote(i, 'H');
        }

        groove.addInitialNote(8, 'b');
        groove.addInitialNote(10, 'S');
        groove.addInitialNote(12, 'b');
        groove.addInitialNote(14, 'S');
        _tab.clear();
        _tab.add(0, 'H|xxxxxxxx|');
        _tab.add(1, 'b|o---o---|');
        _tab.add(2, 'S|--o---o-|');
        _tab.add(3, ' |1+2+3+4+|');
        _tab.add(4, 'H=hi-hat');
        _tab.add(5, 'b=bass,S=snare');
        break;

      case RhythmType.jazz1:
        print('HF: 1-tap: jazz1');
        Get.snackbar('Status'.tr, '1-tap rhythm: jazz1'.tr,
            snackPosition: SnackPosition.BOTTOM);

        // jazz groove 1: 4 beats per measure, 1 measure, 1 voice
        groove.resize(4, 1, 1);
        groove.reset();
        groove.addInitialNote(0, '-');
        groove.addInitialNote(1, 'F');
        groove.addInitialNote(2, '-');
        groove.addInitialNote(3, 'F');
        _tab.clear();
        _tab.add(0, 'F|--o---o-|');
        _tab.add(1, ' |1+2+3+4+|');
        _tab.add(2, 'F=fingersnap');
        break;

      case RhythmType.bossanova:
        print('HF: 1-tap: bossa nova groove');
        Get.snackbar('Status'.tr, '1-tap rhythm: Bossa Nova'.tr,
            snackPosition: SnackPosition.BOTTOM);
        groove.initialize(8, 2, 2); // 8 beats per measure, 2 measures, 2 voices
        groove.reset();
        //measure 1, voice 1: 0-7
        //measure 1, voice 2: 8-15
        //measure 2, voice 1: 16-23
        //measure 2, voice 2: 24-31

        // hi-hat all all 1/8 notes on voice 1
        for (i = 0; i < 8; i++) {
          groove.addInitialNote(i, 'H');
        }
        for (i = 16; i < 24; i++) {
          groove.addInitialNote(i, 'H');
        }

        // use voice 2 for bass drum and woodblock (clave)
        // bass pattern:     1,   2+, 3,    4+, 1, 2+, 3,   4+
        // woodblock pattern:   2,       3+,    1, 2+,    4
        // note 1 and 2+ in second measure both have notes.  Since
        // we're limited to two voices, we'll leave out the some notes
        
        groove.addInitialNote(8,  'b'); // 1
        groove.addInitialNote(9,  '-'); // +
        groove.addInitialNote(10, 'W'); // 2
        groove.addInitialNote(11, 'b'); // +
        groove.addInitialNote(12, 'b'); // 3
        groove.addInitialNote(13, 'W'); // +
        groove.addInitialNote(14, '-'); // 4
        groove.addInitialNote(15, 'b'); // +

        groove.addInitialNote(24, 'W'); // 1 : conflict: choose W
        groove.addInitialNote(25, '-'); // +
        groove.addInitialNote(26, '-'); // 2
        groove.addInitialNote(27, 'b'); // + : conflict: choose b
        groove.addInitialNote(28, 'b'); // 3
        groove.addInitialNote(29, '-'); // +
        groove.addInitialNote(30, 'W'); // 4
        groove.addInitialNote(31, 'b'); // +

        _tab.clear();
        _tab.add(0, 'H|xxxxxxxx|xxxxxxxx|');
        _tab.add(1, 'b|o--oo--o|---oo--o|');
        _tab.add(2, 'W|--o--o--|o-----o-|');
        _tab.add(3, ' |1+2+3+4+|1+2+3+4+|');
        _tab.add(4, 'H=hi-hat,b=bass');
        _tab.add(5, '  W=woodblock');
        break;

      case RhythmType.merengue:
        print('HF: 1-tap: merengue');
        Get.snackbar('Status'.tr, '1-tap rhythm: merengue'.tr,
            snackPosition: SnackPosition.BOTTOM);
        groove.initialize(8, 1, 2); // 8 beats per measure, 1 measures, 2 voices
        groove.reset();

        // guira pattern on hi-hat on first voice.  Note that the Guiar pattern
        // uses 16th notes so we're emulating it here with 8th notes
        groove.addInitialNote(0, 'H');
        groove.addInitialNote(1, '-');
        groove.addInitialNote(2, '-');
        groove.addInitialNote(3, 'H');
        groove.addInitialNote(4, 'H');
        groove.addInitialNote(5, '-');
        groove.addInitialNote(6, '-');
        groove.addInitialNote(7, 'H');

        // bass drum on 1 and 3 of second voice
        groove.addInitialNote(8, 'b');
        groove.addInitialNote(9, '-');
        groove.addInitialNote(10, '-');
        groove.addInitialNote(11, '-');
        groove.addInitialNote(12, 'b');
        groove.addInitialNote(13, '-');
        groove.addInitialNote(14, '-');
        groove.addInitialNote(15, '-');

        _tab.clear();
        _tab.add(0, 'H|x--xx--x|');
        _tab.add(1, 'B|o---o---|');
        _tab.add(2, ' |1+2+3+4+|');
        _tab.add(3, 'H=hi-hat,b=bass');
        break;

      case RhythmType.afrocuban68:
        print('HF: 1-tap: AfroCuban 6/8');
        Get.snackbar('Status'.tr, '1-tap rhythm: Afro-Cuban 6/8'.tr,
            snackPosition: SnackPosition.BOTTOM);
        groove.initialize(6, 2, 2); // 6 beats per measure, 2 measures, 2 voices
        groove.reset();

        // cowbell on voice 1
        groove.addInitialNote(0, 'C');
        groove.addInitialNote(1, '-');
        groove.addInitialNote(2, 'C');
        groove.addInitialNote(3, '-');
        groove.addInitialNote(4, 'C');
        groove.addInitialNote(5, 'C');

        groove.addInitialNote(12, '-');
        groove.addInitialNote(13, 'C');
        groove.addInitialNote(14, '-');
        groove.addInitialNote(15, 'C');
        groove.addInitialNote(16, '-');
        groove.addInitialNote(17, 'C');

        // bass and snare on voice 2
        groove.addInitialNote(6, 'b');
        groove.addInitialNote(7, 'S');
        groove.addInitialNote(8, 'b');
        groove.addInitialNote(9, 'S');
        groove.addInitialNote(10, 'S');
        groove.addInitialNote(11, 'b');

        groove.addInitialNote(18, 'S');
        groove.addInitialNote(19, 'b');
        groove.addInitialNote(20, 'S');
        groove.addInitialNote(21, 'b');
        groove.addInitialNote(22, 'S');
        groove.addInitialNote(23, 'S');

        _tab.clear();
        _tab.add(0, 'C|x-x-xx|-x-x-x|');
        _tab.add(1, 'S|-o-oo-|o-o-oo|');
        _tab.add(2, 'b|o-o--o|-o-o--|');
        _tab.add(3, ' |1+2+3+|1+2+3+|');
        _tab.add(4, 'C=cowbell,s=snare');
        _tab.add(5, 'b=bass');
        break;

      case RhythmType.samba:
        print('HF: 1-tap: samba');
        Get.snackbar('Status'.tr, '1-tap rhythm: samba'.tr,
            snackPosition: SnackPosition.BOTTOM);
        groove.initialize(8, 2, 2); // 8 beats per measure, 2 measures, 2 voices
        groove.reset();

        // use voice 1 for hi-hat
        groove.addInitialNote(0, 'H');
        groove.addInitialNote(1, '-');
        groove.addInitialNote(2, 'H');
        groove.addInitialNote(3, 'H');
        groove.addInitialNote(4, 'H');
        groove.addInitialNote(5, '-');
        groove.addInitialNote(6, 'H');
        groove.addInitialNote(7, 'H');

        groove.addInitialNote(16, 'H');
        groove.addInitialNote(17, '-');
        groove.addInitialNote(18, 'H');
        groove.addInitialNote(19, 'H');
        groove.addInitialNote(20, 'H');
        groove.addInitialNote(21, '-');
        groove.addInitialNote(22, 'H');
        groove.addInitialNote(23, 'H');

        // use voice 2 for bass drum and snare
        groove.addInitialNote(8, 'b');
        groove.addInitialNote(9, 'S');
        groove.addInitialNote(10, '-');
        groove.addInitialNote(11, 'b');
        groove.addInitialNote(12, 'S');
        groove.addInitialNote(13, '-');
        groove.addInitialNote(14, 'S');
        groove.addInitialNote(15, 'b');

        groove.addInitialNote(24, 'b');
        groove.addInitialNote(25, 'S');
        groove.addInitialNote(26, '-');
        groove.addInitialNote(27, 'b');
        groove.addInitialNote(28, 'S');
        groove.addInitialNote(29, '-');
        groove.addInitialNote(30, 'S');
        groove.addInitialNote(31, 'b');

        _tab.clear();
        _tab.add(0, 'H|x-xxx-xx|x-xxx-xx|');
        _tab.add(1, 'S|-o--o-o-|-o--o-o-|');
        _tab.add(2, 'b|o--o---o|o--o---o|');
        _tab.add(3, ' |1+2+3+4+|1+2+3+4+|');
        _tab.add(4, 'H=hi-hat,S=snare');
        _tab.add(5, '  b=bass');
        break;

      case RhythmType.salsa:
        Get.snackbar('Status'.tr, '1-tap rhythm: salsa'.tr,
            snackPosition: SnackPosition.BOTTOM);
        groove.initialize(8, 2, 2); // 8 beats per measure, 2 measures, 2 voices
        groove.reset();

        _tab.clear();
        _tab.add(0, 'H|xxxxxxxx|xxxxxxxx|');
        _tab.add(1, 'B|o---o--o|o---o--o|');
        _tab.add(2, 'W|---o--o-|--o--o--|');
        _tab.add(3, ' |1+2+3+4+|1+2+3+4+|');
        _tab.add(4, 'H=hi-hat,B=bass');
        _tab.add(5, '  W=woodblock');
        break;

      default:
        print('HF: error: undefined 1-tap rhythm type');
        _tab.clear();
        _tab.add(0, '???');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - 1-tap Menu'.tr),
      ),
      floatingActionButton: Obx(() =>
        FloatingActionButton(
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
        child: ListView(children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    '1-tap mode: choose a rhythm, enable beats, tap your foot 4 times as a count-in, and then only on the 1s'
                        .tr,
                    softWrap: true,
                    style: TextStyle(color: Colors.blue, fontSize: 20),
                  ),
                ),
              ),
            ]),
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
                        case 'Rock 1':
                          type = RhythmType.rock1;
                          createGroove(type);
                          break;
                        case 'Rock 2':
                          type = RhythmType.rock2;
                          createGroove(type);
                          break;
                        case 'Jazz 1':
                          type = RhythmType.jazz1;
                          createGroove(type);
                          break;
                        case 'Bossa Nova':
                          type = RhythmType.bossanova;
                          createGroove(type);
                          break;
                        case 'Merengue':
                          type = RhythmType.merengue;
                          createGroove(type);
                          break;
                        case 'Afro-Cuban 6/8':
                          type = RhythmType.afrocuban68;
                          createGroove(type);
                          break;
                        case 'Samba':
                          type = RhythmType.samba;
                          createGroove(type);
                          break;
                        default:
                          print('HF: unknown 1-tap rhythm type');
                          break;
                      }
                      print("HF: 1-tap rhythm changed to $newValue");
                    });
                    _rhythmName = newValue!;
                  },
                  items: <String>[
                    'Rock 1',
                    'Rock 2',
                    'Jazz 1',
                    'Bossa Nova',
                    'Merengue',
                    'Afro-Cuban 6/8',
                    'Samba',
                  ].map<DropdownMenuItem<String>>((String value) {
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
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Tab:',
                      style: Theme.of(context).textTheme.caption,
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  _tab.concat(),
                  textAlign: TextAlign.left,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.courierPrime(
                    textStyle: TextStyle(color: Colors.blue, fontSize: 18),
                  ),
                ),
              ),
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
                child: Obx(
                  () => Text(groove.leadInString.value,
                      style: TextStyle(color: Colors.blue, fontSize: 32)),
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
