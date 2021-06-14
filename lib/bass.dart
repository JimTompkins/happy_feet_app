// list of key names for dropdown button.  Note that we start with E since it's the lowest
// note on an electric bass.
List keys = <String>['E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', ];

List scaleTonesIndex = <int>[0, 0,	2,	4,	5,	7,	9,	11];

List scaleTonesRoman = <String>['-', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

List chordsInKey = <String>['M', 'm', 'm', 'M', 'M', 'm', 'dim'];

List chordTypes = <String>['M', 'm', 'dim', 'Aug', 'Pwr', 'sus4', 'sus2'];
List MajorNotes = <int>[0,4,7];  // where 0 is the tonic
List MinorNotes = <int>[0,3,7];
List DiminishedNotes = <int>[0,3,6];
List AugmentedNotes = <int>[0,4,8];
List PowerNotes = <int>[0,7];
List Sus4Notes = <int>[0,5,7];
List Sus2Notes = <int>[0,2,7];
List chordNotes = <List>[MajorNotes, MinorNotes, DiminishedNotes, AugmentedNotes, PowerNotes, Sus4Notes, Sus2Notes];

// return a string containing the names of the scale tones in a given key
String scaleTones(String? key) {
  int index = 0;
  int offset = 0;
  int finalIndex = 0;

  if (key == null) {
    return '';
  }

  // find the key in the list of keys (which is also a list of notes)
  int keyIndex = keys.indexWhere((element) => element == key);

//  print('HF: scaleTones $key, $keyIndex');

  String result = '';
  for(int i=1; i<=7; i++) {
    index = keyIndex;
    offset = scaleTonesIndex[i];
    finalIndex = (index + offset) % 12;
    result = result + keys[finalIndex] + ' ';
  }

//  print('HF: scaleTones $result');

  return result;
}

//Map<String, List> chordMap = Map.fromIterables(chordTypes, chordNotes);

// MIDI code of the note E1 (the lowest note on an electric bass)
// The range of MIDI notes in bass mode is from E1 to the VII of D2 = 53
const int E1midi = 40;
// MIDI code of the note E2 (the lowest note on an acoustic guitar)
// The range of MIDI notes in guitar mode is from E2 to the VII of D3 = 51
const int E2midi = E1midi + 12;
