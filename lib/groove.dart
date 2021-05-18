import 'midi.dart';
import 'bass.dart';

Note note = new Note(0, "-");
List<Note> notes = [note];
Groove groove = new Groove(1,1,notes);

class Note {
  int? midi;
  String? name;
  String? initial;

  Note(int midi, String name) {
    this.midi = midi;
    this.name = name;
    this.initial = name.substring(0,1);
  }

  Note.empty() {
  }
}

class Groove {
  int bpm = 1;  // number of beat per measure
  int numMeasures = 1; // number of measures
  int index = 0; // pointer to next note to play
  List notes = <Note>[]; // list of notes

  // constructor with list of notes
  Groove(int beats, int measures, List notes) {
    this.bpm = beats;
    this.numMeasures = measures;
    this.index = 0;
    this.notes = notes;
  }

  // constructor without list of notes
  Groove.empty(int beats, int measures) {
    this.bpm = beats;
    this.numMeasures = measures;
    this.index = 0;
    this.notes = List<Note>.generate(beats * measures,(i){
      return Note(0, "");
    });
  }

  initialize() {
    this.bpm = 1;
    this.numMeasures = 1;
    this.index = 0;
    this.notes.clear();
    this.notes[0].name = '-';
    this.notes[0].midi = 0;
    this.notes[0].initial = '-';
  }

  // retain the bpm and numMeasures but set all notes to -
  // used when changing between groove and bass mode
  void clearNotes() {
     for(int i = 0; i<this.bpm*this.numMeasures; i++) {
       this.notes[i].name = '-';
       this.notes[i].midi = 0;
       this.notes[i].initial = '-';
     }
  }

  void addNote(int beat, int measure, Note note) {
    this.notes[(beat-1)+(measure-1)*this.bpm] = note;
  }

  // add a note to the groove using its initial only
  void addInitialNote(int index, String initial) {
    this.notes[index].initial = initial;
    switch (initial) {
      case '-': {
        this.notes[index].midi = 0;
        this.notes[index].name = '-';
      }
      break;
      case 'B': {
        this.notes[index].midi = 60;
        this.notes[index].name = 'Bass drum';
      }
      break;
      case 'K': {
        this.notes[index].midi = 59;
        this.notes[index].name = 'Kick drum';
      }
      break;
      case 'S': {
        this.notes[index].midi = 40;
        this.notes[index].name = 'Snare drum';
      }
      break;
      case 'H': {
        this.notes[index].midi = 70;
        this.notes[index].name = 'High Hat Cymbal';
      }
      break;
      case 'C': {
        this.notes[index].midi = 80;
        this.notes[index].name = 'Cowbell';
      }
      break;
      case 'T': {
        this.notes[index].midi = 78;
        this.notes[index].name = 'Tambourine';
      }
      break;
      default: {
        this.notes[index].midi = 0;
        this.notes[index].name = '-';
      }
    }
  }

  // add a bass note to the groove using the roman numeral and which key
  // we're in currently e.g. key of C, III would be E.
  addBassNote(index, roman, keyName) {
    // if no note is to be played, as indicated by -,
    // then set midi to 0 and name and initial to -
    if (roman == '-') {
      this.notes[index].name = '-';
      this.notes[index].initial = '-';
      this.notes[index].midi = 0;
    }
    // create a name by concatenating the key name, a - and the
    // roman numeral,  e.g. C-IV
    else {
      this.notes[index].name = keyName + '-' + roman;
      this.notes[index].initial = keyName + '-' + roman;

      // get the index of the keyName
      int keyIndex = keys.indexWhere((element) =>
      element == keyName);

      // get the index of the roman numeral
      int romanIndex = scaleTonesRoman.indexWhere((element) =>
      element == roman);

      int offset = scaleTonesIndex[romanIndex];

      // create the MIDI code by adding the following:
      //   the MIDI code for E1
      //   the key (starting from E)
      //   the roman numeral offset from the tonic
      this.notes[index].midi = E1midi + keyIndex + offset;
    }
  }

  // return the first letter of a notes name
  String initialNote(int index) {
    return this.notes[index].substring(0,1);
  }

  // return a list of initials of the current groove notes
  List<String> getInitials() {
    var returnValue = new List<String>.filled(64,'-');
    for(int i=0; i< this.bpm*this.numMeasures; i++) {
      returnValue[i] = this.notes[i].initial;
    }
    return returnValue;
  }

  // resize the groove
  // TODO: if increasing the number of beats per measure, duplicate the last beat(s)
  // TODO: if increasing the number of measures, duplicate the last measure
  void resize(int beat, int measure) {
    this.bpm = beat;
    this.numMeasures = measure;
    this.index = 0;
    final beats = beat * measure;
    // if the list of notes is too long
    if (this.notes.length > beats) {
      // remove the extra items
      this.notes.removeRange(beat, this.notes.length - 1);
    }
    // if the list is too short
    if (this.notes.length < beats) {
      var numToAdd = beats - this.notes.length;
      print("HF: resize groove adding $numToAdd notes");
      for (var i = 0; i < numToAdd; i++) {
        // add items to the list
        this.notes.add(Note(0, "-"));
      }
    }
  }

  // play the next note in the groove
  void play() {
    print('HF:   Note: ${this.notes[this.index].midi}, index: ${this.index}');

    // play the note if non-zero
    if (this.notes[this.index].midi != 0) {
      // play the note
      midi.play(this.notes[this.index].midi);
    }

    // increment pointer to the next note
    this.index = (this.index + 1) % (this.bpm * this.numMeasures);
  }

  // restart by setting index to 0
  void restart() {
    this.index = 0;
  }

}