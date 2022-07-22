import 'audio.dart';
import 'dart:async';
import 'bass.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;

Note note = new Note(0, "Bass drum");
Groove groove = new Groove.empty(1, 1, GrooveType.percussion);

enum GrooveType { percussion, bass, guitarChords, pianoChords }

// 1-tap rhythm types from:
//    https://www.midwestclinic.org/user_files_1/pdfs/clinicianmaterials/2005/victor_lopez.pdf
enum RhythmType {
  rock1,
  rock2,
  jazz1,
  bossanova,
  afrocuban68,
  salsa,
  mambo,
  songo,
  chachacha,
  merengue,
  bolero,
  samba
}

class Note {
  int? oggIndex; // the index of the ogg file sample
  int?
      oggNote; // the number of semitones to transpose from the .ogg file sample
  String? name;
  String? initial;

  Note(int index, String name) {
    this.oggIndex = index;
    this.oggNote = 0;
    this.name = name;
    this.initial = initialMap[name];
  }

  Note.empty();

  copyFrom(Note from) {
    this.oggIndex = from.oggIndex;
    this.oggNote = from.oggNote;
    this.name = from.name;
    this.initial = from.initial;
  }
}

class Groove {
  int bpm = 1; // number of beat per measure
  int numMeasures = 1; // number of measures
  int voices = 1;
  bool interpolate =
      false; // a flag to control interpolation mode aka back beat
  // in interpolate mode, every 2nd note in the groove is played at a time
  // predicted from 1/2 of the period
  bool oneTap = false; // a flag to indicate 1-tap rhythm mode where
  // the first 4 foot taps are used as a lead-in and then there is
  // only a foottap on the "1" beat.  All other beats are interpolated
  // from the last beat period and set as timers.
  int index = 0; // pointer to next note to play
  int leadInCount =
      4; // number of beats to skip at the start in interpolate mode
  int lastSequenceBit = -1; // sequence bit of last notify received
  // note that -1 is used to indicate that a first beat has not yet been received
  final timeBuffer =
      CircularBuffer<int>(4); // circular buffer of beat delta timestamps
  final sysTimeBuffer = CircularBuffer<double>(
      4); // circular buffer of system timestamp deltas in ms
  DateTime lastBeatTime = DateTime.now(); // get system time
  double beatsPerMinute = 0.0;
  double sysFilteredBPM = 0.0;
  double sum = 0;
  double sum2 = 0;
  double variation = 0.0;
  double beatSubdivisionInMs = 0.0;
  List notes = <Note>[]; // list of notes
  List notes2 = <Note>[]; // list of notes
  String key = 'E';
  GrooveType type = GrooveType.percussion;
  String description = '';
  var bpmString = '---'.obs;
  var bpmColor = Colors.white;
  var indexString = 'beat 1'.obs;
  var leadInString = '0'.obs;
  // variables for practice mode: instantaneous BPM, current streaks
  // within +/- 1, 3, and 5 BPM of target
  var practiceBPM = 0.0.obs;
  var practiceStreak1 = 0.obs;
  var practiceStreak3 = 0.obs;
  var practiceStreak5 = 0.obs;
  var targetTempo = 120.obs;
  var practiceColor = Colors.white;
  bool firstBeat = true;
  int runCount = 0;
  bool practice = false;

  // constructor with list of notes
  Groove(int beats, int measures, List notes, List notes2, GrooveType type) {
    this.bpm = beats;
    this.numMeasures = measures;
    this.index = 0;
    this.lastSequenceBit = -1;
    this.notes = notes;
    this.notes2 = notes2;
    this.type = type;
    this.voices = 1;
    this.interpolate = false;
    this.runCount = 0;

    // add notes
    for (int i = 0; i < (beats * measures); i++) {
      this.notes.add(null);
      this.notes[i].name = 'none';
      this.notes[i].oggIndex = -1;
      this.notes[i].oggNote = 0;
      this.notes[i].initial = '-';

      this.notes2.add(null);
      this.notes2[i].name = 'none';
      this.notes2[i].oggIndex = -1;
      this.notes2[i].oggNote = 0;
      this.notes2[i].initial = '-';
    }

    this.key = 'E';
  }

  // constructor without list of notes
  Groove.empty(int beats, int measures, GrooveType type) {
    this.bpm = beats;
    this.numMeasures = measures;
    this.voices = 1;
    this.index = 0;
    this.interpolate = false;
    this.lastSequenceBit = -1;
    this.notes = List<Note>.generate(beats * measures, (i) {
      return Note(-1, "-");
    });
    this.notes2 = List<Note>.generate(beats * measures, (i) {
      return Note(-1, "-");
    });
    this.type = type;
    this.runCount = 0;
  }

