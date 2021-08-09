import 'oggPiano.dart';
import 'bass.dart';
import 'package:circular_buffer/circular_buffer.dart';
import 'package:get/get.dart';

Note note = new Note(0, "Bass drum");
List<Note> notes = [note];
Groove groove = new Groove(1,1,notes, GrooveType.percussion);

enum GrooveType { percussion, bass, guitarNotes, guitarChords, pianoNotes, pianoChords }

class Note {
  int? oggIndex;  // the index of the ogg file sample
  int? oggNote;   // the number of semitones to transpose from the .ogg file sample
  String? name;
  String? initial;

  Note(int index, String name) {
    this.oggIndex = index;
    this.oggNote = 0;
    this.name = name;
    this.initial = initialMap[name];
  }

  Note.empty() {
  }

  copyFrom(Note from) {
    this.oggIndex = from.oggIndex;
    this.oggNote = from.oggNote;
    this.name = from.name;
    this.initial = from.initial;
  }

}

class Groove {
  int bpm = 1;  // number of beat per measure
  int numMeasures = 1; // number of measures
  int index = 0; // pointer to next note to play
  int lastSequenceBit = -1;  // sequence bit of last notify received
                             // note that -1 is used to indicate that a first beat has not yet been received
  final timeBuffer = CircularBuffer<int>(8);  // circular buffer of beat delta timestamps
  double BeatsPerMinute = 0.0;
  double sum = 0;
  List notes = <Note>[]; // list of notes
  String? key = 'E';
  GrooveType type = GrooveType.percussion;
  String description = '';

  // constructor with list of notes
  Groove(int beats, int measures, List notes, GrooveType type) {
    this.bpm = beats;
    this.numMeasures = measures;
    this.index = 0;
    this.lastSequenceBit = -1;
    this.notes = notes;
    this.type = type;
  }

  // constructor without list of notes
  Groove.empty(int beats, int measures, GrooveType type) {
    this.bpm = beats;
    this.numMeasures = measures;
    this.index = 0;
    this.lastSequenceBit = -1;
    this.notes = List<Note>.generate(beats * measures,(i){
      return Note(-1, "-");
    });
    this.type = type;
  }

  initialize() {
    this.bpm = 1;
    this.numMeasures = 1;
    this.index = 0;
    this.lastSequenceBit = -1;
    this.notes.clear();
    this.notes[0].name = '-';
    this.notes[0].oggIndex = -1;
    this.notes[0].oggNote = 0;
    this.notes[0].initial = '-';
    this.type = GrooveType.percussion;
    this.key = 'E';
  }

