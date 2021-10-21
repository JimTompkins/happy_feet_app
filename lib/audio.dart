import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_ogg_piano/flutter_ogg_piano.dart';
//import 'package:audioplayers/audioplayers.dart';
import 'package:soundpool/soundpool.dart';
import 'dart:io' show Platform;
import 'package:sprintf/sprintf.dart';

final HfAudio hfaudio = new HfAudio();

// Mapping from note name to ogg voice number
var oggMap = <String, num>{
  'none': -1,
  '-': -1,
  'Bass drum': 0,
  'Kick drum': 1,
  'Snare drum': 2,
  'Hi-hat cymbal': 3,
  'Cowbell': 4,
  'Tambourine': 5,
  'Fingersnap': 7,
  'Rim shot': 8,
  'Shaker': 9,
  'Woodblock': 10,
};

// Mapping from note name to mp3 file name for audiocache
var mp3Map = <int, String>{
  -1: 'none',
  0: 'bass_drum_fade.mp3',
  1: 'kick_drum.mp3',
  2: 'snare_drum.mp3',
  3: 'high_hat.mp3',
  4: 'cowbell.mp3',
  5: 'tambourine.mp3',
  7: 'fingersnap.mp3',
  8: 'sidestick.mp3',
  9: 'shaker.mp3',
  10: 'woodblock.mp3',
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
};

var soundIdMap = <int, int>{};

// Mapping from note name to single character reference.  Note
// that this can't be done by grabbing the first character since
// there are two notes starting with 'S'.
var initialMap = <String, String>{
  'none': '-',
  '-': '-',
  'Bass drum': 'B',
  'Kick drum': 'K',
  'Snare drum': 'S',
  'Hi-hat cymbal': 'H',
  'Cowbell': 'C',
  'Tambourine': 'T',
  'Fingersnap': 'F',
  'Rim shot': 'R',
  'Shaker': 'A',
  'Woodblock': 'W',
};

class HfAudio {
  final fop = FlutterOggPiano();
//  final AudioCache ac = new AudioCache(prefix: 'assets/sounds/');
  final Soundpool pool = Soundpool(streamType: StreamType.music);

  void init() {
    if (Platform.isAndroid) {
      initAndroid();
    } else if (Platform.isIOS) {
//      initIOSAudiocache();
      initIOSSoundpoolPercussion();
    }
  }

  // initialize iOS audio engine using soundpool for percussion sounds
  void initIOSSoundpoolPercussion() async {
    print('HF: loading percussion mp3files into soundpool');
    String _path = "assets/sounds/";
    String _filename;

    int _len = soundIdMap.length;
    print('HF: initIOSSoundpoolPercussion : soundIdMap lengh = $_len.toString()');

    // release previously loaded sounds
    pool.release();
    soundIdMap.clear();

    _filename = "bass_drum_fade.mp3";
    rootBundle.load(_path + _filename).then((_asset0) {
      pool.load(_asset0).then((_soundId0) {
        soundIdMap[0] = _soundId0;
      });
    });

    _filename = "kick_drum.mp3";
    rootBundle.load(_path + _filename).then((_asset1) {
      pool.load(_asset1).then((_soundId1) {
        soundIdMap[1] = _soundId1;
      });
    });

    _filename = "snare_drum.mp3";
    rootBundle.load(_path + _filename).then((_asset2) {
      pool.load(_asset2).then((_soundId2) {
        soundIdMap[2] = _soundId2;
      });
    });

    _filename = "high_hat.mp3";
    rootBundle.load(_path + _filename).then((_asset3) {
      pool.load(_asset3).then((_soundId3) {
        soundIdMap[3] = _soundId3;
      });
    });

    _filename = "cowbell.mp3";
    rootBundle.load(_path + _filename).then((_asset4) {
      pool.load(_asset4).then((_soundId4) {
        soundIdMap[4] = _soundId4;
      });
    });

    _filename = "tambourine.mp3";
    rootBundle.load(_path + _filename).then((_asset5) {
      pool.load(_asset5).then((_soundId5) {
        soundIdMap[5] = _soundId5;
      });
    });

    _filename = "fingersnap.mp3";
    rootBundle.load(_path + _filename).then((_asset6) {
      pool.load(_asset6).then((_soundId6) {
        soundIdMap[7] = _soundId6;
      });
    });

    _filename = "sidestick.mp3";
    rootBundle.load(_path + _filename).then((_asset7) {
      pool.load(_asset7).then((_soundId7) {
        soundIdMap[8] = _soundId7;
      });
    });

    _filename = "shaker.mp3";
    rootBundle.load(_path + _filename).then((_asset8) {
      pool.load(_asset8).then((_soundId8) {
        soundIdMap[9] = _soundId8;
      });
    });

    _filename = "woodblock.mp3";
    rootBundle.load(_path + _filename).then((_asset9) {
      pool.load(_asset9).then((_soundId9) {
        soundIdMap[10] = _soundId9;
      });
    });

    _len = soundIdMap.length;
    print('HF: initIOSSoundpoolPercussion : soundIdMap length = $_len.toString()');
  }