  String untranslateNoteName(String note) {
    String result = "-";
    if (note == 'none'.tr) {
      result = 'none';
    } else if (note == 'Bass drum'.tr) {
      result = 'Bass drum';
    } else if (note == 'Bass echo'.tr) {
      result = 'Bass echo';
    } else if (note == 'Lo tom'.tr) {
      result = 'Lo tom';
    } else if (note == 'Hi tom'.tr) {
      result = 'Hi tom';
    } else if (note == 'Snare drum'.tr) {
      result = 'Snare drum';
    } else if (note == 'Hi-hat cymbal'.tr) {
      result = 'Hi-hat cymbal';
    } else if (note == 'Cowbell'.tr) {
      result = 'Cowbell';
    } else if (note == 'Tambourine'.tr) {
      result = 'Tambourine';
    } else if (note == 'Fingersnap'.tr) {
      result = 'Fingersnap';
    } else if (note == 'Rim shot'.tr) {
      result = 'Rim shot';
    } else if (note == 'Shaker'.tr) {
      result = 'Shaker';
    } else if (note == 'Woodblock'.tr) {
      result = 'Woodblock';
    } else if (note == 'Brushes'.tr) {
      result = 'Brushes';
    } else if (note == 'Quijada'.tr) {
      result = 'Quijada';
    }
    return result;
  }

  // initialize the groove in single note mode
  initSingle(String name) {
    String trName = untranslateNoteName(name);
    this.resize(1, 1, 1);
    this.interpolate = false;
    this.notes[0].oggIndex = oggMap[trName];
    this.notes[0].oggNote = 0;
    this.notes[0].name = trName;
    this.notes[0].initial = initialMap[trName];
    this.oneTap = false;
    this.reset();
  }

  // initialize the groove in alternating note mode
  initAlternating(String name1, String name2) {
    String trName1 = untranslateNoteName(name1);
    String trName2 = untranslateNoteName(name2);
    this.resize(2, 1, 1);
    this.interpolate = false;
    this.notes[0].oggIndex = oggMap[trName1];
    this.notes[0].oggNote = 0;
    this.notes[0].name = trName1;
    this.notes[0].initial = initialMap[trName1];

    this.notes[1].oggIndex = oggMap[trName2];
    this.notes[1].oggNote = 0;
    this.notes[1].name = trName2;
    this.notes[1].initial = initialMap[trName2];

    this.oneTap = false;
    this.reset();
  }

  // initialize the groove in dual note mode
  initDual(String name1, String name2) {
    String trName1 = untranslateNoteName(name1);
    String trName2 = untranslateNoteName(name2);
    this.resize(1, 1, 2);
    this.interpolate = false;
    this.notes[0].oggIndex = oggMap[trName1];
    this.notes[0].oggNote = 0;
    this.notes[0].name = trName1;
    this.notes[0].initial = initialMap[trName1];

    this.notes2[0].oggIndex = oggMap[trName2];
    this.notes2[0].oggNote = 0;
    this.notes2[0].name = trName2;
    this.notes2[0].initial = initialMap[trName2];

    this.oneTap = false;
    this.reset();
  }

  reset() {
    this.index = 0;
    this.lastSequenceBit = -1;
    this.leadInCount = 4;
    this.leadInString.value = '4';
    this.firstBeat = true;
  }

  // increment the index to the next note to be played
  incrementIndex() {
    this.index = (this.index + 1) % (this.bpm * this.numMeasures);
  }

  // go to the next beat 1
  nextBeat1() {
    if (this.numMeasures == 1) {
      //  if there is only one measure, reset index to 0
      this.index = 0;
    } else {
      // if there are more than one measure, set index to next beat 1
      int measure = this.index ~/ this.bpm;
      this.index = ((measure + 1) % this.numMeasures) * this.bpm;
    }
  }

  // retain the bpm and numMeasures but set all notes to -
  // used when changing between groove and bass mode
  void clearNotes() {
    for (int i = 0; i < this.bpm * this.numMeasures; i++) {
      this.notes[i].name = '-';
      this.notes[i].oggIndex = -1;
      this.notes[i].oggNote = 0;
      this.notes[i].initial = '-';

      this.notes2[i].name = '-';
      this.notes2[i].oggIndex = -1;
      this.notes2[i].oggNote = 0;
      this.notes2[i].initial = '-';
    }
    this.voices = 1;
  }

