import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/foundation.dart';
import '../ble2.dart'; // flutter_blue_plus version
//import '../appDesign.dart';

// multi-connect page
MultiConnectPage multiConnectPage = new MultiConnectPage();

// Stateful version of multiConnectPage page
class MultiConnectPage extends StatefulWidget {
  @override
  _MultiConnectPageState createState() => _MultiConnectPageState();
}

class _MultiConnectPageState extends State<MultiConnectPage> {
  static BluetoothBLEService _bluetoothBLEService = Get.find();
  int? _rssi = 0;
  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Happy Feet - Multi-connect'.tr),
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(6),
        child: Column(
          children: <Widget>[
            Row(
              children: [
                Text(
                  'Select an available HappyFeet:'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                IconButton(
                  icon: Icon(
                    Icons.help,
                  ),
                  iconSize: 30,
                  color: Colors.blue[800],
                  onPressed: () {
                    Get.defaultDialog(
                      title: 'Multi mode'.tr,
                      middleText:
                          'Nearby HappyFeet are listed from closest to furthest as shown by RSSI'
                              .tr,
                      textConfirm: 'OK',
                      onConfirm: () {
                        Get.back();
                      },
                    );
                  },
                ),
              ],
            ),
            Flexible(
                child: ListView.builder(
                    itemCount: _bluetoothBLEService.devicesList.length,
                    itemBuilder: (BuildContext context, int index) {
                      _rssi = _bluetoothBLEService
                          .rssiMap[_bluetoothBLEService.devicesList[index]];

                      return ListTile(
                          title: Text(_bluetoothBLEService.devicesList[index].id
                              .toString()),
                          trailing: Text(_rssi.toString() + 'dB'),
                          onTap: () {
                            // connect to the selected HappyFeet
                            _bluetoothBLEService.targetDevice =
                                _bluetoothBLEService.devicesList[index];
                            _bluetoothBLEService.connectToDevice();
                            _bluetoothBLEService.bleAddress =
                                _bluetoothBLEService.devicesList[index].id
                                    .toString();
                            _bluetoothBLEService.rssi =
                                _bluetoothBLEService.rssiMap[
                                    _bluetoothBLEService.devicesList[index]]!;
                            if (kDebugMode) {
                              print(
                                  'HF: connecting to selected device $_bluetoothBLEService.devicesList[index].id.toString()');
                            }
                            Get.snackbar('Bluetooth status'.tr,
                                'connecting to Bluetooth '.tr,
                                snackPosition: SnackPosition.BOTTOM);
                            // go back to previous screen
                            Get.back(closeOverlays: true);
                          });
                    })),
          ],
        ),
      ),
    );
  } // Widget
} // class
