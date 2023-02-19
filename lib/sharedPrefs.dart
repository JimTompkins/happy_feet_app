// sharedPrefs.dart
//import 'package:flutter/foundation.dart';
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
/*
  // this version of the audioTestMode getter was used to measure the time taken
  // to call the shared_preferences get.  Result = 3ms.  Seems a bit long.
  bool get audioTestMode {
    var before = DateTime.now().millisecond; // get system time
    var result = _sharedPrefs?.getBool('audioTestMode') ?? false;
    var after = DateTime.now().millisecond;
    var duration = after - before;
    if (kDebugMode) {
      print('HF: get audioTestMode duration = $duration ms');
    }
    return result;
  }
*/

  set audioTestMode(bool value) {
    // the commented code was used to measure the time required to
    // set a shared_preference.  Result = 14ms.  Seems very long
    // but setting should not be used for anything time critical...
    //var before = DateTime.now().millisecond; // get system time
    _sharedPrefs?.setBool('audioTestMode', value);
    //var after = DateTime.now().millisecond;
    //var duration = after - before;
    //if (kDebugMode) {
    //  print('HF: set audioTestMode duration = $duration ms');
    //}
  }

// flag used to enable multi mode.  Use multi mode if you have more than one
// HappyFeet.  In multi mode, it will show all of the HappyFeet discovered
// when connecting, and let you select which one you want to connect to.
  bool get multiMode => _sharedPrefs?.getBool('multiMode') ?? false;

  set multiMode(bool value) {
    _sharedPrefs?.setBool('multiMode', value);
  }

// flag used to enable the foot switch.  When foot switch is enabled, you
// can move your foot quickly to either side while it is flat on the floor
// to enable or disable beats.
  bool get footSwitch => _sharedPrefs?.getBool('footSwitch') ?? false;

  set footSwitch(bool value) {
    _sharedPrefs?.setBool('footSwitch', value);
  }

// flag used to enable toe or heel tapping.  The default setting is heel tapping
  bool get heelTap => _sharedPrefs?.getBool('heelTap') ?? true;

  set heelTap(bool value) {
    _sharedPrefs?.setBool('heelTap', value);
  }

// flag used to enable auto mode in 1-tap mode.  When auto mode is enabled,
// 1-tap mode only needs you to do the 4 beat lead-in and then tap the first 1.
// It will play the selected groove automatically using the tempo set during
// the lead-in.
  bool get autoMode => _sharedPrefs?.getBool('autoMode') ?? false;

  set autoMode(bool value) {
    _sharedPrefs?.setBool('autoMode', value);
  }

// flag used to enable play-on-click mode.  When this is enabled, when you select
// a sound, it will be played.  This is useful when you are learning how to
// make grooves.
  bool get playOnClickMode => _sharedPrefs?.getBool('playOnClickMode') ?? false;

  set playOnClickMode(bool value) {
    _sharedPrefs?.setBool('playOnClickMode', value);
  }

// flag used to show the walkthrough.  It is initially set to true but can
// be set to false by hitting the skip button on the walkthrough
  bool get showWalkthrough => _sharedPrefs?.getBool('showWalkthrough') ?? true;

  set showWalkthrough(bool value) {
    _sharedPrefs?.setBool('showWalkthrough', value);
  }

// flag indicating whether a metronome is used in Practice mode or not.
// If set to true, a metronome tone (consisting of C4 and G4 on piano)
// will be played at the selected tempo
  bool get metronomeFlag => _sharedPrefs?.getBool('metronomeFlag') ?? false;

  set metronomeFlag(bool value) {
    _sharedPrefs?.setBool('metronomeFlag', value);
  }

}

final sharedPrefs = SharedPrefs();

/*
  savedLanguage = prefs.getString('language') ?? '';
*/

// saved preference for language
//String savedLanguage = '';
//String language = '';