  // add a note to the groove using its initial only
  void addInitialNote(int index, String initial) {
    int _oggIndex = -1;
    int _oggNote = 0;
    String _name = '-';
    int _voices = this.voices;

    if (kDebugMode) {
      print(
          'HF: addInitialNote: index = $index, initial = $initial, _voices = $_voices');
    }

    switch (initial) {
      case '-':
        {
          _oggIndex = -1;
          _oggNote = 0;
          _name = '-';
        }
        break;
      case 'b':
        {
          _oggIndex = 0;
          _oggNote = 0;
          _name = 'Bass drum';
        }
        break;
      case 'B':
        {
          _oggIndex = 1;
          _oggNote = 0;
          _name = 'Bass echo';
        }
        break;
      case 'S':
        {
          _oggIndex = 2;
          _oggNote = 0;
          _name = 'Snare drum';
        }
        break;
      case 'H':
        {
          _oggIndex = 3;
          _oggNote = 0;
          _name = 'High Hat Cymbal';
        }
        break;
      case 'C':
        {
          _oggIndex = 4;
          _oggNote = 0;
          _name = 'Cowbell';
        }
        break;
      case 'M':
        {
          _oggIndex = 5;
          _oggNote = 0;
          _name = 'Tambourine';
        }
        break;
      case 'F':
        {
          _oggIndex = 7;
          _oggNote = 0;
          _name = 'Fingersnap';
        }
        break;
      case 'R':
        {
          _oggIndex = 8;
          _oggNote = 0;
          _name = 'Rim shot';
        }
        break;
      case 'A':
        {
          _oggIndex = 9;
          _oggNote = 0;
          _name = 'Shaker';
        }
        break;
      case 'W':
        {
          _oggIndex = 10;
          _oggNote = 0;
          _name = 'Woodblock';
        }
        break;
      case 't':
        {
          _oggIndex = 11;
          _oggNote = 0;
          _name = 'Lo tom';
        }
        break;
      case 'T':
        {
          _oggIndex = 12;
          _oggNote = 0;
          _name = 'Hi tom';
        }
        break;
      case 'U':
        {
          _oggIndex = 13;
          _oggNote = 0;
          _name = 'Brushes';
        }
        break;
      case 'Q':
        {
          _oggIndex = 14;
          _oggNote = 0;
          _name = 'Quijada';
        }
        break;
      default:
        {
          _oggIndex = -1;
          _oggNote = 0;
          _name = '-';
        }
    }

    if (this.voices == 1) {
      this.notes[index].oggIndex = _oggIndex;
      this.notes[index].oggNote = _oggNote;
      this.notes[index].name = _name;
      this.notes[index].initial = initial;
      if (kDebugMode) {
        print(
            'HF: addInitialNote single voice: index = $index, oggIndex = $_oggIndex, oggnote = $_oggNote, name = $_name');
      }
    } else if (this.voices == 2) {
      var _measure = index ~/ this.bpm;
      var _beat = index % this.bpm;
      var _i = (_measure ~/ 2) * this.bpm + _beat;
      if (kDebugMode) {
        print(
            'HF: addInitialNote dual voice: _measure = $_measure, _beat = $_beat, _i = $_i');
      }
      if (_measure.isEven) {
        if (kDebugMode) {
          print(
              'HF: addInitialNote dual voice: notes _i = $_i, index = $index, oggIndex = $_oggIndex, oggnote = $_oggNote, name = $_name');
        }
        this.notes[_i].oggIndex = _oggIndex;
        this.notes[_i].oggNote = _oggNote;
        this.notes[_i].name = _name;
        this.notes[_i].initial = initial;
      } else {
        if (kDebugMode) {
          print(
              'HF: addInitialNote dual voice: notes2 _i = $_i, index = $index, oggIndex = $_oggIndex, oggnote = $_oggNote, name = $_name');
        }
        this.notes2[_i].oggIndex = _oggIndex;
        this.notes2[_i].oggNote = _oggNote;
        this.notes2[_i].name = _name;
        this.notes2[_i].initial = initial;
      }
    }
  }

  // change the key of a bass groove
  changeKey(String? keyName) {
    String roman;
    int romanIndex;
    String key;
    if (keyName == null) {
      key = 'E';
    } else {
      key = keyName;
    }
    this.key = key;

    // loop over all of the notes in the groove
    for (int i = 0; i < this.bpm * this.numMeasures; i++) {
      if (this.notes[i].name != '-') {
        // ignore empty notes
        romanIndex = this.notes[i].name.indexOf('-') + 1;
        roman = this.notes[i].name.substring(romanIndex); //
        this.addBassNote(i, roman, key);
      }
    }
  }

  // add a bass note to the groove using the arabic numeral and which key
  // we're in currently e.g. key of C, 3 would be E.
  addBassNote(int index, String arabic, String keyName) {
    // if no note is to be played, as indicated by -,
    // then set oggIndex to -1 and name and initial to -
    if (arabic == '-') {
      this.notes[index].name = '-';
      this.notes[index].initial = '-';
      this.notes[index].oggIndex = -1;
      this.notes[index].oggNote = 0;
    } else {
      // create a name by concatenating the key name, a "-" and the
      // arabic numeral,  e.g. C-4
      this.notes[index].name = keyName + '-' + arabic;
      this.notes[index].initial = arabic;

      // get the index of the keyName
      int keyIndex = keys.indexWhere((element) => element == keyName);
      if (kDebugMode) {
        print('HF: addBassNote: keyName = $keyName, keyIndex = $keyIndex');
      }

      // get the index of the roman numeral
      if (arabic == 'none') {
        arabic = '-';
      }
      int arabicIndex =
          scaleTonesArabic.indexWhere((element) => element == arabic);
      if (kDebugMode) {
        print('HF: addBassNote: arabic = $arabic');
        print('HF: addBassNote: arabicIndex = $arabicIndex');
      }

      int offset = scaleTonesIndex[arabicIndex];
      if (kDebugMode) {
        print('HF: addBassNote: offset = $offset');
      }

      if (Platform.isAndroid) {
        //this.notes[index].oggIndex = 6;
        this.notes[index].oggIndex = E1ogg + keyIndex + offset;

        // create the oggNote by adding the following:
        //   the MIDI code for E1
        //   the key (starting from E)
        //   the roman numeral offset from the tonic
        // and subtracting the MIDI code for the sample file
        //this.notes[index].oggNote = E1midi + keyIndex + offset - A1midi;

        // in the current scheme, there is an individual ogg file for each bass
        // note, so no transposing is needed.
        this.notes[index].oggNote = 0;
      } else if (Platform.isIOS) {
        // create the oggNote by adding the following:
        //   the key (starting from E)
        //   the roman numeral offset from the tonic
        //   the starting mp3 index in soundIdMap in audio.dart
        int _temp = keyIndex + offset + E1mp3;
        assert(_temp < E1mp3);
        assert(_temp > (E1mp3 + 23));
        this.notes[index].oggIndex = _temp;
      }
    }
  }

