import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../audioBASS.dart'; // BASS version
//import '../groove.dart';
import '../appDesign.dart';
import '../sharedPrefs.dart';

class EqualizerEntry {
  String name = '-';
  double volume = 1.0;
  String savedValue = 'A';

  EqualizerEntry(this.name, this.volume, this.savedValue);

  EqualizerEntry.withoutSavedValue(name, volume) {
    this.name = name;
    this.volume = volume;
    this.savedValue = doubleToString(volume);
  }

  // convert a double on the range 0:1 to a single character string
  // as follows: 0:0.1 = '0', 0.1:0.2 = '1', ..., 1.0 = 'A'
  String doubleToString(double x) {
    int y = (x * 10.0).round();
    String result = '0';
    if (y < 10) {
      result = y.toString();
    } else {
      result = 'A';
    }
    return result;
  }
}

BluesEqualizer bluesEqualizer = new BluesEqualizer();

class BluesEqualizer {
  EqualizerEntry bassDrum = EqualizerEntry.withoutSavedValue('Bass drum', 1.0);
  EqualizerEntry snareDrum =
      EqualizerEntry.withoutSavedValue('Snare drum', 1.0);
  EqualizerEntry bass = EqualizerEntry.withoutSavedValue('Bass', 1.0);

  // convert a double on the range 0:1 to a single character string
  // as follows: 0:0.1 = '0', 0.1:0.2 = '1', ..., 1.0 = 'A'
  String doubleToString(double x) {
    int y = (x * 10.0).round();
    String result = '0';
    if (y < 10) {
      result = y.toString();
    } else {
      result = 'A';
    }
    return result;
  }

  // convert a single character string to a double as follows:
  // '0' = 0.0, '1' = 0.1, ..., '9' = 0.9, 'A' = 1.0
  double stringToDouble(String x) {
    double result = 0.0;
    if (x == 'A') {
      result = 1.0;
    } else {
      result = 0.1 * int.parse(x);
    }
    return result;
  }

  // save the three volume levels to a text string in shared preferences
  void saveVolumeLevel() {
    String volumeString = doubleToString(bassDrum.volume) +
        doubleToString(snareDrum.volume) +
        doubleToString(bass.volume);
    if (kDebugMode) {
      print('Hf: saveVolumeLevel: string = $volumeString');
    }
    sharedPrefs.bluesVolume = volumeString;
  }

  // load the three volume levels from a text string in shared preferences
  void loadVolumeLevel() {
    String volumeString = sharedPrefs.bluesVolume;
    if (volumeString.length != 3) {
      volumeString = 'AAA';
    }
    //print('Hf: loadVolumeLevel: volumeString = $volumeString');
    bassDrum.volume = stringToDouble(volumeString[0]);
    snareDrum.volume = stringToDouble(volumeString[1]);
    bass.volume = stringToDouble(volumeString[2]);
    if (kDebugMode) {
      print(
          'Hf: loadVolumeLevel: volumeString = $volumeString, bassDrumVolume = ${bassDrum.volume}, snareDrumVolume = ${snareDrum.volume}, bassVolume = ${bass.volume}');
    }
  }
}

// blues equalizer screen: this screen has sliders for the volume
// level of the three notes used in blues mode: bass drum, snare and bass
BluesEqualizerScreen bluesEqualizerScreen = new BluesEqualizerScreen();

// Stateful version of equalizer screen
class BluesEqualizerScreen extends StatefulWidget {
  @override
  BluesEqualizerScreenState createState() => BluesEqualizerScreenState();
}

class BluesEqualizerScreenState extends State<BluesEqualizerScreen> {
  // a function to add a row with a text widget with a note name
  // and a slider for the volume for that note.  When the slider is
  // pressed, that note's volume is adjusted.
  Widget equalizerRow(String noteName, int index, EqualizerEntry eq) {
    return Row(children: <Widget>[
      Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              noteName.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )),
      Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Slider(
              min: 0.0,
              max: 1.0,
              activeColor: AppColors.settingsIconColor,
              divisions: 10,
              value: eq.volume,
              onChanged: (val) {
                setState(() {
                  eq.volume = val;
                });
                // adjust the volume
                hfaudio.setVolume(index, val);

                // play the sound
                hfaudio.play(index, -1);
              },
            ),
          )),
    ]);
  }

  @override
  initState() {
    super.initState();
    bluesEqualizer.loadVolumeLevel();
  }

  @override
  void dispose() {
    super.dispose();
    bluesEqualizer.saveVolumeLevel();
  }

  // a function to added a row with a text widget with a note category
  // such as bass notes, and a slider for adjusting the volume of every
  // note between startIndex and stopIndex
  Widget equalizerRowRange(
      String noteName, int startIndex, int stopIndex, EqualizerEntry eq) {
    return Row(children: <Widget>[
      Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              noteName.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )),
      Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Slider(
              min: 0.0,
              max: 1.0,
              activeColor: AppColors.settingsIconColor,
              divisions: 10,
              value: eq.volume,
              onChanged: (val) {
                setState(() {
                  eq.volume = val;
                });
                // adjust the volume
                hfaudio.setVolumeRange(startIndex, stopIndex, val);

                // play the sound
                hfaudio.play(startIndex, -1);
              },
            ),
          )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equalizer'.tr),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Row(children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Adjust the sound levels'.tr,
                  softWrap: true,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
          ]),
