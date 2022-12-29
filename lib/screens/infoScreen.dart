import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import '../ble2.dart';
import '../appDesign.dart';

_launchURLHomePage() async {
  const url = 'https://happyfeet-music.com';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

_launchURLPrivacyPage() async {
  const url = 'https://happyfeet-music.com/app-privacy/';
  if (await canLaunch(url)) {
    await launch(url);
  } else {
    throw 'Could not launch $url';
  }
}

_emailUs() async {
  final Email email = Email(
    recipients: ['info@happyfeet-music.com'],
  );
  await FlutterEmailSender.send(email);
}

// info scren
InfoScreen infoScreen = new InfoScreen();

// Stateful version of Info page
class InfoScreen extends StatefulWidget {
  @override
  _InfoScreenState createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  Future<String>? _modelNumber;
  Future<String>? _firmwareRevision;
  Future<String>? _rssi;
  Future<String>? _bleAddress;
  Future<int>? _batteryVoltage;
  static const double iconSize = 25;

  @override
  initState() {
    super.initState();
    _initPackageInfo();
    _modelNumber = _bluetoothBLEService.readModelNumber();
    _firmwareRevision = _bluetoothBLEService.readFirmwareRevision();
    _rssi = _bluetoothBLEService.readRSSI();
    _bleAddress = _bluetoothBLEService.readBleAddress();
    _batteryVoltage = _bluetoothBLEService.readBatteryVoltage();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Info'.tr),
      ),
      body: Center(
        child: ListView(children: <Widget>[
          Column(
            children: <Widget>[
              
              Row(children: <Widget>[
                Flexible(child:FractionallySizedBox(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('App version:'.tr, maxLines: 2,
                      style: Theme.of(context).textTheme.caption,),
                    ),
                  ), 
                ),
                Flexible(child:FractionallySizedBox(
                  alignment: Alignment.center,
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(_packageInfo.version, maxLines: 2,
                      style: Theme.of(context).textTheme.caption,),
                    ),
                  ),
                ),                
              ]),
              
              Row(children: <Widget>[
                Flexible(child: FractionallySizedBox(
                    widthFactor: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('Serial number:'.tr, 
                        maxLines: 3,
                        style: Theme.of(context).textTheme.caption,),
                    ),
                  ),
                ),
                Flexible(child: FractionallySizedBox(
                  widthFactor: 1,
                  alignment: Alignment.center,
                  //child:Flexible(
                  // this widget is here so that text wrapping will work...
                  child: FutureBuilder<String>(
                      future: _bleAddress,
                      builder: (BuildContext context,
                          AsyncSnapshot<String> snapshot) {
                        List<Widget> children;
                        if (snapshot.hasData) {
                          if (snapshot.data == 'not connected'.tr) {
                            children = <Widget>[
                              const Icon(
                                Icons.question_mark,
                                color: Colors.grey,
                                size: iconSize,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text('${snapshot.data}', 
                                  maxLines: 3,
                                  style: Theme.of(context).textTheme.caption,
                                  ),
                              )
                            ];
                          } else {
                            children = <Widget>[
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.green,
                                size: iconSize,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Text('${snapshot.data}', 
                                  maxLines: 3,
                                  style: Theme.of(context).textTheme.caption,
                                  ),
                              )
                            ];
                          }
                        } else if (snapshot.hasError) {
                          children = <Widget>[
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: iconSize,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: Text('Error: ${snapshot.error}'.tr, 
                                maxLines: 3,
                                style: Theme.of(context).textTheme.caption,
                                ),
                            )
                          ];
                        } else {
                          children = const <Widget>[
                            SizedBox(
                              child: CircularProgressIndicator(),
                              width: iconSize,
                              height: iconSize,
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 16),
                              child: Text(
                                  '...'), // can't translate a string here...
                            )
                          ];
                        }
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: children,
                          ),
                        );
                      }),
                    //),
                  ),
                ),
              ]),
              Row(children: <Widget>[
                Flexible(child: FractionallySizedBox(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('RSSI:'.tr,
                      maxLines: 3,
                      style: Theme.of(context).textTheme.caption,
                      ),
                  ),
                ),
                ),
                FutureBuilder<String>(
                    future: _rssi,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      List<Widget> children;
                      if (snapshot.hasData) {
                        children = <Widget>[
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Result: ${snapshot.data}' + 'dB',
                              maxLines: 3,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          )
                        ];
                      } else if (snapshot.hasError) {
                        children = <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Error: ${snapshot.error}'.tr,
                              maxLines: 3,
                              style: Theme.of(context).textTheme.caption,
                            ),
                          )
                        ];
                      } else {
                        children = const <Widget>[
                          SizedBox(
                            child: CircularProgressIndicator(),
                            width: iconSize,
                            height: iconSize,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child:
                                Text('...'), // can't translate a string here...
                          )
                        ];
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children,
                        ),
                      );
                    })
              ]),

              Row(children: <Widget>[
                Flexible(child: FractionallySizedBox(
                  widthFactor: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                      child: Text('Model number:'.tr,
                        maxLines: 3,
                        style: Theme.of(context).textTheme.caption,
                      ),
                  ),
                  ),
                ),
                FutureBuilder<String>(
                    future: _modelNumber,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      List<Widget> children;
                      if (snapshot.hasData) {
                        children = <Widget>[
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Result: ${snapshot.data}'.tr),
                          )
                        ];
                      } else if (snapshot.hasError) {
                        children = <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Error: ${snapshot.error}'.tr),
                          )
                        ];
                      } else {
                        children = const <Widget>[
                          SizedBox(
                            child: CircularProgressIndicator(),
                            width: iconSize,
                            height: iconSize,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child:
                                Text('...'), // can't translate a string here...
                          )
                        ];
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children,
                        ),
                      );
                    })
              ]),
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Firmware revision'.tr,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                FutureBuilder<String>(
                    future: _firmwareRevision,
                    builder:
                        (BuildContext context, AsyncSnapshot<String> snapshot) {
                      List<Widget> children;
                      if (snapshot.hasData) {
                        children = <Widget>[
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Result: ${snapshot.data}'.tr),
                          )
                        ];
                      } else if (snapshot.hasError) {
                        children = <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Error: ${snapshot.error}'.tr),
                          )
                        ];
                      } else {
                        children = const <Widget>[
                          SizedBox(
                            child: CircularProgressIndicator(),
                            width: iconSize,
                            height: iconSize,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('...'),
                          )
                        ];
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children,
                        ),
                      );
                    })
              ]),
              Row(children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Battery charge level:'.tr,
                    maxLines: 3,
                    style: Theme.of(context).textTheme.caption,
                  ),
                ),
                FutureBuilder<int>(
                    future: _batteryVoltage,
                    builder:
                        (BuildContext context, AsyncSnapshot<int> snapshot) {
                      List<Widget> children;
                      if (snapshot.hasData) {
                        children = <Widget>[
                          const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child:
                                Text('Result: ${snapshot.data.toString()}%'.tr),
                          )
                        ];
                      } else if (snapshot.hasError) {
                        children = <Widget>[
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: iconSize,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Text('Error: ${snapshot.error}'.tr),
                          )
                        ];
                      } else {
                        children = const <Widget>[
                          SizedBox(
                            child: CircularProgressIndicator(),
                            width: iconSize,
                            height: iconSize,
                          ),
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text('...'),
                          )
                        ];
                      }
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: children,
                        ),
                      );
                    })
              ]),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      onPressed: _launchURLHomePage,
                      child: new Text(
                        'Show HappyFeet homepage'.tr,
                        style: AppTheme.appTheme.textTheme.caption,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      onPressed: _launchURLPrivacyPage,
                      child: new Text(
                        'Show privacy policy'.tr,
                        style: AppTheme.appTheme.textTheme.caption,
                      ),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStatePropertyAll<Color>(
                            AppColors.myButtonColor),
                      ),
                      onPressed: _emailUs,
                      child: new Text(
                        'Contact us'.tr,
                        style: AppTheme.appTheme.textTheme.caption,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ]),
      ),
    );
  } // Widget
} // class
