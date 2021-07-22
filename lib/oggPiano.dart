import 'package:flutter/services.dart';
import 'package:flutter_ogg_piano/flutter_ogg_piano.dart';

final OggPiano oggpiano = new OggPiano();

class OggPiano {

  final fop = FlutterOggPiano();

  void init() {
    // initialize the audio engine
    fop.init(mode: MODE.LOW_LATENCY);

    // load the sound sample files
    rootBundle.load('assets/sounds/bass_drum.ogg').then((ogg) {
      fop.load(src: ogg, name: 'bass_drum.ogg', index: 0, forceLoad: true);
    });
    rootBundle.load('assets/sounds/kick_drum.ogg').then((ogg) {
      fop.load(src: ogg, name: 'kick_drum.ogg', index: 1, forceLoad: true);
    });
    rootBundle.load('assets/sounds/snare_drum.ogg').then((ogg) {
      fop.load(src: ogg, name: 'snare_drum.ogg', index: 2, forceLoad: true);
    });
    rootBundle.load('assets/sounds/high_hat.ogg').then((ogg) {
      fop.load(src: ogg, name: 'high_hat.ogg', index: 3, forceLoad: true);
    });
    rootBundle.load('assets/sounds/cowbell.ogg').then((ogg) {
      fop.load(src: ogg, name: 'cowbell.ogg', index: 4, forceLoad: true);
    });
    rootBundle.load('assets/sounds/tambourine.ogg').then((ogg) {
      fop.load(src: ogg, name: 'tambourine.ogg', index: 5, forceLoad: true);
    });
    rootBundle.load('assets/sounds/Bass74MapleJazzA1.ogg').then((ogg) {
      fop.load(src: ogg, name: 'Bass74MapleJazzA1.ogg', index: 6, forceLoad: true);
    });
  }

  // play a single sound from the index i sample loaded earlier, transposed
  // by n semitones
  void play(int i, int n) {
    fop.play(index: i, note: n, pan: 0.0);
  }

  // play multiple sounds using a map to pass the details of the
  // sounds to be played.  Each key will be ID, and double[]
  // contains [pitch, left_volume, right_volume].
//  void playChord(Map<int, List<Float64List>> map) {
//    fop.playInGroup(map);
//  }

  void depose() {
     fop.release();
  }

}