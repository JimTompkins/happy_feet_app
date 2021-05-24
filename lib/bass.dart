// list of key names for dropdown button.  Note that we start with E since it's the lowest
// note on an electric bass.
List keys = <String>['E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'C', 'C#', 'D', 'D#', ];

List scaleTonesIndex = <int>[0, 0,	2,	4,	5,	7,	9,	11];

List scaleTonesRoman = <String>['-', 'I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

// MIDI code of the note E1 (the lowest note on an electric bass)
// The range of MIDI notes in bass mode is from E1 to the VII of D# = 63
const int E1midi = 40;
