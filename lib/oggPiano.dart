import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_ogg_piano/flutter_ogg_piano.dart';

final OggPiano oggpiano = new OggPiano();

// Mapping from note name to ogg voice number
var oggMap = <String, num>{
  'Bass drum':0,
  'Kick drum':1,
  'Snare drum':2,
  'Hi-hat Cymbal':3,
  'Cowbell':4,
  'Tambourine':5,
  'Fingersnap':7,
  'Rim shot':8,
  'Shaker':9,
  'Woodblock':10,
};

// Mapping from note name to single character reference.  Note
// that this can't be done by grabbing the first character since
// there are two notes starting with 'S'.
var initialMap = <String, String>{
  'Bass drum':'B',
  'Kick drum':'K',
  'Snare drum':'S',
  'Hi-hat Cymbal':'H',
  'Cowbell':'C',
  'Tambourine':'T',
  'Fingersnap':'F',
  'Rim shot':'R',
  'Shaker':'A',
  'Woodblock':'W',
};

class OggPiano {

  final fop = FlutterOggPiano();

  void init() {
    // initialize the audio engine
    fop.init(mode: MODE.LOW_LATENCY);

    // load the sound sample files
    rootBundle.load('assets/sounds/bass_drum.ogg').then((ogg) {
      fop.load(src: ogg, name: 'bass_drum.ogg', index: 0, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/kick_drum.ogg').then((ogg) {
      fop.load(src: ogg, name: 'kick_drum.ogg', index: 1, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/snare_drum.ogg').then((ogg) {
      fop.load(src: ogg, name: 'snare_drum.ogg', index: 2, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/high_hat.ogg').then((ogg) {
      fop.load(src: ogg, name: 'high_hat.ogg', index: 3, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/cowbell.ogg').then((ogg) {
      fop.load(src: ogg, name: 'cowbell.ogg', index: 4, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/tambourine.ogg').then((ogg) {
      fop.load(src: ogg, name: 'tambourine.ogg', index: 5, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/Bass74MapleJazzA1_1sTrim.ogg').then((ogg) {
      fop.load(src: ogg, name: 'Bass74MapleJazzA1_1sTrim.ogg', index: 6, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/fingersnap.ogg').then((ogg) {
      fop.load(src: ogg, name: 'fingersnap.ogg', index: 7, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/sidestick.ogg').then((ogg) {
      fop.load(src: ogg, name: 'sidestick.ogg', index: 8, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/shaker.ogg').then((ogg) {
      fop.load(src: ogg, name: 'shaker.ogg', index: 9, forceLoad: true, replace: true);
    });
    rootBundle.load('assets/sounds/woodblock1.ogg').then((ogg) {
      fop.load(src: ogg, name: 'woodblock1.ogg', index: 10, forceLoad: true, replace: true);
    });
  }

  // play a single sound from the index i sample loaded earlier, transposed
  // by n semitones
  void play(int voices, int note1, int transpose1, int note2, int transpose2) {
    print('HF: oggPiano.play voices: $voices, note1: $note1, transpose1: $transpose1, note2:$note2, transpose2: $transpose2');

    if (voices == 1) {
      if (note1 != -1) {
        fop.play(index: note1, note: transpose1, pan: 0.0);
        return;
      }
    } else if (voices == 2) {
        if (note1 == -1 && note2 != -1) {
          // play note 2 as a single note
          fop.play(index: note2, note: transpose2, pan: 0.0);
          return;
        }
        if (note2 == -1 && note1 != -1) {
          // play note 1 as a single note
          fop.play(index: note1, note: transpose1, pan: 0.0);
          return;
        }
        if (note1 == -1 && note2 == -1) {
          // nothing to play
          return;
        }
        if (note1 != -1 && note2 != -1) {
          // play both notes at the same time
          Map<int, List<Float64List>> map = Map();
          List<Float64List> sounds1 = [];
          List<Float64List> sounds2 = [];
          Float64List list1 = Float64List(3);
          Float64List list2 = Float64List(3);

          list1[0] = transpose1.toDouble();  // pitch
          list1[1] = 0.0;   // pan
          list1[2] = 0.95;  // scale
          sounds1.add(list1);
          map[note1] = sounds1;

          list2[0] = transpose2.toDouble();  // pitch
          list2[1] = 0.0;   // pan
          list2[2] = 0.95;  // scale
          sounds2.add(list2);
          map[note2] = sounds2;

          fop.playInGroup(map);
          return;
        }
    }

  }


  void depose() {
     fop.release();
  }

}