  // return an initial to be used as shorthand for a note's name.
  // Generally, the initial is the first letter of the name.  The
  // exception is Shaker which uses  K as its initial since S is
  // already used by Snare drum.
  String initialNote(int index) {
    return initialMap[this.notes[index].name]!;
  }

  // return the type of this groove
  String getType() {
    String type;
    switch (this.type) {
      case GrooveType.percussion:
        {
          type = 'percussion';
        }
        break;
      case GrooveType.bass:
        {
          type = 'bass';
        }
        break;
      default:
        {
          type = 'percussion';
        }
        break;
    }
    return (type);
  }

  // check the type of this groove and change it if necessary.  If changing the
  // groove type, clear all of the notes
  void checkType(String type) {
    if (kDebugMode) {
      print('HF: checkType: type = $type');
    }
    if ((type == 'percussion') && (this.type != GrooveType.percussion)) {
      this.type = GrooveType.percussion;
      if (kDebugMode) {
        print('HF: checkType: changing type to percussion');
      }
      this.clearNotes();
      hfaudio.init();
    }
    if ((type == 'bass') && (this.type != GrooveType.bass)) {
      this.type = GrooveType.bass;
      if (kDebugMode) {
        print('HF: checkType: changing type to bass');
      }
      this.clearNotes();
      this.interpolate = false; // turn off backbeat mode when change to bass
      hfaudio.init();
    }
  }

  // return a list of initials of the current groove notes
  // max number of beats in groove is:
  //    max beats per measure = 8
  //    max measures = 12
  //    max voices = 2
  //    total = 8 x 12 x 2
  // In single voice mode, the notes are listed by beat then measure
  // e.g. <B0, M0>, <B1, M0>, <B0, M1>, <B1, M1> for a 2 BPM, 2 measure groove
  // In dual voice mode, the notes are listed by beat, voice, then measure
  // For a 2 BPM, 2 voice, 2 measure groove, they are listed as:
  // e.g. <B0, V0, M0>, <B0, V1, M0>, <B1, V0, M0>, <B1, V1, M0>...
  // The reason for this is that there is a difference between how beats are
  // shown on the screen (with the voices on separate lines) vs
  // how they are played
  List<String> getInitials() {
    int _beats = this.bpm * this.numMeasures * this.voices;
//    print('HF: getInitials: _beats = $_beats');
//    String _currentGroove = this.toCSV('groove snapshot in getInitials');
//    print('HF:    _currentGroove = $_currentGroove');
    var initialList = new List<String>.filled(_beats, '-');
    for (int i = 0; i < _beats; i++) {
      if (this.type == GrooveType.percussion) {
//        print('HF:    groove type = percussion');
        if (voices == 1) {
//           print('HF:   voices = 1');
          initialList[i] = this.notes[i].initial;
//           String _x = this.notes[i].initial;
//           print('HF: i = $i, _x = $_x');
        } else {
//          print('HF:    voices = 2');
          var _measure = i ~/ this.bpm;
          var _beat = i % this.bpm;
          var _x = (_measure ~/ 2) * this.bpm + _beat;
          if (_measure.isEven) {
            initialList[i] = this.notes[_x].initial;
//            String _y = this.notes[_x].initial;
//            print('HF:    voice 1: _x = $_x, this.notes[_x].initial = $_y');
          } else {
            initialList[i] = this.notes2[_x].initial;
//            String _y = this.notes2[_x].initial;
//            print('HF:    voice 2: _x = $_x, this.notes2[_x].initial = $_y');
          }
        }
      } else if (this.type == GrooveType.bass) {
        if (this.notes[i].name == '-') {
          initialList[i] = '-';
        } else {
          int hyphenIndex = this.notes[i].name.indexOf('-') + 1;
          initialList[i] = this.notes[i].name.substring(hyphenIndex);
        }
      }
    }
    if (kDebugMode) {
      print('HF: getInitials: initialList = $initialList');
    }
    return initialList;
  }

