import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
//import 'package:get/get_connect/http/src/utils/utils.dart';
import 'package:happy_feet_app/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

import 'groove.dart';
//import 'mybool.dart';

class BluetoothBLEService {
  static const String DEVINFO_SERVICE_UUID =
      "0000180a-0000-1000-8000-00805f9b34fb";

  static const String MODEL_NUMBER_CHARACTERISTIC_UUID =
      "00002a24-0000-1000-8000-00805f9b34fb";
  static const String SERIAL_NUMBER_CHARACTERISTIC_UUID =
      "00002a25-0000-1000-8000-00805f9b34fb";
  static const String FIRMWARE_REV_CHARACTERISTIC_UUID =
      "00002a26-0000-1000-8000-00805f9b34fb";
  static const String HARDWARE_REV_CHARACTERISTIC_UUID =
      "00002a27-0000-1000-8000-00805f9b34fb";
  static const String SOFTWARE_REV_CHARACTERISTIC_UUID =
      "00002a28-0000-1000-8000-00805f9b34fb";
  static const String MANUFACTURER_NAME_CHARACTERISTIC_UUID =
      "00002a29-0000-1000-8000-00805f9b34fb";

  static const String HF_SERVICE_UUID = "0000fff0-0000-1000-8000-00805f9b34fb";

  // 6 characteristics: 1, 2, 5 and 6 are readable,
  // 3 and 6 are writable, and 4 notifies
  static const String CHAR1_CHARACTERISTIC_UUID =
      "0000fff1-0000-1000-8000-00805f9b34fb";
  static const String CHAR2_CHARACTERISTIC_UUID =
      "0000fff2-0000-1000-8000-00805f9b34fb";
  static const String CHAR3_CHARACTERISTIC_UUID =
      "0000fff3-0000-1000-8000-00805f9b34fb";
  static const String CHAR4_CHARACTERISTIC_UUID =
      "0000fff4-0000-1000-8000-00805f9b34fb";
  static const String CHAR5_CHARACTERISTIC_UUID =
      "0000fff5-0000-1000-8000-00805f9b34fb";
  static const String CHAR6_CHARACTERISTIC_UUID =
      "0000fff6-0000-1000-8000-00805f9b34fb";

  static const TARGET_DEVICE_NAMES = ["HappyFeet"];

  FlutterBluePlus? _ble = FlutterBluePlus.instance;
//  _ble.setLogLevel(LogLevel.debug);
  StreamSubscription<ScanResult>? scanSubscription;

  BluetoothDevice? targetDevice;

  BluetoothCharacteristic? _char1;
  BluetoothCharacteristic? _char2;
  BluetoothCharacteristic? _char3;
  BluetoothCharacteristic? _char4;
  BluetoothCharacteristic? _char5;
  BluetoothCharacteristic? _char6;

  BluetoothCharacteristic? _modelNumber;
//  BluetoothCharacteristic? _serialNumber;
  BluetoothCharacteristic? _firmwareRev;
//  BluetoothCharacteristic? _hardwareRev;
//  BluetoothCharacteristic? _softwareRev;
//  BluetoothCharacteristic? _manufacturerName;

  StreamSubscription<List<int>>? _beatSubscription;

  bool isReady = false;
  bool serviceDiscoveryComplete = true;
  final isConnected = false.obs;
  int heartbeatCount = 0;
  int rssi = -1;
  int batteryVoltage = 0;
  String bleAddress = 'unknown';
  bool scanComplete = false;
  RxBool _playState = Get.find();

  String? connectionText = "";
  List<BluetoothDevice> devicesList = [];
  var rssiMap = <BluetoothDevice, int>{};

  BluetoothBLEService() {
    devicesList = [];

    isDeviceBluetoothOn();
  }

  final _deviceBluetoothStateSubject = BehaviorSubject<bool>();
  Stream<bool> get deviceBluetoothStateStream =>
      _deviceBluetoothStateSubject.stream;

