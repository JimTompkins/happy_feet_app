import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../audioBASS.dart'; // BASS version
import '../groove.dart';
import '../appDesign.dart';

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
  }

  Widget equalizerRow(String noteName, int index) {
    return Row(children: <Widget>[
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          noteName.tr,
          style: Theme.of(context).textTheme.displayMedium,
        ),
      ),
      Padding(
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
            hfaudio.setVolume(index, val);

            // play the sound
            hfaudio.play(index, -1);
          },
        ),
      ),
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

          //equalizerRow('Bass drum', 0),
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
          
          //equalizerRow('Snare drum', 2),
          
          Row(children: <Widget>[
            Expanded(flex: 4, 
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
          
          //equalizerRow('Bass', 40),
        ]),
      ),
    );
  } // Widget

}