/*
          Row(children: <Widget>[
            Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Bass drum'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
            Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.settingsIconColor,
                    divisions: 10,
                    value: bassDrum.volume,
                    onChanged: (val) {
                      setState(() {
                        bassDrum.volume = val;
                      });
                      // adjust the volume
                      hfaudio.setVolume(groove.notes[0].oggIndex, val);

                      // play the sound
                      hfaudio.play(groove.notes[0].oggIndex, -1);
                    },
                  ),
                )),
          ]),
*/
          equalizerRow('Bass drum', 0, bluesEqualizer.bassDrum),
/*
          Row(children: <Widget>[
            Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Snare drum'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
            Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.settingsIconColor,
                    divisions: 10,
                    value: snareDrum.volume,
                    onChanged: (val) {
                      setState(() {
                        snareDrum.volume = val;
                      });
                      // adjust the volume
                      hfaudio.setVolume(groove.notes[1].oggIndex, val);

                      // play the sound
                      hfaudio.play(groove.notes[1].oggIndex, -1);
                    },
                  ),
                )),
          ]),
*/
          equalizerRow('Snare drum', 2, bluesEqualizer.snareDrum),
/*
          Row(children: <Widget>[
            Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Bass'.tr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )),
            Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Slider(
                    min: 0.0,
                    max: 1.0,
                    activeColor: AppColors.settingsIconColor,
                    divisions: 10,
                    value: bass.volume,
                    onChanged: (val) {
                      setState(() {
                        bass.volume = val;
                      });
                      // adjust the volume of all bass notes
                      hfaudio.setVolumeRange(40, 63, val);

                      // play the sound
                      hfaudio.play(groove.notes2[0].oggIndex, -1);
                    },
                  ),
                )),
          ]),
*/
          equalizerRowRange('Bass', 40, 63, bluesEqualizer.bass),
        ]),
      ),
    );
  } // Widget
}

PercussionEqualizer percussionEqualizer = new PercussionEqualizer();

class PercussionEqualizer {
  EqualizerEntry bassDrum = EqualizerEntry.withoutSavedValue('Bass drum', 1.0);
  EqualizerEntry bassEcho = EqualizerEntry.withoutSavedValue('Bass echo', 1.0);
  EqualizerEntry snareDrum =
      EqualizerEntry.withoutSavedValue('Snare drum', 1.0);
  EqualizerEntry hiHat = EqualizerEntry.withoutSavedValue('Hi-hat cymbal', 1.0);
  EqualizerEntry cowbell = EqualizerEntry.withoutSavedValue('Cowbell', 1.0);
  EqualizerEntry tambourine =
      EqualizerEntry.withoutSavedValue('Tambourine', 1.0);
  EqualizerEntry fingersnap =
      EqualizerEntry.withoutSavedValue('Fingersnap', 1.0);
  EqualizerEntry rimshot = EqualizerEntry.withoutSavedValue('Rim shot', 1.0);
  EqualizerEntry shaker = EqualizerEntry.withoutSavedValue('Shaker', 1.0);
  EqualizerEntry woodblock = EqualizerEntry.withoutSavedValue('Woodblock', 1.0);
  EqualizerEntry loTom = EqualizerEntry.withoutSavedValue('Lo tom', 1.0);
  EqualizerEntry hiTom = EqualizerEntry.withoutSavedValue('Hi tom', 1.0);
  EqualizerEntry brushes = EqualizerEntry.withoutSavedValue('Brushes', 1.0);
  EqualizerEntry quijada = EqualizerEntry.withoutSavedValue('Quijada', 1.0);

  // convert a double on the range 0:1 to a single character string
  // as follows: 0:0.1 = '0', 0.1:0.2 = '1', ..., 1.0 = 'A'
  String doubleToString(double x) {
    int y = (x * 10.0).round();
    String result = '0';
    if (y < 10) {
      result = y.toString();
    } else {
      result = 'A';
    }
    return result;
  }

  // convert a single character string to a double as follows:
  // '0' = 0.0, '1' = 0.1, ..., '9' = 0.9, 'A' = 1.0
  double stringToDouble(String x) {
    double result = 0.0;
    if (x == 'A') {
      result = 1.0;
    } else {
      result = 0.1 * int.parse(x);
    }
    return result;
  }