  // resize the groove
  // TODO: if increasing the number of beats per measure, duplicate the last beat(s)
  // TODO: if increasing the number of measures, duplicate the last measure
  void resize(int beat, int measure, int voices) {
    var origBpm = this.bpm;
    var origMeasures = this.numMeasures;
    this.bpm = beat;
    this.numMeasures = measure;
    this.voices = voices;
    this.index = 0;
    final beats = beat * measure;

    // if the list of notes is too long
    if (this.notes.length > beats) {
      var numToRemove = this.notes.length - beats;
      var notesLength = this.notes.length;
      var notes2Length = this.notes2.length;
      if (kDebugMode) {
        print(
            "HF: resize groove removing $numToRemove notes, beat = $beat, measure = $measure, notes length = $notesLength, notes2 length = $notes2Length");
      }
      // remove the extra items
      this.notes.removeRange(beats - 1, this.notes.length - 1);
      this.notes2.removeRange(beats - 1, this.notes2.length - 1);
    } else if (this.notes.length < beats) {
      // if the list is too short
      var numToAdd = beats - this.notes.length;
      var notesLength = this.notes.length;
      var notes2Length = this.notes2.length;
      if (kDebugMode) {
        print(
            "HF: resize groove adding $numToAdd notes, beat = $beat, measure = $measure, notes length = $notesLength, notes2 length = $notes2Length");
      }
      for (var i = 0; i < numToAdd; i++) {
        // add items to the list
        if (kDebugMode) {
          print('    i = $i');
        }
        this.notes.add(Note(-1, "-"));
        if (kDebugMode) {
          print('    ... added to Note');
        }
        this.notes2.add(Note(-1, "-"));
        if (kDebugMode) {
          print('    ... added to Note2');
        }
      }
      // if adding measures...
      if (measure > origMeasures) {
        if (kDebugMode) {
          print('HF:  resize: adding measures');
        }
        var measuresToAdd = measure - origMeasures;
        var copyFromStart = (origMeasures - 1) * origBpm;
        for (int i = 0; i < measuresToAdd; i++) {
          var copyToStart = (origMeasures + i) * beat;
          for (int n = 0; n < beat; n++) {
            var src = copyFromStart + n;
            var dest = copyToStart + n;
            this.notes[dest].copyFrom(this.notes[src]);
            this.notes2[dest].copyFrom(this.notes2[src]);
            if (kDebugMode) {
              print('HF: resize: copying from $src to $dest');
            }
          }
        }
      }
    }
    // print out the resized groove
    this.printGroove();

    this.reset();
  }

  // initialize the groove
  void initialize(int beat, int measure, int voices) {
    this.bpm = beat;
    this.numMeasures = measure;
    this.voices = voices;
    this.index = 0;

    // delete all existing notes
    this.notes.clear();
    this.notes2.clear();

    // add in the number of notes that will be needed
    for (int i = 0; i < this.bpm * this.numMeasures; i++) {
      this.notes.add(Note(-1, '-'));
      this.notes2.add(Note(-1, '-'));
    }

    return;
  }

  // set the color of the BeatsPerMinute indicator on the bottom app bar based on the
  // beat timing variation.
  // found that the colors were visually distracting to stayed with white in the end...
  void variationToColor() {
    if ((variation > -10.0) && (variation < 10.0)) {
      bpmColor = Colors.white;
    } else if (variation >= 10.0) {
      bpmColor = Colors.red[100]!;
    } else if (variation <= -10.0) {
      bpmColor = Colors.lime[100]!;
    }
    bpmColor = Colors.white;
    return;
  }

// update the BPM and measure:beat info for the Bottom App Bar
  void updateBABInfo() {
    // update the BPM and index info on the bottom app bar
    // if variation is high, or BPM is non-sensical i.e. < 0 or > 320, then show '---'
    if ((variation.abs() < 50.0) &&
        ((sysFilteredBPM > 20.0) && (sysFilteredBPM < 320.0))) {
      bpmString.value = sysFilteredBPM.toStringAsFixed(1);
    } else {
      bpmString.value = '---';
    }
    if (this.numMeasures == 1) {
      indexString.value = 'beat ' + (this.index + 1).toString();
    } else {
      int _beat = (this.index % this.bpm) + 1;
      int _meas = (this.index ~/ this.bpm) + 1;
      indexString.value = _meas.toString() + ":" + _beat.toString();
    }
    variationToColor();
  }

// update the practice mode streak counts: the number of successive
// beats within +/-X BPM of the target tempo where X is 1, 3 and 5.
  void updateStreakCounts() {
    var err = 0;

    err = this.targetTempo.value - this.practiceBPM.value.toInt();

    // set the background color based on the sign of the error:
    // red if going too fast, green if going too slow, blue otherwise
    if (err < -5) {
      practiceColor = Colors.red;
    } else if (err > 5) {
      practiceColor = Colors.green;
    } else {
      practiceColor = Colors.blue;
    }

    // absolute value of error, used by the streak couters below
    if (err < 0) {
      err = err * -1;
    }

    if (err <= 5) {
      this.practiceStreak5++;
    } else {
      this.practiceStreak5.value = 0;
    }
  }

