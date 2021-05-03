import 'midi.dart';

Note note = new Note(60, "Bass drum");
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

  void addNote(int beat, int measure, Note note) {
    this.notes[(beat-1)+(measure-1)*this.bpm] = note;
  }

  // add a note to the groove using its initial only
  void addInitialNote(int index, String initial) {
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
      default: {
        this.notes[index].midi = 0;
        this.notes[index].name = '-';
      }
    }
  }

  // return the first letter of a notes name
  String initialNote(int index) {
    return this.notes[index].substring(0,1);
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