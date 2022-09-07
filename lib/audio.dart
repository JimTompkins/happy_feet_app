import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ogg_piano/flutter_ogg_piano.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:soundpool/soundpool.dart';
import 'dart:io' show Platform;
import 'package:get/get.dart';

import 'groove.dart';

final HfAudio hfaudio = new HfAudio();

// Mapping from note name to ogg voice number
var oggMap = <String, num>{
  'none': -1,
  '-': -1,
  'Bass drum': 0,
  'Bass echo': 1,
  'Lo tom': 11,
  'Hi tom': 12,
  'Snare drum': 2,
  'Hi-hat cymbal': 3,
  'Cowbell': 4,
  'Tambourine': 5,
  'Fingersnap': 7,
  'Rim shot': 8,
  'Shaker': 9,
  'Woodblock': 10,
  'Brushes': 13,
  'Quijada': 14,
};

// Mapping from note name to mp3 file name for audiocache
var mp3Map = <int, String>{
  -1: 'none',
  0: 'fatkick.mp3',
  1: 'kick_drum2.mp3',
  2: 'snare_drum.mp3',
  3: 'high_hat.mp3',
  4: 'cowbell.mp3',
  5: 'tambourine.mp3',
  7: 'fingersnap.mp3',
  8: 'sidestick.mp3',
  9: 'shaker.mp3',
  10: 'woodblock2.mp3',
  11: '00.mp3',
  12: '01.mp3',
  13: '02.mp3',
  14: '03.mp3',
  15: '04.mp3',
  16: '05.mp3',
  17: '06.mp3',
  18: '07.mp3',
  19: '08.mp3',
  20: '09.mp3',
  21: '10.mp3',
  22: '11.mp3',
  23: '12.mp3',
  24: '13.mp3',
  25: '14.mp3',
  26: '15.mp3',
  27: '16.mp3',
  28: '17.mp3',
  29: '18.mp3',
  30: '19.mp3',
  31: '20.mp3',
  32: '21.mp3',
  33: '22.mp3',
  34: '23.mp3',
  35: 'lodrytom.mp3',
  36: 'hidrytom.mp3',
  37: 'circlebrush.mp3',
  38: 'vibraslap.mp3',
  39: 'C3G4M6.mp3', // metronome tone, -6dB
};

var soundIdMap = <int, int>{};

// Mapping from note name to single character reference.  Note
// that this can't be done by grabbing the first character since
// there are two notes starting with 'S'.
var initialMap = <String, String>{
  'none': '-',
  '-': '-',
  'Bass drum': 'b',
  'Bass echo': 'B',
  'Snare drum': 'S',
  'Hi-hat cymbal': 'H',
  'Cowbell': 'C',
  'Tambourine': 'M',
  'Fingersnap': 'F',
  'Rim shot': 'R',
  'Shaker': 'A',
  'Woodblock': 'W',
  'Lo tom': 't',
  'Hi tom': 'T',
  'Brushes': 'U',
  'Quijada': 'Q',
};

class HfAudio {
  final fop = FlutterOggPiano();
//  final AudioCache ac = new AudioCache(prefix: 'assets/sounds/');
  Soundpool pool = Soundpool.fromOptions(
      options: SoundpoolOptions(streamType: StreamType.alarm, maxStreams: 10));
  Future<int> streamId = Future.value(0);

  // flags used to indicate if the persussion or bass sounds have been loaded.
  bool engineInitialized = false;
  bool percussionLoaded = false;
  bool bassLoaded = false;

  void init() {
    if (Platform.isAndroid) {
      initAndroid();
    } else if (Platform.isIOS) {
//      initIOSAudiocache();
      initIOSSoundpool();
    }
  }

