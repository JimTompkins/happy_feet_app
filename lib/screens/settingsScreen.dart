import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
//import '../main.dart';
import '../ble2.dart';
import '../utils.dart';
import '../appDesign.dart';
import '../sharedPrefs.dart';
import 'infoScreen.dart';
import 'walkthroughScreen.dart';

// settings screen
SettingsScreen settingsScreen = new SettingsScreen();

// Stateful version of settings screen
class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  String lang = sharedPrefs.savedLanguage;
  RxBool _playState = Get.find();
  var locale = Get.deviceLocale!;

  final List<HfMenuItem> languageDropdownList = [
    HfMenuItem(text: 'English', color: Colors.grey[100]),
    HfMenuItem(text: 'Français', color: Colors.grey[300]),
    HfMenuItem(text: 'Deutsch', color: Colors.grey[100]),
    HfMenuItem(text: 'Español', color: Colors.grey[300]),
    HfMenuItem(text: 'Italiano', color: Colors.grey[100]),
    HfMenuItem(text: 'Português', color: Colors.grey[300]),
    HfMenuItem(text: 'Nederlands', color: Colors.grey[100]),
    HfMenuItem(text: 'Українська', color: Colors.grey[300]),
  ];

  @override
  initState() {
    lang = sharedPrefs.savedLanguage;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'.tr),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Column(children: <Widget>[
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Change language'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(60, 8, 8, 8),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton2(
                    items: languageDropdownList
                        .map((item) => DropdownMenuItem<String>(
                              value: item.text,
                              child: Container(
                                alignment: AlignmentDirectional.centerStart,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0),
                                color: item.color,
                                child: Text(
                                  item.text,
                                  style: AppTheme
                                      .appTheme.textTheme.headlineMedium,
                                ),
                              ),
                            ))
                        .toList(),
                    selectedItemBuilder: (context) {
                      return languageDropdownList
                          .map(
                            (item) => Container(
                              alignment: Alignment.center,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                item.text,
                                style: AppTheme.appTheme.textTheme.labelMedium,
                              ),
                            ),
                          )
                          .toList();
                    },
                    value: lang,
                    dropdownPadding: EdgeInsets.zero,
                    itemPadding: EdgeInsets.zero,
                    buttonHeight: 40,
                    buttonPadding: const EdgeInsets.only(left: 14, right: 14),
                    buttonDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(),
                      color: AppColors.dropdownBackgroundColor,
                    ),
                    itemHeight: 40,
                    dropdownDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(),
                    ),
                    onChanged: (String? newValue) {
                      setState(() {
                        switch (newValue) {
                          case 'English':
                            locale = Locale('en', 'US');
                            break;
                          case 'Français':
                            locale = Locale('fr', 'FR');
                            break;
                          case 'Deutsch':
                            locale = Locale('de', 'DE');
                            break;
                          case 'Español':
                            locale = Locale('es', 'ES');
                            break;
                          case 'Italiano':
                            locale = Locale('it', 'IT');
                            break;
                          case 'Português':
                            locale = Locale('pt', 'PT');
                            break;
                          case 'Nederlands':
                            locale = Locale('nl', 'NL');
                            break;
                          case 'Українська':
                            locale = Locale('uk', 'UK');
                            break;
                          default:
                            locale = Locale('en', 'US');
                            break;
                        }
                        lang = newValue!;
                        //sharedPrefs.language = newValue;
                        sharedPrefs.savedLanguage = newValue;
                        Get.updateLocale(locale);
                        if (kDebugMode) {
                          print("HF: saved language changed to $newValue");
                        }
                      });
                    },
                  ),
                ),
              ),
              // Text
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Audio test'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Switch(
                value: sharedPrefs.audioTestMode,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() {
                    if (_bluetoothBLEService.isConnected() && value) {
                      // can't turn on audio test mode if BLE is connected
                      Get.snackbar('Error:'.tr,
                          'You cannot use audio test mode if connected.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      sharedPrefs.audioTestMode = value;
                      if (sharedPrefs.audioTestMode) {
                        if (kDebugMode) {
                          print('HF: audio test mode enabled');
                        }
                        Get.snackbar('Status'.tr, 'Audio test mode enabled.'.tr,
                            snackPosition: SnackPosition.BOTTOM);
                      } else {
                        if (kDebugMode) {
                          print('HF: audio test mode disabled');
                        }
                        Get.snackbar(
                            'Status'.tr, 'Audio test mode disabled.'.tr,
                            snackPosition: SnackPosition.BOTTOM);
                      }
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 25,
                color: AppColors.myButtonColor,
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Audio test mode'.tr,
                    middleText:
                        "In audio test mode, tap the music note button to play the next note."
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Multi mode'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Switch(
                value: sharedPrefs.multiMode,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() {
                    sharedPrefs.multiMode = value;
                    if (sharedPrefs.multiMode) {
                      if (kDebugMode) {
                        print('HF: multi mode enabled');
                      }
                      Get.snackbar('Status'.tr, 'Multi mode enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      if (kDebugMode) {
                        print('HF: multi mode disabled');
                      }
                      Get.snackbar('Status'.tr, 'Multi mode disabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 25,
                color: AppColors.myButtonColor,
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Multi mode'.tr,
                    middleText:
                        'Use multi mode if you have more than one HappyFeet.'
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Foot switch'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Switch(
                value: sharedPrefs.footSwitch,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() {
                    sharedPrefs.footSwitch = value;
                    if (sharedPrefs.footSwitch) {
                      if (kDebugMode) {
                        print('HF: foot switch enabled');
                      }
                      Get.snackbar('Status'.tr, 'Foot switch enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      if (kDebugMode) {
                        print('HF: foot switch disabled');
                      }
                      Get.snackbar('Status'.tr, 'Foot switch disabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 25,
                color: AppColors.myButtonColor,
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Foot switch'.tr,
                    middleText:
                        'When the foot switch is enabled, you can enable or disable beats by moving your foot quickly to either side while flat on the floor.'
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Auto mode'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Switch(
                value: sharedPrefs.autoMode,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() {
                    sharedPrefs.autoMode = value;
                    if (sharedPrefs.autoMode) {
                      if (kDebugMode) {
                        print('HF: auto mode enabled');
                      }
                      Get.snackbar('Status'.tr, 'Auto mode enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      if (kDebugMode) {
                        print('HF: auto mode disabled');
                      }
                      Get.snackbar('Status'.tr, 'Auto mode disabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 25,
                color: AppColors.myButtonColor,
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Auto mode'.tr,
                    middleText:
                        'When auto mode is enabled, in 1-tap mode you only have to tap your foot on the first 1, and the groove plays automatically.'
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Tapping mode'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ]),
            Row(children: <Widget>[
              Spacer(flex: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'toe'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              Switch(
                value: sharedPrefs.heelTap,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() {
                    sharedPrefs.heelTap = value;
                    if (sharedPrefs.heelTap) {
                      if (kDebugMode) {
                        print('HF: heel tap mode enabled');
                      }
                      Get.snackbar('Status'.tr, 'Heel tap mode enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      if (kDebugMode) {
                        print('HF: toe tap mode enabled');
                      }
                      Get.snackbar('Status'.tr, 'Toe tap mode enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                    // if connected and beats are enabled, then re-enable
                    // which will send the updated heelTap value
                    if (_bluetoothBLEService.isConnected.value &&
                        _playState.value) {
                      _bluetoothBLEService.enableBeat();
                    }
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'heel'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 25,
                color: AppColors.myButtonColor,
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Tapping Mode'.tr,
                    middleText:
                        'Change this to make HappyFeet detect either toe or heel taps.'
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Row(children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Play on click mode'.tr,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
              ),
            ]),
            Row(children: <Widget>[
              Spacer(flex: 10),
              Switch(
                value: sharedPrefs.playOnClickMode,
                activeColor: Colors.deepOrange[400],
                activeTrackColor: Colors.deepOrange[200],
                inactiveThumbColor: Colors.grey[600],
                inactiveTrackColor: Colors.grey[400],
                onChanged: (value) {
                  setState(() {
                    sharedPrefs.playOnClickMode = value;
                    if (sharedPrefs.playOnClickMode) {
                      if (kDebugMode) {
                        print('HF: play-on-click mode enabled');
                      }
                      Get.snackbar(
                          'Status'.tr, 'Play on click mode enabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    } else {
                      if (kDebugMode) {
                        print('HF: play-on-click mode disabled');
                      }
                      Get.snackbar(
                          'Status'.tr, 'Play on click mode disabled.'.tr,
                          snackPosition: SnackPosition.BOTTOM);
                    }
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.help,
                ),
                iconSize: 25,
                color: AppColors.myButtonColor,
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Play on click mode'.tr,
                    middleText:
                        "In play on click mode, sounds are played when they are selected."
                            .tr,
                    textConfirm: 'OK',
                    onConfirm: () {
                      Get.back();
                    },
                  );
                },
              ),
            ]),
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      child: Text(
                        'Info'.tr,
                        style: AppTheme.appTheme.textTheme.displaySmall,
                      ),
                      onPressed: () {
                        Get.to(() => infoScreen);
                      }),
                ),
              ]),
            ]),
            Wrap(children: <Widget>[
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      child: Text(
                        'Introduction'.tr,
                        style: AppTheme.appTheme.textTheme.displaySmall,
                      ),
                      onPressed: () {
                         // show the walkthrough again next time app is started
                        sharedPrefs.showWalkthrough = true; 
                        Get.to(() => walkthroughScreen);
                      }),
                ),
              ]),
            ]),
          ]), // Column
        ]),
      ),
    );
  } // Widget
} // class