  isDeviceBluetoothOn() async {
    try {
      bool isBluetoothOn = await _ble!.isOn;
      _deviceBluetoothStateSubject.add(isBluetoothOn);
      // flutterBlue.state.listen((state) {
      //   _deviceBluetoothStateSubject.add(state == BluetoothState.on);
      // });
      // .onError(() {
      //   _deviceBluetoothStateSubject.add(false);
      // });
    } catch (err) {
      //_deviceBluetoothStateSubject.add(false);
//    _connectionStateSubject.add(BluetoothConnectionStateDTO(
//        bluetoothConnectionState: BluetoothConnectionState.FAILED,
//        error: err));
    }
  }

  // values of BluetoothState:
  //unknown,  unavailable,  unauthorized,  turningOn,  on,  turningOff,  off

  init() {
    isReady = false;
    scanComplete = false;
    isConnected(false);
    _ble!.state.listen((status) {
      switch (status) {
        case BluetoothState.unknown:
          print('HF: BLE status unknown');
          isReady = false;
          break;
        case BluetoothState.unavailable:
          print('HF: BLE status unsupported');
          Get.snackbar('Bluetooth status'.tr,
              'This device does not support Bluetooth'.tr,
              snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BluetoothState.unauthorized:
          print('HF: BLE status unauthorized');
          Get.snackbar('Bluetooth status'.tr,
              'Authorize the HappyFeet app to use Bluetooth and location'.tr,
              snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BluetoothState.off:
          print('HF: BLE status powered off');
          Get.snackbar('Bluetooth status'.tr,
              'Bluetooth is turned off.  Please turn it on'.tr,
              snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BluetoothState.on:
          print('HF: BLE status ready');
          isReady = true;
          break;
        default:
          print('HF: BLE status unknown');
          break;
      }
    });
  }

  startConnection() {
    devicesList.clear(); // clear the list of found devices
    rssiMap.clear();
    scanComplete = false;
    if (targetDevice == null) {
      try {
        stopScan();
        scanSubscription = _ble!
            .scan(
                scanMode: ScanMode.lowLatency,
                withServices: [Guid(HF_SERVICE_UUID)],
                timeout: Duration(seconds: 7))
            .listen(
                (scanResult) {
                  try {
                    // if (scanResult.device.name.isEmpty) return;

                    //_devicesList!.add(scanResult.device);

                    String foundDevice = TARGET_DEVICE_NAMES
                        .firstWhere((e) => e == scanResult.device.name);
                    if (foundDevice.isNotEmpty) {
                      print('HF: HappyFeet found');
                      // if not in multi mode, stop further scanning and
                      // connect to the first device found...
                      if (!multiMode) {
                        stopScan();
                        rssi = scanResult.rssi;
                        print('HF: found device with RSSI $rssi');
                        bleAddress = scanResult.device.id.toString();
                        print('HF: rssi = $rssi, address = $bleAddress');
                        targetDevice = scanResult.device;
                        connectToDevice();
                        print(
                            'HF: connecting to device immediately since not in multi mode');
                      }
                      // if in multi mode, add the device to a list of devices
                      // and keep scanning
                      else {
                        if (!devicesList.contains(scanResult.device)) {
                          print(
                              'HF: adding device to list since in multi mode');
                          devicesList.add(scanResult.device);
                          bleAddress = scanResult.device.id.toString();
                          rssi = scanResult.rssi;
                          //print('HF: found device $bleAddress with RSSI $rssi');
                          //print('HF: scan result = $scanResult');
                          rssiMap[scanResult.device] = rssi;
                        } else {
                          print('HF: already on devicesList');
                        }
                      }
                    }
                  } catch (err) {
                    print(err);
                  }
                },
                onDone: () => _onDoneScan(),
                onError: (err) {
                  print('HF: connection failed 1');
                });
      } catch (err) {
        print('HF: connection failed 2');
      }
    } else {
      connectToDevice();
    }
  }

  _onDoneScan() {
    stopScan();
    if (!multiMode) {
      if (targetDevice == null) {
        Get.snackbar(
            'Bluetooth status'.tr,
            'Can\'t find Happy Feet!  Do you own one?  Is it nearby?  Is it charged?'
                .tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    } else
    // if in multi mode, check the list of devices found.  If none, open a snackbar.
    // if one, connect to it.  If more than one, open a list for the user to select
    // the desired device
    {
      if (devicesList.length == 0) {
        Get.snackbar(
            'Bluetooth status'.tr,
            'Can\'t find Happy Feet!  Do you own one?  Is it nearby?  Is it charged?'
                .tr,
            snackPosition: SnackPosition.BOTTOM);
      } else if (devicesList.length == 1) {
        print('HF: found 1 HappyFeet, connecting now...');
        bleAddress = devicesList[0].id.toString();
        rssi = rssiMap[devicesList[0]]!;
        print('HF: rssi = $rssi, address = $bleAddress');
        targetDevice = devicesList[0];
        connectToDevice();
      } else if (devicesList.length > 1) {
        var n = devicesList.length;
        print('HF: found $n HappyFeet in multi mode');
        // sort the devices list by RSSI in descending order i.e. closest first
        devicesList.sort((b, a) => rssiMap[a]!.compareTo(rssiMap[b]!));
        Get.to(() => multiConnectPage);
      }
    }
    scanComplete = true;
  }

  // wait for the scan to complete by checking the scanComplete flag every 500ms
  isScanComplete() async {
    var scanStartTime = DateTime.now(); // get system time at start of scan
    print('HF: starting scan');
    while (true) {
      if (scanComplete) {
        break;
      }
      var now = DateTime.now(); // get current system time
      Duration scanDuration =
          now.difference(scanStartTime); // calculate duration of scan so far
      var t = scanDuration.inSeconds.toDouble();
      print('HF: scan time = $t');
      if (t > 10.0) {
        print('HF: scan timed out');
        break;
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
    return;
  }

  stopScan() {
    _ble!.stopScan();
    scanSubscription?.cancel();
    scanSubscription = null;
  }

  bool isBleConnected() {
    if (targetDevice == null) {
      return false;
    } else {
      return isConnected.value;
    }
  }

  connectToDevice() async {
    if (targetDevice == null) {
      print("HF: connectToDevice: targetDevice is null");
      return;
    } else {
      print("HF: connectToDevice");
    }

//  _connectionStateSubject.add(BluetoothConnectionStateDTO(
//      bluetoothConnectionState: BluetoothConnectionState.DEVICE_CONNECTING));

    try {
      await targetDevice!.connect();
      targetDevice!.state.listen((connectionStateUpdate) async {
        switch (connectionStateUpdate) {
          case BluetoothDeviceState.connected:
            if (!isBleConnected()) {
              isConnected(true);
              print('HF: device connected');
              Get.snackbar('Bluetooth status'.tr, 'Connected!'.tr,
                  snackPosition: SnackPosition.BOTTOM);
              heartbeatCount = 0;
              discoverServices();
            }
            break;
          case BluetoothDeviceState.disconnected:
            isConnected(false);
            break;
          case BluetoothDeviceState.connecting:
            break;
          case BluetoothDeviceState.disconnecting:
            break;
        }
      });
    } catch (err) {
      print('HF: connection error $err');
    }
  }

  discoverServices() async {
    if (targetDevice == null) {
      print("HF: discoverServices: targetDevice is null");
      return;
    } else {
      print("HF: discoverServices: targetDevice is not null");
    }

    try {
      List<BluetoothService> services = await targetDevice!.discoverServices();
      services.forEach((service) async {
        // get characteristics of the DeviceInfo service
        if (service.uuid.toString() == DEVINFO_SERVICE_UUID) {
          service.characteristics.forEach((characteristic) async {
            if (characteristic.uuid.toString() ==
                MODEL_NUMBER_CHARACTERISTIC_UUID) {
              _modelNumber = characteristic;
            }
            if (characteristic.uuid.toString() ==
                FIRMWARE_REV_CHARACTERISTIC_UUID) {
              _firmwareRev = characteristic;
            }
          });
        }
        // get characteristics of the HappyFeet service
        if (service.uuid.toString() == HF_SERVICE_UUID) {
          // for HappyFeet, set the MTU as small as possible
          final mtu = await targetDevice!.mtu.first;
          print("HF: MTU size: $mtu");
          //await targetDevice!.requestMtu(23);

          await Future.delayed(Duration(milliseconds: 1000));

          print("HF: processing characteristics...");
          service.characteristics.forEach((characteristic) async {
            if (characteristic.uuid.toString() == CHAR1_CHARACTERISTIC_UUID) {
              _char1 = characteristic;
            } else if (characteristic.uuid.toString() ==
                CHAR2_CHARACTERISTIC_UUID) {
              _char2 = characteristic;
            } else if (characteristic.uuid.toString() ==
                CHAR3_CHARACTERISTIC_UUID) {
              _char3 = characteristic;
            } else if (characteristic.uuid.toString() ==
                CHAR4_CHARACTERISTIC_UUID) {
              _char4 = characteristic;
            } else if (characteristic.uuid.toString() ==
                CHAR5_CHARACTERISTIC_UUID) {
              _char5 = characteristic;
            } else if (characteristic.uuid.toString() ==
                CHAR6_CHARACTERISTIC_UUID) {
              _char6 = characteristic;
            }
          });
          print("HF: ...done.");
        }
      });
    } catch (e) {
      print(e.toString());
    }
  }

  disconnectFromDevice() async {
    if (targetDevice == null) return;
    if (_char6 != null) {
      await disableBeat();
    }

    await _beatSubscription?.cancel();
    _beatSubscription = null;
    print("HF: _beatSubscription is cancelled");

    await scanSubscription?.cancel();
    scanSubscription = null;
    print('HF: scanSubscription is cancelled');

    devicesList.clear(); // clear the list of found devices

    if (_char1 != null) _char1 = null;
    if (_char2 != null) _char2 = null;
    if (_char3 != null) _char3 = null;
    if (_char4 != null) _char4 = null;
    if (_char5 != null) _char5 = null;
    if (_char6 != null) _char6 = null;

    if (targetDevice == null) return;

    await targetDevice!.disconnect();
    Get.snackbar('Bluetooth status'.tr, 'Disconnecting'.tr,
        snackPosition: SnackPosition.BOTTOM);

    isConnected(false);

    targetDevice = null;
  }

  Future<void> setDisconnectFlag() async {
    stopProcessingBeats();
    if (_char6 == null) {
      print('HF: setDisconnectFlag: error: null characteristic');
      // error
    } else {
      print('HF: set disconnect flag');
      await _char6!.write([0x40]);
    }
  }

  // clear bit 0 of char6, the beat enable flag
  Future<void> disableBeat() async {
    //stopProcessingBeats();
    if (_char6 == null) {
      print('HF: disableBeat: error: null characteristic');
      // error
    } else {
      print('HF: disabling beats');
      await _char6!.write([0x00]);
    }
  }

  // set bit 0 of char6, the beat enable flag
  Future<void> enableBeat() async {
    print("HF: enable processing notifications on char4...");
    processBeats();
    await Future.delayed(Duration(milliseconds: 1000));
    if (_char6 == null) {
      print('HF: enableBeat: error: null characteristic');
      // error
    } else {
      print('HF: enabling beats');
      await _char6!.write([0x01]);
    }
  }

  // set bit 7 of char6, the beat enable flag
  Future<void> enableTestMode() async {
    if (_char6 == null) {
      print('HF: enableTestMode: error: null characteristic');
      // error
    } else {
      print('HF: enabling test mode: HF will send beats at a fixed rate');
      await _char6!.write([0x80]);
    }
  }

  // write the beat detection threshold.  The input value threshold comes
  // from a slider that varies between 0 and 100.
  Future<void> writeThreshold(int threshold) async {
    if (_char3 == null) {
      print('HF: writeThreshold: error: null characteristic');
      // error
    } else {
      int value = 0;
      // limit threshold to the range [0: 100]
      if (threshold > 100) {
        value = 100;
      } else if (threshold < 0) {
        value = 0;
      } else {
        value = threshold;
      }
      print('HF: writeThreshold: threshold = $threshold, value = $value');
      await _char3!.write([value]);
    }
  }

  // read the accelerometer's whoAmI register reading from char2
  // the value should be 0x44
  readWhoAmI() async {
    if (_char2 == null) return;
    if (_char2!.properties.read) {
      try {
        List<int> value = await _char2!.read();
        if (value[0] == 0x44) {
          print("HF: correct whoAmI value was read");
        } else {
          print("HF: *** incorrect whoAmI value was read");
        }
      } catch (err) {
        print("HF: error readWhoAmI");
        print(err);
      }
    }
  }

  // method to process beats received as notifications on char4
  processBeats() async {
    var _lock = Lock();
    if (_char4 == null) {
      print("HF: processBeats: _char4 is null");
      return;
    } else {
      print('HF: process beats _char4 = $_char4');
    }

    await _beatSubscription?.cancel();
    if (_char4!.isNotifying) {
      print('HF: char4 is notifying');
    } else {
      print('HF: char4 is NOT notifying');
    }
    // see flutter_blue issues #295
    await _lock.synchronized(
      () async {
        await _char4!.setNotifyValue(true);
      },
    );
    try {
      _beatSubscription = _char4!.value.listen((data) {
//        var time = DateTime.now(); // get system time
        if (data.isNotEmpty) {
          String notifyData = data[0].toRadixString(16).padLeft(4, '0');
          print('HF:   notify received with data: $notifyData');
//          var lengthOfData = data.length();
//          print('HF:   length of data = $lengthOfData');

          if ((data[0] & 0xFF) == 0xFF) {
            // bit 7
//            print("HF: heartbeat notify received");
            heartbeatCount++;
            if (heartbeatCount >= 360) {
              print('HF: timeout error.  No beat received for 30min');
              Get.snackbar('Bluetooth status'.tr,
                  'Disconnecting since no beats detected for 30 minutes'.tr,
                  snackPosition: SnackPosition.BOTTOM);
              disconnectFromDevice();
            }
          } else if ((data[0] & 0x20) == 0x20) {
            // foot-switch notify received
            if (footSwitch) {
              // only take action if the foot-switch is enabled
              //  bit 5
              print('HF: foot-switch toggle notify received');
              if (_playState.value) {
                print('HF: beats currently on, being disabled');
                // disable beats
                this.disableBeat();
                _playState.value = false;
                Get.closeAllSnackbars();
                Get.snackbar('Status'.tr, 'Beats disabled by foot'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(milliseconds: 1000));
              } else {
                // enable beats
                print('HF: beats currently off, being enabled');
                groove.reset();
                this.enableBeat();
                _playState.value = true;
                Get.closeAllSnackbars();
                Get.snackbar('Status'.tr, 'Beats enabled by foot'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(milliseconds: 1000));
              }
            }
          } else {
            print('HF: playing next note in groove, ${data[0]}');
            heartbeatCount = 0;
            // play the next note in the groove
            groove.play(data[0]);
          }
        } else {
          print('HF:  data is empty');
        }
      }, onError: (dynamic err) {
        print('HF: error on char4 subscription: $err');
      });
    } catch (err) {
      print('HF:  beat subscription error: $err');
    }
  }

  void stopProcessingBeats() async {
    await _beatSubscription?.cancel();
    _beatSubscription = null;
  }

  // read the model number
  Future<String>? readModelNumber() async {
    String result = 'Error'.tr;
    if (!isConnected()) {
      // not connected
      result = 'not connected'.tr;
      return result;
    } else {
      // connected
      if (_modelNumber == null) {
        print('HF: readModelNumber: _modelNumber is null');
        return result;
      } else {
        try {
          print('HF: reading model number...');
          List<int> value = await _modelNumber!.read();
          // convert list of character codes to string
          var valString = String.fromCharCodes(value);
          print('HF: readModelNumber: read result = $valString');
          return String.fromCharCodes(value);
        } catch (e) {
          print("HF: error readModelNumber $e");
          return ('Error'.tr);
        }
      }
    }
  }

  // read the firmware revision
  Future<String>? readFirmwareRevision() async {
    String result = 'Error'.tr;
    if (!isConnected()) {
      // not connected
      result = 'not connected'.tr;
      return result;
    } else {
      // connected
      if (_firmwareRev == null) {
        print('HF: readFirmwareRevision: _firmwareRev is null');
        return result;
      } else {
        try {
          print('HF: reading firmware revision...');
          List<int> value = await _firmwareRev!.read();
          // convert list of character codes to string
          var valString = String.fromCharCodes(value);
          print('HF: readFirmwareRev: read result = $valString');
          return String.fromCharCodes(value);
        } catch (e) {
          print("HF: error readFirmwareRev $e");
          return ('Error'.tr);
        }
      }
    }
  }

  // read the RSSI
  Future<String>? readRSSI() async {
    String result = 'Error'.tr;
    if (!isConnected()) {
      // not connected
      result = 'not connected'.tr;
      return result;
    } else {
      // connected
      result = this.rssi.toString();
      return (result);
    }
  }

  // read the BLE address (which can also be used as a serial number)
  Future<String>? readBleAddress() async {
    String result = 'Error'.tr;
    if (!isConnected()) {
      // not connected
      result = 'not connected'.tr;
      return result;
    } else {
      // connected
      result = this.bleAddress;
      return (result);
    }
  }

  // read char6 to see if beat sending is enabled or not
  Future<bool>? readBeatEnable() async {
    if (_char6 == null) {
      print('HF: readBeatEnable: _char6 is null');
      return (false);
    } else {
      try {
        List<int> value = await _char6!.read();
        if (value[0] == 0x00) {
          print("HF: beats currently disabled.  Value = $value[0]");
          return (false);
        } else {
          print("HF: beats currently enabled.  Value = $value[0]");
          return (true);
        }
      } catch (err) {
        print("HF: error readBeatEnable");
        print(err);
        return (false);
      }
    }
  }

  // read BLE characteristic 1 (char1) which contains battery voltage as a
  // percentage of 3.273V  See the function battMeasure in simple_gatt_profile.c in the
  // embedded code.  The TI CC2650 has a minimum operating voltage of 1.8V.
  // The ST LD3985 LDO (low drop out) linear regulator has a typical 20mV
  // dropout voltage at 50mA so probably less in this design, e.g. 10mV.
  // The LD3985 has a min operating voltage of 2.5V.
  // So the min battery voltage as a percentage is 2.51V/3.273V = 76%.
  Future<int>? readBatteryVoltage() async {
    if (_char1 == null) {
      print('HF: readBatteryVoltage: _char1 is null');
      return (0);
    } else {
      try {
        List<int> value = await _char1!.read();
        print("HF: battery voltage .  Value = $value[0]");
        batteryVoltage = value[0];
        // scale batteryVoltage to convert the range 76:100 to 0:100
        if (batteryVoltage > 100) {
          // limit battery voltage to 100%
          batteryVoltage = 100;
        } else if (batteryVoltage < 76) {
          batteryVoltage = 0;
        } else {
          batteryVoltage = (batteryVoltage - 76) * 100 ~/ 24;
        }
        return (batteryVoltage);
      } catch (err) {
        print("HF: error readBatteryVoltage");
        print(err);
        return (0);
      }
    }
  }

  // read char2 which Y or N based on the result of reading the
  // accelerometer's whoAmi register.
  Future<String>? readAccStatus() async {
    if (_char2 == null) {
      print('HF: readAccStatus: _char2 is null');
      return ('not connected');
    } else {
      try {
        List<int> value = await _char2!.read();
        print("HF: accelerometer status .  Value = $value[0]");
        if (value[0] == 0x59) {
          // Y = 0x59
          return ('OK');
        } else {
          return ('NOK');
        }
      } catch (err) {
        print("HF: error readAccStatus");
        print(err);
        return ('Error');
      }
    }
  }

  Future<void> dispose() async {
    await disconnectFromDevice();
    print("HF: BluetoothBLE is disposed.");
  }
}