  // initialize Android audio engine.  Call a subfunction depending on the
  // current groove type.
  void initAndroid() async {
    // initialize the audio engine
    if (!engineInitialized) {
      await fop.init(mode: MODE.LOW_LATENCY);
      engineInitialized = true;
    }

    if (groove.type == GrooveType.percussion) {
      if (!this.percussionLoaded) {
        Get.snackbar('Status'.tr, 'Loading percussion sounds.'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 5),
            showProgressIndicator: true);
        initAndroidPercussion();
        this.percussionLoaded = true;
      }
    } else if (groove.type == GrooveType.bass) {
      if (!this.bassLoaded) {
        Get.snackbar('Status'.tr, 'Loading bass sounds.'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 10),
            showProgressIndicator: true);
        initAndroidBass();
        this.bassLoaded = true;
      }
    } else {
      initAndroidPercussion();
    }
  }

  // initialize iOS audio engine.  Call a subfunction depending on the
  // current groove type.
  void initIOSSoundpool() {
    if (kDebugMode) {
      print('HF: initIOSSoundpool : entered');
      if (groove.type == GrooveType.bass) {
        print('HF:       groove type = bass');
      } else {
        print('HF:     groove type = percussion');
      }
      if (this.percussionLoaded) {
        print('HF:     percussion loaded = true');
      } else {
        print('HF:   percussion loaded = false');
      }
      if (this.bassLoaded) {
        print('HF:     bassloaded = true');
      } else {
        print('HF:   bassloaded = false');
      }
    }

    /*
    if (groove.type == GrooveType.percussion) {
      initIOSSoundpoolPercussion();
    } else if (groove.type == GrooveType.bass) {
      initIOSSoundpoolBass();
    } */
    if (groove.type == GrooveType.percussion) {
      if (!this.percussionLoaded) {
        Get.snackbar('Status'.tr, 'Loading percussion sounds.'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3), // measured 262ms
            showProgressIndicator: true);
        initIOSSoundpoolPercussion();
        this.percussionLoaded = true;
      }
    } else if (groove.type == GrooveType.bass) {
      if (!this.bassLoaded) {
        Get.snackbar('Status'.tr, 'Loading bass sounds.'.tr,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3), // measured 550ms
            showProgressIndicator: true);
        initIOSSoundpoolBass();
        this.bassLoaded = true;
      }
    } else {
      initIOSSoundpoolPercussion();
    }
  }

  // initialize iOS audio engine using soundpool for percussion sounds
  void initIOSSoundpoolPercussion() async {
    if (kDebugMode) {
      print('HF: loading percussion mp3files into soundpool');
    }
    String _path = "assets/sounds/";
    String _filename;

    var _startTime = DateTime.now(); // get system time

    // release previously loaded sounds
    //await pool.release();
    //soundIdMap.clear();

    _filename = _path + "fatkick.mp3";
    var asset0 = await rootBundle.load(_filename);
    int id0 = await pool.load(asset0);
    soundIdMap[0] = id0;

    _filename = _path + "kick_drum2.mp3";
    var asset1 = await rootBundle.load(_filename);
    int id1 = await pool.load(asset1);
    soundIdMap[1] = id1;

    _filename = _path + "snare_drum.mp3";
    var asset2 = await rootBundle.load(_filename);
    int id2 = await pool.load(asset2);
    soundIdMap[2] = id2;

    _filename = _path + "high_hat.mp3";
    var asset3 = await rootBundle.load(_filename);
    int id3 = await pool.load(asset3);
    soundIdMap[3] = id3;

    _filename = _path + "cowbell.mp3";
    var asset4 = await rootBundle.load(_filename);
    int id4 = await pool.load(asset4);
    soundIdMap[4] = id4;

    _filename = _path + "tambourine.mp3";
    var asset5 = await rootBundle.load(_filename);
    int id5 = await pool.load(asset5);
    soundIdMap[5] = id5;

    _filename = _path + "fingersnap.mp3";
    var asset7 = await rootBundle.load(_filename);
    int id7 = await pool.load(asset7);
    soundIdMap[7] = id7;

    _filename = _path + "sidestick.mp3";
    var asset8 = await rootBundle.load(_filename);
    int id8 = await pool.load(asset8);
    soundIdMap[8] = id8;

    _filename = _path + "shaker.mp3";
    var asset9 = await rootBundle.load(_filename);
    int id9 = await pool.load(asset9);
    soundIdMap[9] = id9;

    _filename = _path + "woodblock2.mp3";
    var asset10 = await rootBundle.load(_filename);
    int id10 = await pool.load(asset10);
    soundIdMap[10] = id10;

    _filename = _path + "lodrytom.mp3";
    var asset11 = await rootBundle.load(_filename);
    int id11 = await pool.load(asset11);
    soundIdMap[11] = id11;

    _filename = _path + "hidrytom.mp3";
    var asset12 = await rootBundle.load(_filename);
    int id12 = await pool.load(asset12);
    soundIdMap[12] = id12;

    _filename = _path + "circlebrush.mp3";
    var asset13 = await rootBundle.load(_filename);
    int id13 = await pool.load(asset13);
    soundIdMap[13] = id13;

    _filename = _path + "vibraslap.mp3";
    var asset14 = await rootBundle.load(_filename);
    int id14 = await pool.load(asset14);
    soundIdMap[14] = id14;

    _filename = _path + "click.mp3";
    var asset15 = await rootBundle.load(_filename);
    int id15 = await pool.load(asset15);
    soundIdMap[15] = id15;

    var _finishTime = DateTime.now(); // get system time
    Duration _loadTime = _finishTime.difference(_startTime);
    var _loadTimeMs =
        _loadTime.inMilliseconds.toDouble(); // convert load time to ms

    if (kDebugMode) {
      print('HF: initIOSPercussion: time = $_loadTimeMs ms');
    }

//TODO: play all sounds at zero volume to remove the large latency on the first
// play of a sound
  }

  // initialize iOS audio engine using soundpool for bass sounds
  void initIOSSoundpoolBass() async {
    if (kDebugMode) {
      print('HF: loading bass mp3files into soundpool');
    }
    String _path = "assets/sounds/";
    String _filename;
    int _i = 0;

    int _len = soundIdMap.length;
    if (kDebugMode) {
      print(
          'HF: initIOSSoundpoolBass : soundIdMap length (before clear) = $_len');
    }

    var _startTime = DateTime.now(); // get system time

    // release previously loaded sounds
    //await pool.release();
    //soundIdMap.clear();
    _len = soundIdMap.length;
    if (kDebugMode) {
      print(
          'HF: initIOSSoundpoolBass : soundIdMap length (after clear) = $_len');
    }

    _i = 40;
    _filename = _path + "00.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset0 = await rootBundle.load(_filename);
    int id0 = await pool.load(asset0);
    soundIdMap[_i] = id0;

    _i = 41;
    _filename = _path + "01.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset1 = await rootBundle.load(_filename);
    int id1 = await pool.load(asset1);
    soundIdMap[1] = id1;

    _i = 42;
    _filename = _path + "02.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset2 = await rootBundle.load(_filename);
    int id2 = await pool.load(asset2);
    soundIdMap[_i] = id2;

    _i = 43;
    _filename = _path + "03.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset3 = await rootBundle.load(_filename);
    int id3 = await pool.load(asset3);
    soundIdMap[_i] = id3;

    _i = 44;
    _filename = _path + "04.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset4 = await rootBundle.load(_filename);
    int id4 = await pool.load(asset4);
    soundIdMap[_i] = id4;

    _i = 45;
    _filename = _path + "05.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset5 = await rootBundle.load(_filename);
    int id5 = await pool.load(asset5);
    soundIdMap[_i] = id5;

    _i = 46;
    _filename = _path + "06.mp3";
    print('HF: initIOSSoundpoolBass: filename = $_filename');
    var asset6 = await rootBundle.load(_filename);
    int id6 = await pool.load(asset6);
    soundIdMap[_i] = id6;

    _i = 47;
    _filename = _path + "07.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset7 = await rootBundle.load(_filename);
    int id7 = await pool.load(asset7);
    soundIdMap[_i] = id7;

    _i = 48;
    _filename = _path + "08.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset8 = await rootBundle.load(_filename);
    int id8 = await pool.load(asset8);
    soundIdMap[_i] = id8;

    _i = 49;
    _filename = _path + "09.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset9 = await rootBundle.load(_filename);
    int id9 = await pool.load(asset9);
    soundIdMap[_i] = id9;

    _i = 50;
    _filename = _path + "10.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset10 = await rootBundle.load(_filename);
    int id10 = await pool.load(asset10);
    soundIdMap[_i] = id10;

    _i = 51;
    _filename = _path + "11.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset11 = await rootBundle.load(_filename);
    int id11 = await pool.load(asset11);
    soundIdMap[_i] = id11;

    _i = 52;
    _filename = _path + "12.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset12 = await rootBundle.load(_filename);
    int id12 = await pool.load(asset12);
    soundIdMap[_i] = id12;

    _i = 53;
    _filename = _path + "13.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset13 = await rootBundle.load(_filename);
    int id13 = await pool.load(asset13);
    soundIdMap[_i] = id13;

    _i = 54;
    _filename = _path + "14.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset14 = await rootBundle.load(_filename);
    int id14 = await pool.load(asset14);
    soundIdMap[_i] = id14;

    _i = 55;
    _filename = _path + "15.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset15 = await rootBundle.load(_filename);
    int id15 = await pool.load(asset15);
    soundIdMap[_i] = id15;

    _i = 56;
    _filename = _path + "16.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset16 = await rootBundle.load(_filename);
    int id16 = await pool.load(asset16);
    soundIdMap[_i] = id16;

    _i = 57;
    _filename = _path + "17.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset17 = await rootBundle.load(_filename);
    int id17 = await pool.load(asset17);
    soundIdMap[_i] = id17;

    _i = 58;
    _filename = _path + "18.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset18 = await rootBundle.load(_filename);
    int id18 = await pool.load(asset18);
    soundIdMap[_i] = id18;

    _i = 59;
    _filename = _path + "19.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset19 = await rootBundle.load(_filename);
    int id19 = await pool.load(asset19);
    soundIdMap[_i] = id19;

    _i = 60;
    _filename = _path + "20.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset20 = await rootBundle.load(_filename);
    int id20 = await pool.load(asset20);
    soundIdMap[_i] = id20;

    _i = 61;
    _filename = _path + "21.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset21 = await rootBundle.load(_filename);
    int id21 = await pool.load(asset21);
    soundIdMap[_i] = id21;

    _i = 62;
    _filename = _path + "22.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset22 = await rootBundle.load(_filename);
    int id22 = await pool.load(asset22);
    soundIdMap[_i] = id22;

    _i = 23;
    _filename = _path + "23.mp3";
    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: filename = $_filename');
    }
    var asset23 = await rootBundle.load(_filename);
    int id23 = await pool.load(asset23);
    soundIdMap[_i] = id23;

    var _finishTime = DateTime.now(); // get system time
    Duration _loadTime = _finishTime.difference(_startTime);
    var _loadTimeMs =
        _loadTime.inMilliseconds.toDouble(); // convert load time to ms

    if (kDebugMode) {
      print('HF: initIOSSoundpoolBass: time = $_loadTimeMs ms');
    }

    _len = soundIdMap.length;
    if (kDebugMode) {
      print(
          'HF: initIOSSoundpoolBass : soundIdMap length after loading all = $_len');
    }