  // initialize iOS audio engine using soundpool for bass sounds
  void initIOSSoundpoolBass() async {
    print('HF: loading bass mp3files into soundpool');
    String _path = "assets/sounds/";
    String _filename;

    int _len = soundIdMap.length;
    print(
        'HF: initIOSSoundpoolBass : soundIdMap lengh = $_len.toString()');

    // release previously loaded sounds
    pool.release();
    soundIdMap.clear();

    for(int i = 0; i<23; i++) {
      _filename = sprintf("%2d",i) + ".mp3";
      rootBundle.load(_path + _filename).then((_asset) {
        pool.load(_asset).then((_soundId) {
          soundIdMap[i] = _soundId;
        });
      });
      }

    _len = soundIdMap.length;
    print('HF: initIOSSoundpoolPercussion : soundIdMap length = $_len.toString()');

  }

    // initialize iOS audio engine using Audiocache...
  // TODO: remove once lower latency solution is working
  /*
  void initIOSAudiocache() {
    print('HF: loading mp3 files into audiocache...');
    ac.loadAll([
      'bass_drum_fade.mp3',
      'kick_drum.mp3',
      'snare_drum.mp3',
      'high_hat.mp3',
      'cowbell.mp3',
      'tambourine.mp3',
//          'Bass74MapleJazzA1_5sTrimEnvelope2dB',
      'fingersnap.mp3',
      'sidestick.mp3',
      'shaker.mp3',
      'woodblock.mp3',
      '00.mp3',
      '01.mp3',
      '02.mp3',
      '03.mp3',
      '04.mp3',
      '05.mp3',
      '06.mp3',
      '07.mp3',
      '08.mp3',
      '09.mp3',
      '10.mp3',
      '11.mp3',
      '12.mp3',
      '13.mp3',
      '14.mp3',
      '15.mp3',
      '16.mp3',
      '17.mp3',
      '18.mp3',
      '19.mp3',
      '20.mp3',
      '21.mp3',
      '22.mp3',
      '23.mp3',
    ]);
    print('HF:   ...done loading mp3 files');
  }
*/

