import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../audioBASS.dart'; // BASS version
import '../groove.dart';
import '../appDesign.dart';
import '../sharedPrefs.dart';

// equalizer screen
EqualizerScreen equalizerScreen = new EqualizerScreen();

// Stateful version of equalizer screen
class EqualizerScreen extends StatefulWidget {
  @override
  _EqualizerScreenState createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends State<EqualizerScreen> {
  double bassDrumVolume = 1.0;
  double snareDrumVolume = 1.0;
  double bassVolume = 1.0;

  @override
  initState() {
    super.initState();
    loadVolumeLevel();
  }

  @override
  void dispose() {
    super.dispose();
    saveVolumeLevel();
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
    String volumeString = doubleToString(bassDrumVolume) +
        doubleToString(snareDrumVolume) +
        doubleToString(bassVolume);
    if (kDebugMode) {
      print('Hf: saveVolumeLevel: string = $volumeString');
    }
    sharedPrefs.bluesVolume = volumeString;
  }

  // load the three volume levels from a text string in shared preferences
  void loadVolumeLevel() {
    //String volumeString = 'A98';
    String volumeString = sharedPrefs.bluesVolume;
    bassDrumVolume = stringToDouble(volumeString[0]);
    snareDrumVolume = stringToDouble(volumeString[1]);
    bassVolume = stringToDouble(volumeString[2]);
    if (kDebugMode) {
      print(
          'Hf: loadVolumeLevel: volumeString = $volumeString, bassDrumVolume = $bassDrumVolume, snareDrumVolume = $snareDrumVolume, bassVolume = $bassVolume');
    }
  }

  // Note: the next two functions are not yet working corretly.
  // The volume level does not update when the slider is pressed.
  // Must be a call-by-value problem.
  // a function to add a row with a text widget with a note name
  // and a slider for the volume for that note.  When the slider is
  // pressed, that note's volume is adjusted.
/*
  Widget equalizerRow(String noteName, int index, double volumeVar) {
    return Row(children: <Widget>[
      Expanded(flex: 4, child:Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          noteName.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      )),
      Expanded(flex: 6, child:Padding(
        padding: const EdgeInsets.all(8.0),
        child: Slider(
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.settingsIconColor,
          divisions: 10,
          value: volumeVar,
          onChanged: (val) {
            setState(() {
              volumeVar = val;
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

  // a function to added a row with a text widget with a note category
  // such as bass notes, and a slider for adjusting the volume of every
  // note between startIndex and stopIndex
  Widget equalizerRowRange(String noteName, int startIndex, int stopIndex, double volumeVar) {
    return Row(children: <Widget>[
      Expanded(flex: 4, child:Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          noteName.tr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      )),
      Expanded(flex: 6, child:Padding(
        padding: const EdgeInsets.all(8.0),
        child: Slider(
          min: 0.0,
          max: 1.0,
          activeColor: AppColors.settingsIconColor,
          divisions: 10,
          value: volumeVar,
          onChanged: (val) {
            setState(() {
              volumeVar = val;
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
*/

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
                    value: bassDrumVolume,
                    onChanged: (val) {
                      setState(() {
                        bassDrumVolume = val;
                      });
                      // adjust the volume
                      hfaudio.setVolume(groove.notes[0].oggIndex, val);

                      // play the sound
                      hfaudio.play(groove.notes[0].oggIndex, -1);
                    },
                  ),
                )),
          ]),

          //equalizerRow('Bass drum', 0, bassDrumVolume),

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
                    value: snareDrumVolume,
                    onChanged: (val) {
                      setState(() {
                        snareDrumVolume = val;
                      });
                      // adjust the volume
                      hfaudio.setVolume(groove.notes[1].oggIndex, val);

                      // play the sound
                      hfaudio.play(groove.notes[1].oggIndex, -1);
                    },
                  ),
                )),
          ]),

          //equalizerRow('Snare drum', 2, snareDrumVolume),

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
                    value: bassVolume,
                    onChanged: (val) {
                      setState(() {
                        bassVolume = val;
                      });
                      // adjust the volume of all bass notes
                      hfaudio.setVolumeRange(40, 63, val);

                      // play the sound
                      hfaudio.play(groove.notes2[0].oggIndex, -1);
                    },
                  ),
                )),
          ]),

          //equalizerRowRange('Bass', 40, 63, bassVolume),
        ]),
      ),
    );
  } // Widget

}