  // play the next note in the groove
  void play(int data) {
    int sequenceBit;
    double mean2;
    var now = DateTime.now(); // get system time
//    print(
//        'HF:   Time: $now, Name: ${this.notes[this.index].name}, groove index: ${this.index}, ogg index: ${this.notes[this.index].oggIndex.toString()}, ogg transpose: ${this.notes[this.index].oggNote.toString()}');

    // check for a sequence error
    sequenceBit = (data >> 6) & 0x01;
    if (lastSequenceBit != -1) {
      // ignore the sequence bit on the first notify received is indicated by -1
      if (sequenceBit == lastSequenceBit) {
        Get.snackbar('Sequence error:',
            'A beat was missed, possibly due to a lost Bluetooth notify message',
            snackPosition: SnackPosition.BOTTOM);
        if (kDebugMode) {
          print('HF: sequence error');
        }

        // increment pointer to skip one note
        this.incrementIndex();
      }
    }
    lastSequenceBit = sequenceBit;

    // calculate this beat interval i.e. the time between this beat and the previous
    Duration beatInterval = now.difference(lastBeatTime);
    var beatPeriod =
        beatInterval.inMilliseconds.toDouble(); // convert period to ms

    // update info used by practice mode
    practiceBPM.value = 1000.0 / beatPeriod * 60;
    updateStreakCounts();

    // play the next note in the groove in these cases:
    // i) not in interpolate or 1-tap mode, or
    // ii) in interpolate mode, and
    //     past the lead-in as indicated by leadInCount == 0
    //     index is even i.e. not a back beat
    if ((!groove.interpolate && !groove.oneTap) ||
        (groove.interpolate && (groove.leadInCount == 0)) &&
            (groove.index.isEven)) {
      hfaudio.play(
          this.voices,
          this.notes[this.index].oggIndex,
          this.notes[this.index].oggNote,
          this.notes2[this.index].oggIndex,
          this.notes2[this.index].oggNote);
      // increment pointer to the next note
      this.incrementIndex();
    } else if (groove.interpolate && (groove.leadInCount > 0)) {
      this.leadInCount--;
      this.leadInString.value = this.leadInCount.toString();
      if (kDebugMode) {
        print('HF:  lead-in count decremented to $this.leadInCount');
      }
    }

    // calculate Beats Per Minute using system time
    final first2 = sysTimeBuffer.isFilled ? sysTimeBuffer.first : 0;
    sysTimeBuffer.add(
        beatPeriod); // add the latest sys time interval to the circular buffer
    sum2 += sysTimeBuffer.last - first2; // update the running sum
    mean2 = sum2 / sysTimeBuffer.length; // calculate the mean delta time
    double sysLatestBPM = (60000.0 / beatPeriod);
    sysFilteredBPM = (60000.0 / mean2);
    if (this.oneTap && !this.firstBeat) {
      sysFilteredBPM = sysFilteredBPM * this.bpm;
      sysLatestBPM = sysLatestBPM * this.bpm;
    }
    variation = (sysLatestBPM - sysFilteredBPM) / sysFilteredBPM * 100.0;

    // create status string
    String _status = '';
    if (beatPeriod > (mean2 * 1.5)) {
      _status = 'missing';
      runCount = 0;
    } else if (beatPeriod < (mean2 * 0.75)) {
      _status = 'spurious';
      runCount = 0;
    } else {
      runCount++;
    }

//    print(
//        'HF: groove.play: inst period = ${beatPeriod.toStringAsFixed(0)}ms, inst BPM = ${sysLatestBPM.toStringAsFixed(1)}, mean period = ${mean2.toStringAsFixed(0)}ms, mean BPM = ${sysFilteredBPM.toStringAsFixed(1)}, variation = ${variation.toStringAsFixed(1)}%, $_status');

    // print comma separated data for later analysis in Excel
    //    latest beat period,latest BPM,mean beat period,mean BPM,variation
    //    run count, status
    if (kDebugMode) {
      print(
          'HF: groove.play.csv,${beatPeriod.toStringAsFixed(0)},${sysLatestBPM.toStringAsFixed(1)},${mean2.toStringAsFixed(0)},${sysFilteredBPM.toStringAsFixed(1)},${variation.toStringAsFixed(1)}%,$runCount,$_status');
    }
    lastBeatTime = now;

    // interpolate mode: schedule a note to be played at a future time if these conditions are met:
    // i)   in interpolate mode
    // ii)  we're past the lead-in, as indicated by leadInCount == 0
    // iii) variation < 40% i.e. the beat is consistent
    if (groove.interpolate && (groove.leadInCount == 0)) {
      // the index should only be odd at this point.  If not, print an error message
      if (this.index.isEven) {
        if (kDebugMode) {
          print(
              'HF: ERROR: index should only be odd for backbeat!  Incrementing...');
        }
        this.incrementIndex();
      }
      // schedule the next note using a timer.  1/2 of the mean beat interval will be used to
      // schedule the note at the expected mid-point of the beat.
//      var halfPeriodInMs = mean2.toInt() ~/ 2;
      var halfPeriodInMs = beatPeriod.toInt() ~/ 2;
      Timer(Duration(milliseconds: halfPeriodInMs), () {
        if (variation.abs() <= 40.0) {
          // only play the note if the beat is stable i.e. variation < 20%
          hfaudio.play(
              this.voices,
              this.notes[this.index].oggIndex,
              this.notes[this.index].oggNote,
              this.notes2[this.index].oggIndex,
              this.notes2[this.index].oggNote);
        }
        var _interpolateNow = DateTime.now(); // get system time
        if (kDebugMode) {
          print(
              'HF:   Interpolate time: $_interpolateNow, T/2: $halfPeriodInMs ms, groove index: ${this.index}, Name1: ${this.notes[this.index].name}, Name2: ${this.notes2[this.index].name}');
        }
        // increment pointer to the next note
        this.incrementIndex();
      });
    }

    // 1-tap mode: in 1-tap mode, there is a 4 beat lead-in and then the user
    // only taps their foot on the 1s
    if (this.oneTap) {
      // check if we're in the count-in as indicated by leadInCount > 0.
      if (this.leadInCount != 0) {
        // update the lead-in count displayed on the screen
        if (leadInCount > 0) {
          // display 4..1 as the leadInCount decrements from 4 to 1
          leadInString.value = (5 - leadInCount).toString();
          if (kDebugMode) {
            print(
                'HF: oneTap play, lead-in-count = $leadInCount, index=${this.index}, ');
          }
        } else {
          leadInString.value = "---";
        }
        leadInCount--;
      } else {
        // we should be at beat one (index = 0)
        if (this.index % this.bpm != 0) {
          if (kDebugMode) {
            print('HF: 1-tap: error not at beat 1');
          }
          // reset the index to the next beat 1
          this.nextBeat1();
        }
        // play the beat one note
        String _now = DateTime.now().toString();
        if (kDebugMode) {
          print(
              'HF: $_now 1-tap: playing beat 1, notes.length = ${this.notes.length}, index now = ${this.index}');
        }
        hfaudio.play(
            this.voices,
            this.notes[this.index].oggIndex,
            this.notes[this.index].oggNote,
            this.notes2[this.index].oggIndex,
            this.notes2[this.index].oggNote);
        updateBABInfo();
        // increment pointer to the next note
        this.incrementIndex();

        // calculate the duration between beats assuming that the lead-in
        // was in 1/4 notes.  If this is the first beat of a 1-tap groove, the
        // beat period is in 1/4 notes from the lead-in.  If this is not the first
        // beat, then the beat period is for the entire measure.
        if (firstBeat) {
          beatSubdivisionInMs = beatPeriod / (this.bpm / 4);
          firstBeat = false;
        } else {
          beatSubdivisionInMs = beatPeriod / this.bpm;
        }
        if (kDebugMode) {
          print('HF: 1-tap: beat subdivision = $beatSubdivisionInMs ms');
        }

        // schedule the remaining notes to be played using timers
        for (int i = 1; i < this.bpm; i++) {
          Timer(Duration(milliseconds: (beatSubdivisionInMs * i).toInt()), () {
            hfaudio.play(
                this.voices,
                this.notes[this.index].oggIndex,
                this.notes[this.index].oggNote,
                this.notes2[this.index].oggIndex,
                this.notes2[this.index].oggNote);
            updateBABInfo();
            _now = DateTime.now().toString();
            if (kDebugMode) {
              print(
                  'HF: $_now 1-tap: playing beat ${i + 1}, index=${this.index}');
            }
            // increment pointer to the next note
            this.incrementIndex();
          });
        }
      }
    }

    if (!oneTap) {
      updateBABInfo();
    }
  }