//TODO: play all sounds at zero volume to remove the large latency on the first
// play of a sound
  }

  void initAndroidPercussion() async {
    int loadCount = 0;
    bool _forceLoad = true;
    bool _replace = true;

    if (kDebugMode) {
      print('HF: initAndroidPercussion...');
    }

    var _startTime = DateTime.now(); // get system time

    // load the sound sample files
    await rootBundle.load('assets/sounds/fatkick.ogg').then((ogg0) async {
      await fop.load(
          src: ogg0,
          name: 'fatkick.ogg',
          index: 0,
          forceLoad: _forceLoad,
          replace: _replace);
      if (kDebugMode) {
        print('HF: finished loading ogg file 0');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/kick_drum2.ogg').then((ogg1) async {
      await fop.load(
          src: ogg1,
          name: 'kick_drum2.ogg',
          index: 1,
          forceLoad: _forceLoad,
          replace: _replace);
      if (kDebugMode) {
        print('HF: finished loading ogg file 1');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/snare_drum.ogg').then((ogg2) async {
      await fop.load(
        src: ogg2,
        name: 'snare_drum.ogg',
        index: 2,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 2');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/high_hat.ogg').then((ogg3) async {
      await fop.load(
        src: ogg3,
        name: 'high_hat.ogg',
        index: 3,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 3');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/cowbell.ogg').then((ogg4) async {
      await fop.load(
        src: ogg4,
        name: 'cowbell.ogg',
        index: 4,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 4');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/tambourine.ogg').then((ogg5) async {
      await fop.load(
        src: ogg5,
        name: 'tambourine.ogg',
        index: 5,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 5');
      }
      loadCount++;
    });

    await rootBundle.load('assets/sounds/fingersnap.ogg').then((ogg7) async {
      await fop.load(
        src: ogg7,
        name: 'fingersnap.ogg',
        index: 7,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 7');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/sidestick.ogg').then((ogg8) async {
      await fop.load(
        src: ogg8,
        name: 'sidestick.ogg',
        index: 8,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 8');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/shaker.ogg').then((ogg9) async {
      await fop.load(
        src: ogg9,
        name: 'shaker.ogg',
        index: 9,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 9');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/woodblock2.ogg').then((ogg10) async {
      await fop.load(
        src: ogg10,
        name: 'woodblock2.ogg',
        index: 10,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 10');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/lodrytom.ogg').then((ogg11) async {
      await fop.load(
        src: ogg11,
        name: 'lodrytom.ogg',
        index: 11,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 11');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/hidrytom.ogg').then((ogg12) async {
      await fop.load(
        src: ogg12,
        name: 'hidrytom.ogg',
        index: 12,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 12');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/circlebrush.ogg').then((ogg13) async {
      await fop.load(
        src: ogg13,
        name: 'circlebrush.ogg',
        index: 13,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 13');
      }
      loadCount++;
    });

    await rootBundle.load('assets/sounds/vibraslap.ogg').then((ogg14) async {
      await fop.load(
        src: ogg14,
        name: 'vibraslap.ogg',
        index: 14,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 14');
      }
      loadCount++;
    });

    await rootBundle.load('assets/sounds/click.ogg').then((ogg15) async {
      await fop.load(
        src: ogg15,
        name: 'click.ogg',
        index: 15,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 15');
      }
      loadCount++;
    });

    var _finishTime = DateTime.now(); // get system time
    Duration loadTime = _finishTime.difference(_startTime);
    var loadTimeMs =
        loadTime.inMilliseconds.toDouble(); // convert load time to ms

    if (kDebugMode) {
      print(
          'HF: initAndroidPercussion: loadCount = $loadCount, time = $loadTimeMs ms');
    }
  }

  void initAndroidBass() async {
    int loadCount = 0;
    bool _forceLoad = true;
    bool _replace = true;

    if (kDebugMode) {
      print('HF: initAndroidBass...');
    }
    var _startTime = DateTime.now(); // get system time

    // load the sound sample files
    await rootBundle.load('assets/sounds/00.ogg').then((ogg40) async {
      await fop.load(
        src: ogg40,
        name: '00.ogg',
        index: 40,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 0');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/01.ogg').then((ogg41) async {
      await fop.load(
        src: ogg41,
        name: '01.ogg',
        index: 41,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 1');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/02.ogg').then((ogg42) async {
      await fop.load(
        src: ogg42,
        name: '02.ogg',
        index: 42,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 2');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/03.ogg').then((ogg43) async {
      await fop.load(
        src: ogg43,
        name: '03.ogg',
        index: 43,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 3');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/04.ogg').then((ogg44) async {
      await fop.load(
        src: ogg44,
        name: '04.ogg',
        index: 44,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 4');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/05.ogg').then((ogg45) async {
      await fop.load(
        src: ogg45,
        name: '05.ogg',
        index: 45,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      print('HF: finished loading ogg file 5');
      loadCount++;
    });
    await rootBundle.load('assets/sounds/06.ogg').then((ogg46) async {
      await fop.load(
        src: ogg46,
        name: '06.ogg',
        index: 46,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 6');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/07.ogg').then((ogg47) async {
      await fop.load(
        src: ogg47,
        name: '07.ogg',
        index: 47,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 7');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/08.ogg').then((ogg48) async {
      await fop.load(
        src: ogg48,
        name: '08.ogg',
        index: 48,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 8');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/09.ogg').then((ogg49) async {
      await fop.load(
        src: ogg49,
        name: '09.ogg',
        index: 49,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 9');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/10.ogg').then((ogg50) async {
      await fop.load(
        src: ogg50,
        name: 'ogg10.ogg',
        index: 50,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 10');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/11.ogg').then((ogg51) async {
      await fop.load(
        src: ogg51,
        name: '11.ogg',
        index: 51,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 11');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/12.ogg').then((ogg52) async {
      await fop.load(
        src: ogg52,
        name: '12.ogg',
        index: 52,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 12');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/13.ogg').then((ogg53) async {
      await fop.load(
        src: ogg53,
        name: '13.ogg',
        index: 53,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 13');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/14.ogg').then((ogg54) async {
      await fop.load(
        src: ogg54,
        name: '14.ogg',
        index: 54,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 14');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/15.ogg').then((ogg55) async {
      await fop.load(
        src: ogg55,
        name: '15.ogg',
        index: 55,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 15');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/16.ogg').then((ogg56) async {
      await fop.load(
        src: ogg56,
        name: '16.ogg',
        index: 56,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 16');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/17.ogg').then((ogg57) async {
      await fop.load(
        src: ogg57,
        name: '17.ogg',
        index: 57,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 17');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/18.ogg').then((ogg58) async {
      await fop.load(
        src: ogg58,
        name: '18.ogg',
        index: 58,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 18');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/19.ogg').then((ogg59) async {
      await fop.load(
        src: ogg59,
        name: '19.ogg',
        index: 59,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 19');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/20.ogg').then((ogg60) async {
      await fop.load(
        src: ogg60,
        name: '20.ogg',
        index: 60,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      print('HF: finished loading ogg file 20');
      loadCount++;
    });
    await rootBundle.load('assets/sounds/21.ogg').then((ogg61) async {
      await fop.load(
        src: ogg61,
        name: '21.ogg',
        index: 61,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 21');
      }
      loadCount++;
    });
    await rootBundle.load('assets/sounds/22.ogg').then((ogg62) async {
      await fop.load(
        src: ogg62,
        name: '22.ogg',
        index: 62,
        forceLoad: _forceLoad,
        replace: _replace,
      );
      if (kDebugMode) {
        print('HF: finished loading ogg file 22');
      }
      loadCount++;
    });

    var _finishTime = DateTime.now(); // get system time
    Duration loadTime = _finishTime.difference(_startTime);
    var loadTimeMs =
        loadTime.inMilliseconds.toDouble(); // convert load time to ms

    if (kDebugMode) {
      print(
          'HF: initAndroidBass: loadCount = $loadCount, time = $loadTimeMs ms');
    }
  }

  // play a single sound from the index i sample loaded earlier, transposed
  // by n semitones
  play(int voices, int note1, int transpose1, int note2, int transpose2) {
    //print('HF: audio.play: voices = $voices, note1 = $note1, note2 = $note2');
    if (Platform.isAndroid) {
//    print('HF: oggPiano.play voices: $voices, note1: $note1, transpose1: $transpose1, note2:$note2, transpose2: $transpose2');

      if (voices == 1) {
        if (note1 != -1) {
          if (kDebugMode) {
            print('HF:   1 voice, note1: $note1, transpose1: $transpose1');
          }
          fop.play(index: note1, note: transpose1, pan: 0.0);
          return;
        }
      } else if (voices == 2) {
        if (note1 == -1 && note2 != -1) {
          if (kDebugMode) {
            print(
                'HF:  2 voices, 1 note, note2: $note2, transpose2: $transpose2');
          }
          // play note 2 as a single note
          fop.play(index: note2, note: transpose2, pan: 0.0);
          return;
        }
        if (note2 == -1 && note1 != -1) {
          if (kDebugMode) {
            print(
                'HF:  2 voices, 1 note, note1: $note1, transpose1: $transpose1');
          }
          // play note 1 as a single note
          fop.play(index: note1, note: transpose1, pan: 0.0);
          return;
        }
        if (note1 == -1 && note2 == -1) {
          // nothing to play
          return;
        }
        if (note1 != -1 && note2 != -1) {
          if (kDebugMode) {
            print(
                'HF:  2 voices, 2 notes, note1: $note1, note2: $note2, transpose1: $transpose1, transpose2: $transpose2');
          }
          // play both notes at the same time
          Map<int, List<Float64List>> map = Map();
          List<Float64List> sounds1 = [];
          List<Float64List> sounds2 = [];
          Float64List list1 = Float64List(3);
          Float64List list2 = Float64List(3);

//          list1[0] = transpose1.toDouble(); // pitch
          list1[0] = note1.toDouble(); // pitch
          list1[1] = 0.0; // pan
          list1[2] = 0.95; // scale
          sounds1.add(list1);
          map[note1] = sounds1;

//          list2[0] = transpose2.toDouble(); // pitch
          list2[0] = note2.toDouble(); // pitch
          list2[1] = 0.0; // pan
          list2[2] = 0.95; // scale
          sounds2.add(list2);
          map[note2] = sounds2;

          fop.playInGroup(map);
          return;
        }
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
      }
      if (voices == 1) {
        if (note1 != -1) {
          if (kDebugMode) {
            print('HF: play note1 = $note1, soundIdMap[note1] = $soundIdMap[note1]');
          }
          this.streamId = pool.play(soundIdMap[note1]!);
          return;
        }
      } else if (voices == 2) {
        if (note1 == -1 && note2 != -1) {
          this.streamId = pool.play(soundIdMap[note2]!);
          return;
        }
        if (note2 == -1 && note1 != -1) {
          this.streamId = pool.play(soundIdMap[note1]!);
          return;
        }
        if (note1 == -1 && note2 == -1) {
          // nothing to play
          return;
        }
        if (note1 != -1 && note2 != -1) {
          this.streamId = pool.play(soundIdMap[note1]!);
          this.streamId = pool.play(soundIdMap[note2]!);
        }
      }
    }
  }

  // stop previous note.  This is only used in bass mode since
  // bass notes should not overlap in time.
  // Note this only works in iOS.
  void stop() {
    if (Platform.isAndroid) {
      // there is no stop method defined by flutter_ogg_piano
    } else if (Platform.isIOS) {
      // need a streamId to stop the playing sound
//      pool.stop(this.streamId);
    }
  }

  void depose() {
    if (Platform.isAndroid) {
      fop.release();
    } else if (Platform.isIOS) {
      //    pool.release();
    }
  }
}