  // save the 14 volume levels to a text string in shared preferences
  void saveVolumeLevel() {
    String volumeString = doubleToString(bassDrum.volume) +
        doubleToString(bassEcho.volume) +
        doubleToString(loTom.volume) +
        doubleToString(hiTom.volume) +
        doubleToString(snareDrum.volume) +
        doubleToString(hiHat.volume) +
        doubleToString(cowbell.volume) +
        doubleToString(tambourine.volume) +
        doubleToString(fingersnap.volume) +
        doubleToString(rimshot.volume) +
        doubleToString(shaker.volume) +
        doubleToString(woodblock.volume) +
        doubleToString(brushes.volume) +
        doubleToString(quijada.volume);

    if (kDebugMode) {
      print('Hf: saveVolumeLevel: string = $volumeString');
    }
    sharedPrefs.percussionVolume = volumeString;
  }

  // load the 14 volume levels from a text string in shared preferences
  void loadVolumeLevel() {
    String volumeString = sharedPrefs.percussionVolume;
    if (volumeString.length != 14) {
      volumeString = 'AAAAAAAAAAAAAA';
    }
    bassDrum.volume = stringToDouble(volumeString[0]);
    bassEcho.volume = stringToDouble(volumeString[1]);
    loTom.volume = stringToDouble(volumeString[2]);
    hiTom.volume = stringToDouble(volumeString[3]);
    snareDrum.volume = stringToDouble(volumeString[4]);
    hiHat.volume = stringToDouble(volumeString[5]);
    cowbell.volume = stringToDouble(volumeString[6]);
    tambourine.volume = stringToDouble(volumeString[7]);
    fingersnap.volume = stringToDouble(volumeString[8]);
    rimshot.volume = stringToDouble(volumeString[9]);
    shaker.volume = stringToDouble(volumeString[10]);
    woodblock.volume = stringToDouble(volumeString[11]);
    brushes.volume = stringToDouble(volumeString[12]);
    quijada.volume = stringToDouble(volumeString[13]);
    if (kDebugMode) {
      print(
          'Hf: loadVolumeLevel: volumeString = $volumeString, bassDrumVolume = ${bassDrum.volume}, snareDrumVolume = ${snareDrum.volume}');
    }
  }
}

// percussion equalizer screen: this screen has sliders for the volume
// level of the 14 percussion sounds
PercussionEqualizerScreen percussionEqualizerScreen =
    new PercussionEqualizerScreen();

// Stateful version of equalizer screen
class PercussionEqualizerScreen extends StatefulWidget {
  @override
  PercussionEqualizerScreenState createState() =>
      PercussionEqualizerScreenState();
}

class PercussionEqualizerScreenState extends State<PercussionEqualizerScreen> {
  // a function to add a row with a text widget with a note name
  // and a slider for the volume for that note.  When the slider is
  // pressed, that note's volume is adjusted.
  Widget equalizerRow(String noteName, int index, EqualizerEntry eq) {
    return Row(children: <Widget>[
      Expanded(
          flex: 4,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              noteName.tr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )),
      Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Slider(
              min: 0.0,
              max: 1.0,
              activeColor: AppColors.settingsIconColor,
              divisions: 10,
              value: eq.volume,
              onChanged: (val) {
                setState(() {
                  eq.volume = val;
                });
                // adjust the volume
                hfaudio.setVolume(index, val);

                // play the sound
                hfaudio.play(index, -1);
              },
            ),
          )),
    ]);
  }

  @override
  initState() {
    super.initState();
    percussionEqualizer.loadVolumeLevel();
  }

  @override
  void dispose() {
    super.dispose();
    percussionEqualizer.saveVolumeLevel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Equalizer'.tr),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Row(children: <Widget>[
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Adjust the sound levels'.tr,
                  softWrap: true,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
          ]),
          equalizerRow('Bass drum', 0, percussionEqualizer.bassDrum),
          equalizerRow('Bass echo', 1, percussionEqualizer.bassEcho),
          equalizerRow('Lo tom', 11, percussionEqualizer.loTom),
          equalizerRow('Hi tom', 12, percussionEqualizer.hiTom),
          equalizerRow('Snare drum', 2, percussionEqualizer.snareDrum),
          equalizerRow('Hi-hat cymbal', 3, percussionEqualizer.hiHat),
          equalizerRow('Cowbell', 4, percussionEqualizer.cowbell),
          equalizerRow('Tambourine', 5, percussionEqualizer.tambourine),
          equalizerRow('Fingersnap', 7, percussionEqualizer.fingersnap),
          equalizerRow('Rim shot', 8, percussionEqualizer.rimshot),
          equalizerRow('Shaker', 9, percussionEqualizer.shaker),
          equalizerRow('Woodblock', 10, percussionEqualizer.woodblock),
          equalizerRow('Brushes', 13, percussionEqualizer.brushes),
          equalizerRow('Quijada', 14, percussionEqualizer.quijada),
        ]),
      ),
    );
  } // Widget
}
