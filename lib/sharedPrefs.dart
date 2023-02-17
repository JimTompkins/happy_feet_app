// sharedPrefs.dart
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefs {
  static SharedPreferences? _sharedPrefs;

  init() async {
    if (_sharedPrefs == null) {
      _sharedPrefs = await SharedPreferences.getInstance();
    }
  }

// flag used to enable a test mode where the play button is used to play sounds
// rather than BLE notifies.  This is used to separate the testing of the
// audio from the BLE interface.
  bool get audioTestMode => _sharedPrefs?.getBool('audioTestMode') ?? false;

  set audioTestMode(bool value) {
    _sharedPrefs?.setBool('audioTestMode', value);
  }

}

final sharedPrefs = SharedPrefs();

/*
  multiMode = prefs.getBool('multiMode') ?? false;
  footSwitch = prefs.getBool('footSwitch') ?? false;
  autoMode = prefs.getBool('autoMode') ?? false;
  heelTap = prefs.getBool('heelTap') ?? false;
  playOnClickMode = prefs.getBool('playOnClickMode') ?? false;
  showWalkthrough = prefs.getBool('showWalkthrough') ?? true;
  metronomeFlag = prefs.getBool('metronomeFlag') ?? false;
  savedLanguage = prefs.getString('language') ?? '';
*/

// flag used to enable multi mode.  Use multi mode if you have more than one
// HappyFeet.  In multi mode, it will show all of the HappyFeet discovered
// when connecting, and let you select which one you want to connect to.
//bool multiMode = false;

// flag used to enable the foot switch.  When foot switch is enabled, you
// can move your foot quickly to either side while it is flat on the floor
// to enable or disable beats.
//bool footSwitch = false;

// flag used to enable toe or heel tapping.  The default setting is heel tapping
//bool heelTap = true;

// saved preference for language
//String savedLanguage = '';
//String language = '';

// flag used to enable auto mode in 1-tap mode.  When auto mode is enabled,
// 1-tap mode only needs you to do the 4 beat lead-in and then tap the first 1.
// It will play the selected groove automatically using the tempo set during
// the lead-in.
//bool autoMode = false;

// flag used to enable play-on-click mode.  When this is enabled, when you select
// a sound, it will be played.  This is useful when you are learning how to
// make grooves.
//bool playOnClickMode = false;

// flag indicating whether a metronome is used in Practice mode or not.
// If set to true, a metronome tone (consisting of C4 and G4 on piano)
// will be played at the selected tempo
//bool metronomeFlag = false;

// flag used to show the walkthrough.  It is initially set to true but can
// be set to false by hitting the skip button on the walkthrough
//bool showWalkthrough = true;