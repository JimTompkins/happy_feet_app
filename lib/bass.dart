// list of key names for dropdown button.  Note that we start with E since it's the lowest
// note on an electric bass.
List keys = <String>[
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
  'C',
  'C#',
  'D',
  'D#',
];

// Original version: only major scale tones in these lists
//List scaleTonesIndex = <int>[0, 0,	2,	4,	5,	7,	9,	11];
//List scaleTonesRoman = <String>['-', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

// Revised version: all tones in these lists
List scaleTonesIndex = <int>[0, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
List scaleTonesRoman = <String>[
  '-',
  'I',
  'bII',
  'II',
  'bIII',
  'III',
  'IV',
  'bV',
  'V',
  'bVI',
  'VI',
  'bVII',
  'VII'
];
List scaleTonesArabic = <String>[
  '-',
  '1',
  'b2',
  '2',
  'b3',
  '3',
  '4',
  'b5',
  '5',
  'b6',
  '6',
  'b7',
  '7'
];
List allBassNotes = <String>['E1', 'F1',  'F#1', 'G1', 'G#1', 'A1', 'A#1',
                             'B1', 'C2', 'C#2', 'D2', 'D#2', 'E2', 'F2',
                             'F#2', 'G2', 'G#2', 'A2', 'A#2', 'B2', 'C3',
                             'C#3', 'D3', 'D#3'];

List chordsInKey = <String>['M', 'm', 'm', 'M', 'M', 'm', 'dim'];

List chordTypes = <String>['M', 'm', 'dim', 'Aug', 'Pwr', 'sus4', 'sus2'];
List majorNotes = <int>[0, 4, 7]; // where 0 is the tonic
List minorNotes = <int>[0, 3, 7];
List diminishedNotes = <int>[0, 3, 6];
List augmentedNotes = <int>[0, 4, 8];
List powerNotes = <int>[0, 7];
List sus4Notes = <int>[0, 5, 7];
List sus2Notes = <int>[0, 2, 7];
List chordNotes = <List>[
  majorNotes,
  minorNotes,
  diminishedNotes,
  augmentedNotes,
  powerNotes,
  sus4Notes,
  sus2Notes
];

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
  for (int i = 1; i <= 12; i++) {
    // start at 1 to ignore the '-'
    index = keyIndex;
    offset = scaleTonesIndex[i];
    finalIndex = (index + offset) % 12;
    result = result + keys[finalIndex] + ' ';
  }

//  print('HF: scaleTones $result');

  return result;
}

//Map<String, List> chordMap = Map.fromIterables(chordTypes, chordNotes);

// index of the note E1 (the lowest note on an electric bass)
//const int E1index = 40;
// MIDI code of the note E2 (the lowest note on an acoustic guitar)
// The range of MIDI notes in guitar mode is from E2 to the VII of D3 = 51
//const int E2midi = E1midi + 12;

//const int A1midi = 33;
//const int C2midi = 48;
//const int C4midi = 72;

const int E1mp3 =
    40; // the starting index for bass note mp3 files in soundIdMap in audio.dart

const int E1ogg =
    40;  // the starting index for bass note .ogg files in audio.dart