  void initAndroid() {
    // initialize the audio engine
    fop.init(mode: MODE.LOW_LATENCY);
    int loadCount = 0;

    // load the sound sample files
    rootBundle.load('assets/sounds/bass_drum_fade.ogg').then((ogg0) {
      fop.load(
          src: ogg0,
          name: 'bass_drum_fade.ogg',
          index: 0,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 0');
      loadCount++;
    });
    rootBundle.load('assets/sounds/kick_drum.ogg').then((ogg1) {
      fop.load(
          src: ogg1,
          name: 'kick_drum.ogg',
          index: 1,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 1');
      loadCount++;
    });
    rootBundle.load('assets/sounds/snare_drum.ogg').then((ogg2) {
      fop.load(
          src: ogg2,
          name: 'snare_drum.ogg',
          index: 2,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 2');
      loadCount++;
    });
    rootBundle.load('assets/sounds/high_hat.ogg').then((ogg3) {
      fop.load(
          src: ogg3,
          name: 'high_hat.ogg',
          index: 3,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 3');
      loadCount++;
    });
    rootBundle.load('assets/sounds/cowbell.ogg').then((ogg4) {
      fop.load(
          src: ogg4,
          name: 'cowbell.ogg',
          index: 4,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 4');
      loadCount++;
    });
    rootBundle.load('assets/sounds/tambourine.ogg').then((ogg5) {
      fop.load(
          src: ogg5,
          name: 'tambourine.ogg',
          index: 5,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 5');
      loadCount++;
    });
    rootBundle
        .load('assets/sounds/Bass74MapleJazzA1_5sTrimEnvelope2dB.ogg')
        .then((ogg6) {
      fop.load(
          src: ogg6,
          name: 'Bass74MapleJazzA1_5sTrimEnvelope2dB.ogg',
          index: 6,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 6');
      loadCount++;
    });
    rootBundle.load('assets/sounds/fingersnap.ogg').then((ogg7) {
      fop.load(
          src: ogg7,
          name: 'fingersnap.ogg',
          index: 7,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 7');
      loadCount++;
    });
    rootBundle.load('assets/sounds/sidestick.ogg').then((ogg8) {
      fop.load(
          src: ogg8,
          name: 'sidestick.ogg',
          index: 8,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 8');
      loadCount++;
    });
    rootBundle.load('assets/sounds/shaker.ogg').then((ogg9) {
      fop.load(
          src: ogg9,
          name: 'shaker.ogg',
          index: 9,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 9');
      loadCount++;
    });
    rootBundle.load('assets/sounds/woodblock1.ogg').then((ogg10) {
      fop.load(
          src: ogg10,
          name: 'woodblock1.ogg',
          index: 10,
          forceLoad: true,
          replace: false);
      print('HF: finished loading ogg file 10');
      loadCount++;
    });
    print('HF: loadCount = $loadCount');
  }

  // play a single sound from the index i sample loaded earlier, transposed
  // by n semitones
  void play(int voices, int note1, int transpose1, int note2, int transpose2) {
    if (Platform.isAndroid) {
//    print('HF: oggPiano.play voices: $voices, note1: $note1, transpose1: $transpose1, note2:$note2, transpose2: $transpose2');

      if (voices == 1) {
        if (note1 != -1) {
//        print('HF:   1 voice');
          fop.play(index: note1, note: transpose1, pan: 0.0);
          return;
        }
      } else if (voices == 2) {
        if (note1 == -1 && note2 != -1) {
//          print('HF:  2 voices, 1 note, note: $note2, transpose: $transpose2');
          // play note 2 as a single note
          fop.play(index: note2, note: transpose2, pan: 0.0);
          return;
        }
        if (note2 == -1 && note1 != -1) {
//          print('HF:  2 voices, 1 note, note: $note1, transpose: $transpose1');
          // play note 1 as a single note
          fop.play(index: note1, note: transpose1, pan: 0.0);
          return;
        }
        if (note1 == -1 && note2 == -1) {
          // nothing to play
          return;
        }
        if (note1 != -1 && note2 != -1) {
//          print('HF:  2 voices, 2 notes');
          // play both notes at the same time
          Map<int, List<Float64List>> map = Map();
          List<Float64List> sounds1 = [];
          List<Float64List> sounds2 = [];
          Float64List list1 = Float64List(3);
          Float64List list2 = Float64List(3);

          list1[0] = transpose1.toDouble(); // pitch
          list1[1] = 0.0; // pan
          list1[2] = 0.95; // scale
          sounds1.add(list1);
          map[note1] = sounds1;

          list2[0] = transpose2.toDouble(); // pitch
          list2[1] = 0.0; // pan
          list2[2] = 0.95; // scale
          sounds2.add(list2);
          map[note2] = sounds2;

          fop.playInGroup(map);
          return;
        }
      }
    } else if (Platform.isIOS) {
      // inset iOS code here
      if (voices == 1) {
        if (note1 != -1) {
          print('HF:   1 voice, note = $note1');
//          ac.play(mp3Map[note1]!);
          pool.play(soundIdMap[note1]!);
          return;
        }
      } else if (voices == 2) {
        if (note1 == -1 && note2 != -1) {
//          print('HF:  2 voices, 1 note, note: $note2, transpose: $transpose2');
          // play note 2 as a single note
//          ac.play(mp3Map[note2]!);
          pool.play(soundIdMap[note2]!);
          return;
        }
        if (note2 == -1 && note1 != -1) {
//          print('HF:  2 voices, 1 note, note: $note1, transpose: $transpose1');
          // play note 1 as a single note
//          ac.play(mp3Map[note1]!);
          pool.play(soundIdMap[note1]!);
          return;
        }
        if (note1 == -1 && note2 == -1) {
          // nothing to play
          return;
        }
        if (note1 != -1 && note2 != -1) {
//          ac.play(mp3Map[note1]!);
//          ac.play(mp3Map[note2]!);
          pool.play(soundIdMap[note1]!);
          pool.play(soundIdMap[note2]!);
        }
      }
    }
  }

  void depose() {
    if (Platform.isAndroid) {
      fop.release();
    } else if (Platform.isIOS) {
      pool.release();
    }
  }
}