  // restart by setting index to 0
  void restart() {
    this.index = 0;
    this.leadInCount = 4;
  }

  // Grooves are saved to and loaded from comma separated variable (CSV) files with
  // the fields defined as follows:
  // 0 = groove format version
  // 1 = description of groove
  // 2 = beats per measure
  // 3 = number of measures
  // 4 = number of voices
  // 5 = interpolate flag (0 = no interpolation, 1 = with interpolation)
  // 6 = groove type e.g. percussion or bass
  // 7 = key (only used for bass grooves)
  // 8:6+BPM*measures*4 = 1st voice notes
  //     for each note...
  //        ogg number
  //        transpose
  //        name
  //        initial
  // ??:??+BPM*measures*4 = 2nd voice notes

  static const String grooveFormatVersion = "2";
  // Format version    Added in release    Reason
  // 1                 rel11               initial release
  // 2                 rel12               added interpolate flag

  // convert groove to  a csv string for writing to a file
  String toCSV(String description) {
    String result = '';
    int beats = this.bpm * this.numMeasures;
    String type;
    var _interp = 0;

    switch (this.type) {
      case GrooveType.percussion:
        {
          type = 'percussion';
        }
        break;
      case GrooveType.bass:
        {
          type = 'bass';
        }
        break;
      default:
        {
          type = 'percussion';
        }
        break;
    }

    if (this.interpolate) {
      _interp = 1;
    }

//    print('HF: oggMap: $oggMap');
//    print('HF: initialMap: $initialMap');

    result = grooveFormatVersion +
        ',' +
        description +
        ',' +
        this.bpm.toString() +
        ',' +
        this.numMeasures.toString() +
        ',' +
        this.voices.toString() +
        ',' +
        _interp.toString() +
        ',' +
        type +
        ',' +
        this.key +
        ',';

//    print('HF: toCSV1: $result');

    // for each note
    for (int i = 0; i < beats; i++) {
//       print('HF: toCSV: note $i');
//       var val = this.notes[i].oggIndex.toString();
//       print('HF:        oggIndex = $val');
//       val = this.notes[i].oggNote.toString();
//       print('HF:        oggNote = $val');
//       val = this.notes[i].name;
//       print('HF:        name = $val');
//       val = this.notes[i].initial;
//       print('HF:        initial = $val');
      String note = this.notes[i].oggIndex.toString() +
          ',' +
          this.notes[i].oggNote.toString() +
          ',' +
          this.notes[i].name +
          ',' +
          this.notes[i].initial +
          ',';
//       print('HF: toCSV2: $note');
      result = result + note;
    }

    // for each note in the 2nd voice
    for (int i = 0; i < beats; i++) {
      String note2 = this.notes2[i].oggIndex.toString() +
          ',' +
          this.notes2[i].oggNote.toString() +
          ',' +
          this.notes2[i].name +
          ',' +
          this.notes2[i].initial +
          ',';
//      print('HF: toCSV3: $note2');
      result = result + note2;
    }

    return result;
  }

