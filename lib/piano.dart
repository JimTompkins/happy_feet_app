import 'package:/flutter/foundation.dart';

// list of key names for dropdown button.  Note that we start with E since it's the lowest

// note on an electric bass.
List pianoKeys = <String>[
  'C',
  'C#',
  'D',
  'D#',
  'E',
  'F',
  'F#',
  'G',
  'G#',
  'A',
  'A#',
  'B',
];

enum KeyType { major, minor }

List chordsInMajorKey = <String>['M', 'm', 'm', 'M', 'M', 'm', '-'];
List chordsInMinorKey = <String>['m', '-', 'M', 'm', 'm', 'M', 'M'];
List scaleTonesIndex = <int>[0, 2, 4, 5, 7, 9, 11];

List chordTypes = <String>['M', 'm', '-', '+'];

// return a string containing the names of the chords in the given key and type
// e.g. chords in Cmaj = Cmaj, Dmin, Emin, Fmaj, Gmaj, Amin, Bdim
String pianoChords(String? key, KeyType? type) {
  int index = 0;
  int offset = 0;
  int finalIndex = 0;

  if ((key == null) || (type == null)) {
    return '???';
  }

  // find the key in the list of keys (which is also a list of notes)
  int keyIndex = pianoKeys.indexWhere((element) => element == key);

  if (kDebugMode) {
    print('HF: pianoChords: key=$key, keyIndex=$keyIndex');
  }

  String result = '';
  for (int i = 0; i < 7; i++) {
    index = keyIndex;
    offset = scaleTonesIndex[i];
    finalIndex = (index + offset) % 12;
    if (type == KeyType.major) {
      result = result + pianoKeys[finalIndex] + chordsInMajorKey[i] + ' ';
    } else if (type == KeyType.minor) {
      result = result + pianoKeys[finalIndex] + chordsInMinorKey[i] + ' ';
    }
  }

  if (kDebugMode) {
    print('HF: pianoChords: result=$result');
  }

  return result;
}
