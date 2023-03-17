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
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Bass drum'.tr,
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

                  // play the sound
                  hfaudio.play(groove.notes[0].oggIndex, -1);
                },
              ),
            ),
          ]),
          Row(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Snare drum'.tr,
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
                value: snareDrumVolume,
                onChanged: (val) {
                  setState(() {
                    snareDrumVolume = val;
                  });
                  // adjust the volume
                  
                  // play the sound
                  hfaudio.play(groove.notes[1].oggIndex, -1);
                },
              ),
            ),
          ]),
          Row(children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'Bass'.tr,
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
                value: bassVolume,
                onChanged: (val) {
                  setState(() {
                    bassVolume = val;
                  });
                  // adjust the volume
                  
                  // play the sound
                  hfaudio.play(groove.notes2[0].oggIndex, -1);
                },
              ),
            ),
          ]),
        ]),
      ),
    );
  } // Widget

}