  // convert a CSV string to a groove for reading from a file
  void fromCSV(String txt) {
    // split the string on ,
    List<String> fields = txt.split(',');
    int numFields = fields.length;
    String _format;
    String _description;
    String _type;
    int _voices;
    int _interp;
    String _key;

    if (kDebugMode) {
      print('HF groove.fromCSV : number of fields = $numFields');
    }

    _format = fields[0];
    if (_format == grooveFormatVersion) {
      // same version
      if (kDebugMode) {
        print('HF: loading same groove format version');
      }
    } else {
      // different version
      if (kDebugMode) {
        print('HF: loading different groove format version');
      }
    }
    _description = fields[1];
    this.description = _description;

    this.resize(
        int.parse(fields[2]), int.parse(fields[3]), int.parse(fields[4]));
    int beats = int.parse(fields[2]) * int.parse(fields[3]);
//    this.voices = int.parse(fields[4]);
    _voices = this.voices;
    _interp = int.parse(fields[5]);
    if (_interp == 1) {
      this.interpolate = true;
    } else {
      this.interpolate = false;
    }
    switch (fields[6]) {
      case 'percussion':
        {
          this.type = GrooveType.percussion;
          _type = 'percussion';
        }
        break;
      case 'bass':
        {
          this.type = GrooveType.bass;
          _type = 'bass';
        }
        break;
      default:
        {
          this.type = GrooveType.percussion;
          _type = 'error';
        }
        break;
    }
    this.key = fields[7];
    _key = this.key;
    if (kDebugMode) {
      print(
          'HF groove.fromCSV : description = $_description, number of beats = $beats, voices = $_voices, type = $_type, key = $_key');
    }

    // for each note
    for (int i = 0; i < beats; i++) {
      this.notes[i].oggIndex = int.parse(fields[i * 4 + 8]);
      this.notes[i].oggNote = int.parse(fields[i * 4 + 9]);
      this.notes[i].name = fields[i * 4 + 10];
      this.notes[i].initial = fields[i * 4 + 11];
      String note = this.notes[i].oggIndex.toString() +
          ',' +
          this.notes[i].oggNote.toString() +
          ',' +
          this.notes[i].name +
          ',' +
          this.notes[i].initial +
          ',';
      if (kDebugMode) {
        print('HF: groove.fromCSV notes: $note');
      }
    }

    // for each note in the 2nd voice
    var offset = 8 + (beats * 4);
    for (int i = 0; i < beats; i++) {
      this.notes2[i].oggIndex = int.parse(fields[i * 4 + offset]);
      this.notes2[i].oggNote = int.parse(fields[i * 4 + offset + 1]);
      this.notes2[i].name = fields[i * 4 + offset + 2];
      this.notes2[i].initial = fields[i * 4 + offset + 3];
      String note = this.notes2[i].oggIndex.toString() +
          ',' +
          this.notes2[i].oggNote.toString() +
          ',' +
          this.notes2[i].name +
          ',' +
          this.notes2[i].initial +
          ',';
      if (kDebugMode) {
        print('HF: groove.fromCSV notes2: $note');
      }
    }

    return;
  }

  void printGroove() {
    int beats = this.bpm * this.numMeasures;
    int _bpm = this.bpm;
    int _numMeasures = this.numMeasures;
    int _voices = this.voices;
    String? _key = this.key;
    String type;

    switch (this.type) {
      case GrooveType.percussion:
        {
          type = 'percussion';
        }
        break;
      case GrooveType.bass:
        {
          type = 'bass';
        }
        break;
      default:
        {
          type = 'percussion';
        }
        break;
    }

    if (kDebugMode) {
      print(
          'HF: print groove: BPM = $_bpm, num measures = $_numMeasures, voices = $_voices, key = $_key, type = $type');
    }

    if (this.description != '') {
      if (kDebugMode) {
        print('HF: print groove: $this.description');
      }
    }

    // for each note
    for (int i = 0; i < beats; i++) {
      String note = this.notes[i].oggIndex.toString() +
          ',' +
          this.notes[i].oggNote.toString() +
          ',' +
          this.notes[i].name +
          ',' +
          this.notes[i].initial +
          ',';
      if (kDebugMode) {
        print('HF: print groove voice 1 note [$i]: $note');
      }
    }
    // if there are two voices...
    if (this.voices == 2) {
      for (int i = 0; i < beats; i++) {
        String note = this.notes2[i].oggIndex.toString() +
            ',' +
            this.notes2[i].oggNote.toString() +
            ',' +
            this.notes2[i].name +
            ',' +
            this.notes2[i].initial +
            ',';
        if (kDebugMode) {
          print('HF: print groove voice 2 note [$i]: $note');
        }
      }
    }
  }
}