  reset() {
    this.index = 0;
    this.lastSequenceBit = -1;
  }
  // retain the bpm and numMeasures but set all notes to -
  // used when changing between groove and bass mode
  void clearNotes() {
     for(int i = 0; i<this.bpm*this.numMeasures; i++) {
       this.notes[i].name = '-';
       this.notes[i].oggIndex = -1;
       this.notes[i].oggNote = 0;
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
        this.notes[index].oggIndex = -1;
        this.notes[index].oggNote = 0;
        this.notes[index].name = '-';
      }
      break;
      case 'B': {
        this.notes[index].oggIndex = 0;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Bass drum';
      }
      break;
      case 'K': {
        this.notes[index].oggIndex = 1;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Kick drum';
      }
      break;
      case 'S': {
        this.notes[index].oggIndex = 2;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Snare drum';
      }
      break;
      case 'H': {
        this.notes[index].oggIndex = 3;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'High Hat Cymbal';
      }
      break;
      case 'C': {
        this.notes[index].oggIndex = 4;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Cowbell';
      }
      break;
      case 'T': {
        this.notes[index].oggIndex = 5;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Tambourine';
      }
      break;
      case 'F': {
        this.notes[index].oggIndex = 7;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Fingersnap';
      }
      break;
      case 'R': {
        this.notes[index].oggIndex = 8;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Rim shot';
      }
      break;
      case 'A': {
        this.notes[index].oggIndex = 9;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Shaker';
      }
      break;
      case 'W': {
        this.notes[index].oggIndex = 10;
        this.notes[index].oggNote = 0;
        this.notes[index].name = 'Woodblock';
      }
      break;
      default: {
        this.notes[index].oggIndex = -1;
        this.notes[index].oggNote = 0;
        this.notes[index].name = '-';
      }
    }
  }

  // change the key of a bass groove
  changeKey(String? keyName) {
    String roman;
    int romanIndex;
    // loop over all of the notes in the groove
    for(int i=0; i<this.bpm*this.numMeasures; i++) {
      if (this.notes[i].name != '-') {  // ignore empty notes
        romanIndex = this.notes[i].name.indexOf('-') + 1;
        roman = this.notes[i].name.substring(romanIndex); //
        this.addBassNote(i, roman, keyName);
      }
    }
  }

  // add a bass note to the groove using the roman numeral and which key
  // we're in currently e.g. key of C, III would be E.
  addBassNote(index, roman, keyName) {
    // if no note is to be played, as indicated by -,
    // then set oggIndex to -1 and name and initial to -
    if (roman == '-') {
      this.notes[index].name = '-';
      this.notes[index].initial = '-';
      this.notes[index].oggIndex = -1;
      this.notes[index].oggNote = 0;
    }
    // create a name by concatenating the key name, a "-" and the
    // roman numeral,  e.g. C-IV
    else {
      this.notes[index].name = keyName + '-' + roman;
      this.notes[index].initial = roman;

      // get the index of the keyName
      int keyIndex = keys.indexWhere((element) =>
      element == keyName);

      // get the index of the roman numeral
      int romanIndex = scaleTonesRoman.indexWhere((element) =>
      element == roman);

      int offset = scaleTonesIndex[romanIndex];

      // create the oggNote by adding the following:
      //   the MIDI code for E1
      //   the key (starting from E)
      //   the roman numeral offset from the tonic
      // and subtracting the MIDI code for A1 (the note of the sample file)
      this.notes[index].oggIndex = 6;
      this.notes[index].oggNote = E1midi + keyIndex + offset - A1midi;
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
    switch(this.type) {
      case GrooveType.percussion: {
        type = 'percussion'; }
      break;
      case GrooveType.bass: {
        type = 'bass'; }
      break;
      default: {
        type = 'percussion'; }
      break;
    }
    return(type);
  }

  // check the type of this groove and change it if necessary.  If changing the
  // groove type, clear all of the notes
  void checkType(String type) {
    print('HF: checkType: type = $type');
    if ((type == 'percussion') && (this.type != GrooveType.percussion)) {
      this.type = GrooveType.percussion;
      print('HF: checkType: changing type to percussion');
      this.clearNotes();
    }
    if ((type == 'bass') && (this.type != GrooveType.bass)) {
      this.type = GrooveType.bass;
      print('HF: checkType: changing type to bass');
      this.clearNotes();
    }
  }

  // return a list of initials of the current groove notes
  List<String> getInitials() {
    var returnValue = new List<String>.filled(96,'-');
    for(int i=0; i< this.bpm*this.numMeasures; i++) {
      if (this.type == GrooveType.percussion) {
        returnValue[i] = this.notes[i].initial;
      } else if (this.type == GrooveType.bass) {
        if (this.notes[i].name == '-') {
          returnValue[i] = '-';
        } else {
          int hyphenIndex = this.notes[i].name.indexOf('-') + 1;
          returnValue[i] = this.notes[i].name.substring(hyphenIndex);
        }
      }
    }
    return returnValue;
  }

  // resize the groove
  // TODO: if increasing the number of beats per measure, duplicate the last beat(s)
  // TODO: if increasing the number of measures, duplicate the last measure
  void resize(int beat, int measure) {
    var origBpm = this.bpm;
    var origMeasures = this.numMeasures;
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
        this.notes.add(Note(-1, "-"));
      }
      // if adding measures...
      if (measure > origMeasures) {
        var measuresToAdd = measure - origMeasures;
        var copyFromStart = (origMeasures - 1) * origBpm;
        for(int i=0; i<measuresToAdd; i++) {
          var copyToStart = (origMeasures + i) * beat;
          for(int n=0; n<beat; n++) {
            var src = copyFromStart + n;
            var dest = copyToStart + n;
            this.notes[dest].copyFrom(this.notes[src]);
            print('HF: resize: copying from $src to $dest');
          }
        }
      }
    }
  }

  // play the next note in the groove
  void play(int data) {
    int sequenceBit;
    double mean;
    var time = DateTime.now();   // get system time
    print('HF:   Time: $time, Name: ${this.notes[this.index].name}, groove index: ${this.index}, ogg index: ${this.notes[this.index].oggIndex.toString()}, ogg transpose: ${this.notes[this.index].oggNote.toString()}');

    // check for a sequence error
    sequenceBit = (data >> 6) & 0x01;
    if (lastSequenceBit != -1) {  // ignore the sequence bit on the first notify received is indicated by -1
      if (sequenceBit == lastSequenceBit) {
        Get.snackbar('Sequence error:',
            'A beat was missed, possibly due to a lost Bluetooth notify message',
            snackPosition: SnackPosition.BOTTOM);
        print('HF: sequence error');

        // increment pointer to skip one note
        this.index = (this.index + 1) % (this.bpm * this.numMeasures);
      }
    }
    lastSequenceBit = sequenceBit;

    // play the note if non-zero
    if (this.notes[this.index].oggIndex != -1) {
      // play the note
      oggpiano.play(this.notes[this.index].oggIndex, this.notes[index].oggNote);
    }

    // calculate Beats Per Minute
    final first = timeBuffer.isFilled ? timeBuffer.first : 0;
    timeBuffer.add(data & 0x3F); // add the latest beat delta to the circular buffer
    sum += timeBuffer.last - first;  // update the running sum
    mean = sum.toDouble() / timeBuffer.length; // calculate the mean delta time
    BeatsPerMinute = 1/(mean * 0.040) * 60; // calculate beats per minute.
//    print("HF: beats per minute = ${data & 0x3F} ${mean.toStringAsFixed(1)} ${BeatsPerMinute.toStringAsFixed(1)}");

    // increment pointer to the next note
    this.index = (this.index + 1) % (this.bpm * this.numMeasures);
  }

  // restart by setting index to 0
  void restart() {
    this.index = 0;
  }

  // convert groove to  a csv string for writing to a file
  String toCSV(String description) {
    String result = '';
    int beats = this.bpm * this.numMeasures;
    String type;

    switch(this.type) {
      case GrooveType.percussion: {
        type = 'percussion'; }
        break;
      case GrooveType.bass: {
        type = 'bass'; }
        break;
      default: {
        type = 'percussion'; }
        break;
      }

      if (description == null) {
        description = '';
      }
    result = description + ',' + this.bpm.toString() + ',' + this.numMeasures.toString() + ',' + type + ',';

    print('HF: toCSV: $result');

    // for each note
    for(int i=0; i<beats; i++) {
       String note = this.notes[i].oggIndex.toString() + ',' +
                     this.notes[i].oggNote.toString() + ',' +
                     this.notes[i].name + ',' + this.notes[i].initial + ',';
       print('HF: toCSV: $note');
       result = result + note;
    }

    return result;
  }

  // convert a CSV string to a groove for reading from a file
  void fromCSV(String txt) {
    // split the string on ,
    List<String> fields = txt.split(',');
    int numFields = fields.length;
    String type;
    String description;

    print('HF groove.fromCSV : number of fields = $numFields');

    description = fields[0];
    this.description = description;

    groove.resize(int.parse(fields[1]), int.parse(fields[2]));
    int beats = int.parse(fields[1]) * int.parse(fields[2]);
    type = fields[3];
    print('HF groove.fromCSV : type = $type, number of beats = $beats');

    // for each note
    for(int i=0; i<beats; i++) {
      this.notes[i].oggIndex = int.parse(fields[i*4+4]);
      this.notes[i].oggNote = int.parse(fields[i*4+5]);
      this.notes[i].name = fields[i*4+6];
      this.notes[i].initial = fields[i*4+7];
      String note = this.notes[i].oggIndex.toString() + ',' +
                    this.notes[i].oggNote.toString() + ',' +
                    this.notes[i].name + ',' + this.notes[i].initial + ',';
      print('HF: groove.fromCSV: $note');
    }

    return;
  }

  void printGroove() {
    int beats = this.bpm * this.numMeasures;
    int _bpm = this.bpm;
    int _numMeasures = this.numMeasures;
    String? _key = this.key;
    String type;

    switch(this.type) {
      case GrooveType.percussion: {
        type = 'percussion'; }
      break;
      case GrooveType.bass: {
        type = 'bass'; }
      break;
      default: {
        type = 'percussion'; }
      break;
    }

    print('HF: print groove: $_bpm, $_numMeasures, $_key, $type');

    if (this.description != '') {
      print('HF: print groove: $this.description');
    }

    // for each note
    for(int i=0; i<beats; i++) {
      String note = this.notes[i].oggIndex.toString() + ',' +
                    this.notes[i].oggNote.toString() + ',' +
                    this.notes[i].name + ',' + this.notes[i].initial + ',';
      print('HF: print groove note [$i]: $note');
    }
  }

}