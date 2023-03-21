import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:get/get.dart';
//import 'package:happy_feet_app/main.dart';

//import 'audio.dart';
import 'audioBASS.dart';
import 'bass.dart';
import 'blues.dart';
import 'sharedPrefs.dart';

Note note = new Note(0, "Bass drum");
Groove groove = new Groove.empty(1, 1, GrooveType.percussion);

enum GrooveType { percussion, bass, blues, guitarChords, pianoChords }

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

// types of blues grooves
enum BluesType { TwelveBar, TwelveBarQuickChange, TwelveBarSlowChange }

class Note {
  int? oggIndex; // the index of the ogg file sample
  String? name;
  String? initial;

  Note(int index, String name) {
    this.oggIndex = index;
    this.name = name;
    this.initial = initialMap[name];
  }

  Note.empty();

  copyFrom(Note from) {
    this.oggIndex = from.oggIndex;
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
  bool blues = false; // a flag to indicate blues mode, similar to 1-tap
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
  double sysLatestBPM = 0.0;
  double sysFilteredBPM = 0.0;
  double sum = 0;
  double sum2 = 0;
  double variation = 0.0;
  double beatPeriod = 1000.0; // default to 60 BPM i.e. 1000ms per beat
  double beatSubdivisionInMs = 0.0;
  List notes = <Note>[]; // list of notes
  List notes2 = <Note>[]; // list of notes
  GrooveType type = GrooveType.percussion;
  String description = '';
  var bpmString = '---'.obs;
  var bpmColor = Colors.white;
  var indexString = 'beat 1'.obs;
  var leadInString = '0'.obs;
  String keyName = 'E';
  // info for blues mode screen
  var barString = '-'.obs;
  var nashvilleString = '-'.obs;
  var chordString = '-'.obs;
  RxBool leadInDone = false.obs;
  // variables for practice mode: instantaneous BPM, current streaks
  // within +/- 5 and 10 BPM of target
  var practiceBPM = 0.0.obs;
  var practiceStreak5 = 0.obs;
  var practiceStreak10 = 0.obs;
  var targetTempo = 120.obs;
  //var practiceColor = Colors.white;
  bool firstBeat = true;
  int runCount = 0;
  bool practice = false;
  bool oneTapStarted =
      false; // flag to indicate if the oneTap timer has been started or not
  Timer? measureTimer; // a timer used by oneTap auto mode

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
      this.notes[i].initial = '-';

      this.notes2.add(null);
      this.notes2[i].name = 'none';
      this.notes2[i].oggIndex = -1;
      this.notes2[i].initial = '-';
    }
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
    this.notes[0].name = trName;
    this.notes[0].initial = initialMap[trName];
    this.oneTap = false;
    this.blues = false;
    this.reset();
  }

  // initialize the groove in alternating note mode
  initAlternating(String name1, String name2) {
    String trName1 = untranslateNoteName(name1);
    String trName2 = untranslateNoteName(name2);
    this.resize(2, 1, 1);
    this.interpolate = false;
    this.notes[0].oggIndex = oggMap[trName1];
    this.notes[0].name = trName1;
    this.notes[0].initial = initialMap[trName1];

    this.notes[1].oggIndex = oggMap[trName2];
    this.notes[1].name = trName2;
    this.notes[1].initial = initialMap[trName2];

    this.oneTap = false;
    this.blues = false;
    this.reset();
  }

  // initialize the groove in dual note mode
  initDual(String name1, String name2) {
    String trName1 = untranslateNoteName(name1);
    String trName2 = untranslateNoteName(name2);
    this.resize(1, 1, 2);
    this.interpolate = false;
    this.notes[0].oggIndex = oggMap[trName1];
    this.notes[0].name = trName1;
    this.notes[0].initial = initialMap[trName1];

    this.notes2[0].oggIndex = oggMap[trName2];
    this.notes2[0].name = trName2;
    this.notes2[0].initial = initialMap[trName2];

    this.oneTap = false;
    this.blues = false;
    this.reset();
  }

  reset() {
    this.index = 0;
    this.lastSequenceBit = -1;
    this.leadInCount = 4;
    this.leadInString.value = '4';
    this.leadInDone.value = false;
    this.firstBeat = true;
  }

  // increment the index to the next note to be played
  incrementIndex() {
    this.index = (this.index + 1) % (this.bpm * this.numMeasures);
  }

  // return the index of the last played note.  This is used in bass
  // mode to stop the last note played in case it is still playing.
  int lastIndex() {
    int _result;
    _result = this.index - 1;
    if (_result == -1) {
      _result = (this.bpm * this.numMeasures) - 1;
    }
    return _result;
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
      this.notes[i].initial = '-';

      this.notes2[i].name = '-';
      this.notes2[i].oggIndex = -1;
      this.notes2[i].initial = '-';
    }
    this.voices = 1;
  }

  // add a note to the groove using its initial only
  void addInitialNote(int index, String initial) {
    int _oggIndex = -1;
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
          _name = '-';
        }
        break;
      case 'b':
        {
          _oggIndex = 0;
          _name = 'Bass drum';
        }
        break;
      case 'B':
        {
          _oggIndex = 1;
          _name = 'Bass echo';
        }
        break;
      case 'S':
        {
          _oggIndex = 2;
          _name = 'Snare drum';
        }
        break;
      case 'H':
        {
          _oggIndex = 3;
          _name = 'High Hat Cymbal';
        }
        break;
      case 'C':
        {
          _oggIndex = 4;
          _name = 'Cowbell';
        }
        break;
      case 'M':
        {
          _oggIndex = 5;
          _name = 'Tambourine';
        }
        break;
      case 'F':
        {
          _oggIndex = 7;
          _name = 'Fingersnap';
        }
        break;
      case 'R':
        {
          _oggIndex = 8;
          _name = 'Rim shot';
        }
        break;
      case 'A':
        {
          _oggIndex = 9;
          _name = 'Shaker';
        }
        break;
      case 'W':
        {
          _oggIndex = 10;
          _name = 'Woodblock';
        }
        break;
      case 't':
        {
          _oggIndex = 11;
          _name = 'Lo tom';
        }
        break;
      case 'T':
        {
          _oggIndex = 12;
          _name = 'Hi tom';
        }
        break;
      case 'U':
        {
          _oggIndex = 13;
          _name = 'Brushes';
        }
        break;
      case 'Q':
        {
          _oggIndex = 14;
          _name = 'Quijada';
        }
        break;
      default:
        {
          _oggIndex = -1;
          _name = '-';
        }
    }

    if (this.voices == 1) {
      this.notes[index].oggIndex = _oggIndex;
      this.notes[index].name = _name;
      this.notes[index].initial = initial;
      if (kDebugMode) {
        print(
            'HF: addInitialNote single voice: index = $index, oggIndex = $_oggIndex, name = $_name');
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
              'HF: addInitialNote dual voice: notes _i = $_i, index = $index, oggIndex = $_oggIndex, name = $_name');
        }
        this.notes[_i].oggIndex = _oggIndex;
        this.notes[_i].name = _name;
        this.notes[_i].initial = initial;
      } else {
        if (kDebugMode) {
          print(
              'HF: addInitialNote dual voice: notes2 _i = $_i, index = $index, oggIndex = $_oggIndex, name = $_name');
        }
        this.notes2[_i].oggIndex = _oggIndex;
        this.notes2[_i].name = _name;
        this.notes2[_i].initial = initial;
      }
    }
  }

  // add a note to the groove using its initial only.  This
  // method is used by blues mode.
  void addInitialNoteSequential(int index, String initial) {
    int _oggIndex = -1;
    String _name = '-';
    int _voices = this.voices;

    if (kDebugMode) {
      print(
          'HF: addInitialNoteSequential: index = $index, initial = $initial, _voices = $_voices');
    }

    switch (initial) {
      case '-':
        {
          _oggIndex = -1;
          _name = '-';
        }
        break;
      case 'b':
        {
          _oggIndex = 0;
          _name = 'Bass drum';
        }
        break;
      case 'B':
        {
          _oggIndex = 1;
          _name = 'Bass echo';
        }
        break;
      case 'S':
        {
          _oggIndex = 2;
          _name = 'Snare drum';
        }
        break;
      case 'H':
        {
          _oggIndex = 3;
          _name = 'High Hat Cymbal';
        }
        break;
      case 'C':
        {
          _oggIndex = 4;
          _name = 'Cowbell';
        }
        break;
      case 'M':
        {
          _oggIndex = 5;
          _name = 'Tambourine';
        }
        break;
      case 'F':
        {
          _oggIndex = 7;
          _name = 'Fingersnap';
        }
        break;
      case 'R':
        {
          _oggIndex = 8;
          _name = 'Rim shot';
        }
        break;
      case 'A':
        {
          _oggIndex = 9;
          _name = 'Shaker';
        }
        break;
      case 'W':
        {
          _oggIndex = 10;
          _name = 'Woodblock';
        }
        break;
      case 't':
        {
          _oggIndex = 11;
          _name = 'Lo tom';
        }
        break;
      case 'T':
        {
          _oggIndex = 12;
          _name = 'Hi tom';
        }
        break;
      case 'U':
        {
          _oggIndex = 13;
          _name = 'Brushes';
        }
        break;
      case 'Q':
        {
          _oggIndex = 14;
          _name = 'Quijada';
        }
        break;
      default:
        {
          _oggIndex = -1;
          _name = '-';
        }
    }

    this.notes[index].oggIndex = _oggIndex;
    this.notes[index].name = _name;
    this.notes[index].initial = initial;
    if (kDebugMode) {
      print(
          'HF: addInitialNoteSequential: index = $index, oggIndex = $_oggIndex, name = $_name');
    }
  }

  // add a bass note to the groove using the note's name.
  addBassNote(int index, String name) {
    // if no note is to be played, as indicated by -,
    // then set oggIndex to -1 and name and initial to -
    if (name == '-') {
      this.notes[index].name = '-';
      this.notes[index].initial = '-';
      this.notes[index].oggIndex = -1;
    } else {
      // set both the note's name and initial to the name parameter.
      // Note that for bass notes, the initial (or more accurately the
      // short name) is 2 to 3 characters in length e.g. E1 or D#3
      this.notes[index].name = name;
      this.notes[index].initial = name;

      int noteIndex = allBassNotes.indexWhere((element) => element == name);
      if (kDebugMode) {
        print('HF: addBassNote2: name = $name, note index = $noteIndex');
      }

      int _temp = noteIndex + E1mp3;
      assert(_temp >= E1mp3);
      assert(_temp <= (E1mp3 + 23));
      this.notes[index].oggIndex = _temp;
      if (kDebugMode) {
        print('HF: addBassNote2: number = $_temp');
      }
    }
  }

  // add a bass note to the groove on voice 2 using a number for the note.
  // The number is 0 for E1, 1 for F1, ... up to 23 for D#3
  // This method is used by blues mode.
  addBassNote2(int index, int noteIndex) {
    // if no note is to be played, as indicated by a num equal to -1,
    // then set oggIndex to -1 and name and initial to -
    if (noteIndex == -1) {
      this.notes2[index].name = '-';
      this.notes2[index].initial = '-';
      this.notes2[index].oggIndex = -1;
    } else {
      // calculate the notes name from the noteIndex
      String _noteName = allBassNotes[noteIndex];
      this.notes2[index].name = _noteName;
      this.notes2[index].initial = _noteName;

      int _temp = noteIndex + E1mp3;
      assert(_temp >= E1mp3);
      assert(_temp <= (E1mp3 + 23));
      this.notes2[index].oggIndex = _temp;
      if (kDebugMode) {
        print(
            'HF: addBassNote2: index = $index, note name = $_noteName, number = $_temp');
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
      case GrooveType.blues:
        {
          type = 'blues';
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

    if (type == 'blues') {
      this.type = GrooveType.blues;
      if (kDebugMode) {
        print('HF: checkType: changing type to blues');
      }
      this.clearNotes();
      this.interpolate = false; // turn off backbeat mode when change to blues
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
        ((sysLatestBPM > 20.0) && (sysLatestBPM < 320.0))) {
      bpmString.value = sysLatestBPM.toStringAsFixed(1);
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

  // update the blues mode info
  void updateBluesInfo() {
    int _barNum = ((this.index ~/ 4) + 1);
    barString.value = _barNum.toString();
    String myString = nashville.numbers[_barNum - 1];
    nashvilleString.value = myString;
    int _keyNum = keys.indexWhere((element) => element == keyName);
    switch (nashvilleString.value) {
      case 'I':
        groove.chordString.value = keys[(_keyNum + 0) % 12];
        break;
      case 'IV':
        groove.chordString.value = keys[(_keyNum + 5) % 12];
        break;
      case 'V':
        groove.chordString.value = keys[(_keyNum + 7) % 12];
        break;
      default:
        break;
    }
  }

// update the practice mode streak counts: the number of successive
// beats within +/-X BPM of the target tempo where X is 1, 3 and 5.
  void updateStreakCounts() {
    var err = 0;

    err = this.targetTempo.value - this.practiceBPM.value.toInt();

    // set the background color based on the sign of the error:
    // red if going too fast, green if going too slow, blue otherwise
    /*
    if (err < -10) {
      practiceColor = Colors.red;
    } else if (err < -5) {
      practiceColor = Colors.orange;
    } else if (err > 10) {
      practiceColor = Colors.green;
    } else if (err > 5) {
      practiceColor = Colors.lightGreen;
    } else {
      practiceColor = Colors.blue;
    }
    */

    // absolute value of error, used by the streak couters below
    if (err < 0) {
      err = err * -1;
    }

    if (err <= 5) {
      this.practiceStreak5++;
    } else {
      this.practiceStreak5.value = 0;
    }

    if (err <= 10) {
      this.practiceStreak10++;
    } else {
      this.practiceStreak10.value = 0;
    }
  }

  // play the next note in the groove
  play(int data) {
    int sequenceBit;
    double mean2;
    var now = DateTime.now(); // get system time

    // check for a sequence error
    sequenceBit = (data >> 6) & 0x01;
    if (lastSequenceBit != -1 && !sharedPrefs.audioTestMode) {
      // ignore the sequence bit on the first notify received is indicated by -1 or if we're in audio test mode
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
    beatPeriod = beatInterval.inMilliseconds.toDouble(); // convert period to ms

    // update info used by practice mode
    practiceBPM.value = 1000.0 / beatPeriod * 60;
    updateStreakCounts();

    // play the next note in the groove in these cases:
    // i) not in interpolate or 1-tap mode, or
    // ii) in interpolate mode, and
    //     past the lead-in as indicated by leadInCount == 0
    //     index is even i.e. not an off beat
    if ((!groove.interpolate && !groove.oneTap && !groove.blues) ||
        (groove.interpolate && (groove.leadInCount == 0)) &&
            (groove.index.isEven)) {
      // if this is a bass groove, then stop playing the previous note
      if (this.type == GrooveType.bass) {
        int _last = this.lastIndex();
        hfaudio.stop(_last);
      }
      hfaudio.play(
        this.notes[this.index].oggIndex,
        this.notes2[this.index].oggIndex,
      );
      // increment pointer to the next note
      this.incrementIndex();
    } else if (groove.interpolate && (groove.leadInCount > 0)) {
      this.leadInCount--;
      if (this.leadInCount == 0) {
        this.leadInDone.value = true;
      }
      this.leadInString.value = this.leadInCount.toString();
      if (kDebugMode) {
        print(
            'HF:  lead-in count decremented to $this.leadInCount, leadInDone set to $this.leadInDone.value');
      }
    }

    // calculate Beats Per Minute using system time
    final first2 = sysTimeBuffer.isFilled ? sysTimeBuffer.first : 0;
    sysTimeBuffer.add(
        beatPeriod); // add the latest sys time interval to the circular buffer
    sum2 += sysTimeBuffer.last - first2; // update the running sum
    mean2 = sum2 / sysTimeBuffer.length; // calculate the mean delta time
    sysLatestBPM = (60000.0 / beatPeriod);
    sysFilteredBPM = (60000.0 / mean2);
    if ((this.oneTap || this.blues) && !this.firstBeat) {
      sysFilteredBPM = sysFilteredBPM * this.bpm;
      sysLatestBPM = sysLatestBPM * this.bpm;
    }
    variation = (sysLatestBPM - sysFilteredBPM) / sysFilteredBPM * 100.0;

    // create status string
    String _status = '';
    if (kDebugMode) {
      if (beatPeriod > (mean2 * 1.5)) {
        _status = 'missing';
        runCount = 0;
      } else if (beatPeriod > (mean2 * 1.1)) {
        _status = 'late';
        runCount = 0;
      } else if (beatPeriod < (mean2 * 0.9)) {
        _status = 'early';
        runCount = 0;
      } else if (beatPeriod < (mean2 * 0.75)) {
        _status = 'spurious';
        runCount = 0;
      } else {
        runCount++;
      }
    }

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
      // schedule the next note using a timer.  1/2 of the beat interval will be used to
      // schedule the note at the expected mid-point of the beat.
      var halfPeriodInMs = beatPeriod.toInt() ~/ 2;
      Timer(Duration(milliseconds: halfPeriodInMs), () {
        if (variation.abs() <= 20.0) {
          // only play the note if the beat is stable i.e. variation < 20%
          hfaudio.play(
            //this.voices,
            this.notes[this.index].oggIndex,
            this.notes2[this.index].oggIndex,
          );
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

    // 1-tap or blues mode: in 1-tap mode, there is a 4 beat lead-in and then the user
    // only taps their foot on the 1s
    if (this.oneTap || this.blues) {
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
        leadInDone.value = true;
        // lead-in is done, we're live!
        if (!sharedPrefs.autoMode) {
          // if not in auto mode, call the beat1 function
          oneTapBeat1();
        } else {
          // if no periodic timer is running, start one
          if (!this.oneTapStarted) {
            if (kDebugMode) {
              print('HF: first measure of 1-tap auto mode');
            }
            oneTapBeat1(); // start the first measure
            startMeasureTimer();
          } else {
            // else the timer is running.  In this case, when a beat is detected,
            // the timers should be cancelled
            cancelMeasureTimer();
            if (kDebugMode) {
              print('HF: ending 1-tap auto mode');
            }
          }
        }
      }
    }

    if (!oneTap) {
      updateBABInfo();
    }
    if (blues) {
      updateBluesInfo();
    }
  }

  void startMeasureTimer() {
    // cancel any existing timer before creating a new one
    measureTimer?.cancel();
    measureTimer = null;

    // use timer.periodic to schedule repetitive calls to oneTapbeat1
    measureTimer = Timer.periodic(
      Duration(milliseconds: (beatSubdivisionInMs * this.bpm).toInt()),
      (timer) {
        oneTapBeat1();
      },
    );
    this.oneTapStarted = true;
  }

  void cancelMeasureTimer() {
    measureTimer?.cancel();
    this.oneTapStarted = false;
  }

  // 1-tap beat 1: in 1-tap mode, this function is called to invoke
  // these actions on beat 1:
  //    - play the first note in the groove
  //    - schedules the other notes in the groove using timers
  void oneTapBeat1() {
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
    if (this.type == GrooveType.blues) {
      int _last = this.lastIndex();
      hfaudio.stop(_last);
    }
    hfaudio.play(
      this.notes[this.index].oggIndex,
      this.notes2[this.index].oggIndex,
    );
    updateBABInfo();
    if (blues) {
      updateBluesInfo();
    }

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
      if (!sharedPrefs.autoMode) {
        beatSubdivisionInMs = beatPeriod / this.bpm;
      }
    }
    if (kDebugMode) {
      print('HF: 1-tap: beat subdivision = $beatSubdivisionInMs ms');
    }

    // schedule the remaining notes to be played using timers
    for (int i = 1; i < this.bpm; i++) {
      Timer(Duration(milliseconds: (beatSubdivisionInMs * i).toInt()), () {
        if (this.type == GrooveType.blues) {
          int _last = this.lastIndex();
          hfaudio.stop(_last);
        } 
        hfaudio.play(
          this.notes[this.index].oggIndex,
          this.notes2[this.index].oggIndex,
        );
        updateBABInfo();
        if (blues) {
          updateBluesInfo();
        }
        if (kDebugMode) {
          _now = DateTime.now().toString();
          print('HF: $_now 1-tap: playing beat ${i + 1}, index=${this.index}');
        }
        // increment pointer to the next note
        this.incrementIndex();
      });
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
  // 7:6+BPM*measures*4 = 1st voice notes
  //     for each note...
  //        number
  //        name
  //        initial
  // ??:??+BPM*measures*3 = 2nd voice notes

  static const String grooveFormatVersion = "4";
  // Format version    Added in release    Reason
  // 1                 rel11               initial release
  // 2                 rel12               added interpolate flag
  // 3                 2022-11-10          removed transpose
  // 4                 2022-11-17          removed keys from bass grooves

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
        ',';

//    print('HF: toCSV1: $result');

    // for each note
    for (int i = 0; i < beats; i++) {
      String note = this.notes[i].oggIndex.toString() +
          ',' +
          this.notes[i].name +
          ',' +
          this.notes[i].initial +
          ',';
      result = result + note;
    }

    // for each note in the 2nd voice
    for (int i = 0; i < beats; i++) {
      String note2 = this.notes2[i].oggIndex.toString() +
          ',' +
          this.notes2[i].name +
          ',' +
          this.notes2[i].initial +
          ',';
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
    this.voices = int.parse(fields[4]);
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
    if (kDebugMode) {
      print(
          'HF groove.fromCSV : description = $_description, number of beats = $beats, voices = $_voices, type = $_type');
    }

    // for each note
    for (int i = 0; i < beats; i++) {
      this.notes[i].oggIndex = int.parse(fields[i * 4 + 7]);
//      this.notes[i].oggNote = int.parse(fields[i * 4 + 8]);
      this.notes[i].name = fields[i * 4 + 9];
      this.notes[i].initial = fields[i * 4 + 10];
      String note = this.notes[i].oggIndex.toString() +
          ',' +
//          this.notes[i].oggNote.toString() +
//          ',' +
          this.notes[i].name +
          ',' +
          this.notes[i].initial +
          ',';
      if (kDebugMode) {
        print('HF: groove.fromCSV notes: $note');
      }
    }

    // for each note in the 2nd voice
    var offset = 7 + (beats * 3);
    for (int i = 0; i < beats; i++) {
      this.notes2[i].oggIndex = int.parse(fields[i * 4 + offset]);
//      this.notes2[i].oggNote = int.parse(fields[i * 4 + offset + 1]);
      this.notes2[i].name = fields[i * 4 + offset + 1];
      this.notes2[i].initial = fields[i * 4 + offset + 2];
      String note = this.notes2[i].oggIndex.toString() +
          ',' +
//          this.notes2[i].oggNote.toString() +
//          ',' +
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
          'HF: print groove: BPM = $_bpm, num measures = $_numMeasures, voices = $_voices, type = $type');
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
