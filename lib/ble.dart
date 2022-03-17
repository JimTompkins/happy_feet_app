import 'dart:async';
import 'dart:io' show Platform;
import 'package:get/get.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:happy_feet_app/main.dart';

import 'groove.dart';

class BluetoothBLEService {

  static FlutterReactiveBle _ble = FlutterReactiveBle();

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

  static const String HF_SERVICE_UUID =
      "0000fff0-0000-1000-8000-00805f9b34fb";
  // 6 characteristics:
  //    1 = read
  //    2 = read
  //    3 = write       --> threshold setting
  //    4 = notify      --> beat detection
  //    5 = read
  //    6 = write, read --> beat enable
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

  var _char1;
  var _char2;
  var _char3;
  var _char4;
//  var _char5;
  var _char6;

  var _modelNumber;
//  var _serialNumber;
  var _firmwareRev;
//  var _hardwareRev;
//  var _softwareRev;
//  var _manufacturerName;

  StreamSubscription<List<int>>? _beatSubscription;

  bool isReady = false;
  bool serviceDiscoveryComplete = true;
  final isConnected=false.obs;
  int heartbeatCount = 0;
  int rssi = -1;
  int batteryVoltage = 0;
  String bleAddress = 'unknown';
  bool scanComplete = false;
  RxBool _playState = Get.find();

  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
//  final _devices = <DiscoveredDevice>[];
  List<DiscoveredDevice> devicesList = [];
  List<String> idList = [];
  var rssiMap = <String, int>{};
  DiscoveredDevice? targetDevice;

  init() {
    isReady = false;
    isConnected(false);
    scanComplete = false;
    _ble.logLevel = LogLevel.verbose;  // change to none for release version
    _ble.statusStream.listen((status) {
      switch (status) {
        case BleStatus.unknown:
          print('HF: BLE status unknown');
          isReady = false;
          break;
        case BleStatus.unsupported:
          print('HF: BLE status unsupported');
          Get.snackbar('Bluetooth status'.tr, 'This device does not support Bluetooth'.tr, snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.unauthorized:
          print('HF: BLE status unauthorized');
          Get.snackbar('Bluetooth status'.tr, 'Authorize the HappyFeet app to use Bluetooth and location'.tr, snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.poweredOff:
          print('HF: BLE status powered off');
          Get.snackbar('Bluetooth status'.tr, 'Bluetooth is turned off.  Please turn it on'.tr, snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.locationServicesDisabled:
          print('HF: BLE status powered off');
          Get.snackbar('Bluetooth status'.tr, 'Enable location services'.tr, snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.ready:
          print('HF: BLE status ready');
          isReady = true;
          break;
        default:
          print('HF: BLE status unknown (default)');
          isReady = false;
          break;
      }
    });
  }

  // start the connection process by doing a scan of Bluetooth devices
  startConnection() {
    disconnectFromDevice();
    Uuid hfServiceUUID = Uuid.parse(HF_SERVICE_UUID);

    // check that the BLE status is ready before proceeding
    if (isReady != true) {
      // take action
      return;
    }

    print('HF: start BLE scan');
    devicesList.clear(); // clear the list of found devices
    idList.clear();
    rssiMap.clear();
    scanComplete = false;
    _subscription?.cancel();

    _subscription =
        _ble.scanForDevices(
            withServices: [hfServiceUUID],
            scanMode: ScanMode.lowLatency,
            requireLocationServicesEnabled: true).listen((device) {
          if (device.name == 'HappyFeet') {
            if (!multiMode) {
              print('HF: found HappyFeet, connecting to device...');
              print('HF:    $device');
              stopScan();
              rssi = device.rssi;
              bleAddress = device.id.toString();
              print('HF: rssi = $rssi, address = $bleAddress');
              targetDevice = device;
              Get.snackbar('Bluetooth status'.tr, 'Found Happy Feet!  Connecting...'.tr, snackPosition: SnackPosition.BOTTOM);
              connectToDevice();
              print(
                  'HF: connecting to device immediately since not in multi mode');
            }
            // if in multi mode, add the device to a list of devices
            // and keep scanning
            else {
              if (!idList.contains(device.id)) {
                print(
                    'HF: adding device to list since in multi mode');
                devicesList.add(device);
                idList.add(device.id);
                rssiMap[device.id] = device.rssi;
              } else {
                print('HF: already on devicesList');
              }
            }
          }
        },
          onError: (Object e) => print('HF: device scan fails with error: $e'),
          onDone: () => _onDoneScan(),
        );
  }

  _onDoneScan() {
    print('HF: onDoneScan');
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
        rssi = rssiMap[devicesList[0].id]!;
        print('HF: rssi = $rssi, address = $bleAddress');
        targetDevice = devicesList[0];
        connectToDevice();
      } else if (devicesList.length > 1) {
        var n = devicesList.length;
        print('HF: found $n HappyFeet in multi mode');
        // sort the devices list by RSSI in descending order i.e. closest first
        devicesList.sort((b, a) => rssiMap[a.id.toString()]!.compareTo(rssiMap[b.id.toString()]!));
        Get.to(() => multiConnectPage);
      }
    }
    scanComplete = true;
  }

  bool isBleConnected() {
    if (_connection == null) {
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

    try {
      if (Platform.isAndroid) {
        _connection = _ble.connectToAdvertisingDevice(
          id: targetDevice!.id,
// servicesWithCharacteristicsToDiscover is ignored on Android
//        servicesWithCharacteristicsToDiscover: {Uuid.parse(HF_SERVICE_UUID):
//          [Uuid.parse(CHAR2_CHARACTERISTIC_UUID),
//            Uuid.parse(CHAR4_CHARACTERISTIC_UUID),
//            Uuid.parse(CHAR6_CHARACTERISTIC_UUID)]},
          withServices: [Uuid.parse(HF_SERVICE_UUID)],
          prescanDuration: const Duration(seconds: 5),
          connectionTimeout: const Duration(seconds: 20),
        ).listen((connectionState) async {
          if (connectionState.connectionState ==
              DeviceConnectionState.connected) {
            isConnected(true);
            await Future.delayed(Duration(milliseconds: 1000));
            print('HF: device connected');
            Get.snackbar('Bluetooth status'.tr, 'Connected!'.tr,
                snackPosition: SnackPosition.BOTTOM);
            getCharacteristics();
            heartbeatCount = 0;
          } else {
            isConnected(false);
          }
        },
            onError: (Object e) {
              print('HF: connect to device fails with error: $e');
              Get.snackbar(
                  'Bluetooth status'.tr, 'Connection failed with with error $e!'.tr,
                  snackPosition: SnackPosition.BOTTOM);
            }
        );
      } else {   //iOS
        _connection = _ble.connectToDevice(
          id: targetDevice!.id,
          // if servicesWithCharacteristicsToDiscover is not used, all services/chars will be discovered
          //       servicesWithCharacteristicsToDiscover: {Uuid.parse(HF_SERVICE_UUID):
          //         [Uuid.parse(CHAR2_CHARACTERISTIC_UUID),
          //           Uuid.parse(CHAR3_CHARACTERISTIC_UUID),
          //           Uuid.parse(CHAR4_CHARACTERISTIC_UUID),
          //           Uuid.parse(CHAR6_CHARACTERISTIC_UUID)]},
          connectionTimeout: const Duration(seconds: 20),
        ).listen((connectionState) async {
          if (connectionState.connectionState ==
              DeviceConnectionState.connected) {
            isConnected(true);
            await Future.delayed(Duration(milliseconds: 1000));
            print('HF: device connected');
            Get.snackbar('Bluetooth status'.tr, 'Connected!'.tr,
                snackPosition: SnackPosition.BOTTOM);
            getCharacteristics();
          } else {
            isConnected(false);
          }
        },
            onError: (Object e) {
              print('HF: connect to device fails with error: $e');
              Get.snackbar(
                  'Bluetooth status'.tr, 'Connection failed with with error $e!'.tr,
                  snackPosition: SnackPosition.BOTTOM);
            }
        );
      }
    } catch (err) {
      print('HF: device already connected');
    }
  }

  void getCharacteristics() async {
    print('HF: getCharacteristics');
    if (targetDevice == null) {
      print('HF:    error: targetDevice is null!');
      return;
    }

//    if (Platform.isIOS) {
//      serviceDiscoveryComplete = false;
//      print('HF: start discovering services...');
//      try {
//        await _ble.discoverServices(targetDevice!.id);
//        serviceDiscoveryComplete = true;
//        getCharacteristics2();
//      } on Exception catch (e) {
//        print('HF: error during service discovery: $e');
//      }
//      print('HF: ...done discovering services');
//    } else {
//      getCharacteristics2();
//    }
    serviceDiscoveryComplete = true;
    getCharacteristics2();
  }

  getCharacteristics2() {
    if (serviceDiscoveryComplete) {
     _char1 = QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR1_CHARACTERISTIC_UUID),
        deviceId: targetDevice!.id);
      _char2 = QualifiedCharacteristic(
          serviceId: Uuid.parse(HF_SERVICE_UUID),
          characteristicId: Uuid.parse(CHAR2_CHARACTERISTIC_UUID),
          deviceId: targetDevice!.id);
      _char3 = QualifiedCharacteristic(
          serviceId: Uuid.parse(HF_SERVICE_UUID),
          characteristicId: Uuid.parse(CHAR3_CHARACTERISTIC_UUID),
          deviceId: targetDevice!.id);
// char4 is commented out here since it is found in processBeats() below
//      _char4 = QualifiedCharacteristic(
//          serviceId: Uuid.parse(HF_SERVICE_UUID),
//          characteristicId: Uuid.parse(CHAR4_CHARACTERISTIC_UUID),
//          deviceId: targetDevice!.id);
//    _char5 = QualifiedCharacteristic(
//       serviceId: Uuid.parse(HF_SERVICE_UUID),
//        characteristicId: Uuid.parse(CHAR5_CHARACTERISTIC_UUID),
//        deviceId: targetDevice!.id);
      _char6 = QualifiedCharacteristic(
          serviceId: Uuid.parse(HF_SERVICE_UUID),
          characteristicId: Uuid.parse(CHAR6_CHARACTERISTIC_UUID),
          deviceId: targetDevice!.id);
      _modelNumber = QualifiedCharacteristic(
          serviceId: Uuid.parse(DEVINFO_SERVICE_UUID),
          characteristicId: Uuid.parse(MODEL_NUMBER_CHARACTERISTIC_UUID),
          deviceId: targetDevice!.id);
      _firmwareRev = QualifiedCharacteristic(
          serviceId: Uuid.parse(DEVINFO_SERVICE_UUID),
          characteristicId: Uuid.parse(FIRMWARE_REV_CHARACTERISTIC_UUID),
          deviceId: targetDevice!.id);
      //     if (_char4 == null) {
      //       print('HF: error adding characteristic 4');
      //     } else {
      //       print('HF: added characteristics: $_char4.characteristicId');
      //     }
      if (_char6 == null) {
        print('HF: error adding characteristic 6');
      } else {
        print('HF: added characteristics: $_char6.characteristicId');
      }
    }
  }

  // wait for the scan to complete by checking the scanComplete flag every 500ms
  isScanComplete() async {
    var scanStartTime = DateTime.now(); // get system time at start of scan
    print('HF: starting scan');
    while (true) {
      if (scanComplete) {
        stopScan();
        break;
      }
      var now = DateTime.now(); // get current system time
      Duration scanDuration =
      now.difference(scanStartTime); // calculate duration of scan so far
      var t = scanDuration.inSeconds.toDouble();
      print('HF: scan time = $t');
      if (t > 7.0) {
        print('HF: scan timed out');
        stopScan();
        _onDoneScan();
        break;
      }
      await Future.delayed(Duration(milliseconds: 500));
    }
    return;
  }

  Future<void> stopScan() async {
    print('HF: stopping BLE scan');
    await _subscription?.cancel();
    _subscription = null;
  }

  // disconnect from HappyFeet
  Future<void> disconnectFromDevice() async {
    if (targetDevice == null) return;
    if (_char6 != null) {
      await disableBeat();
    }

    isConnected(false);

    devicesList.clear(); // clear the list of found devices

    try {
      print('HF: disconnecting from device');
      if (_connection != null) {
        await _connection?.cancel();
        Get.snackbar('Bluetooth status'.tr, 'Disconnecting'.tr, snackPosition: SnackPosition.BOTTOM);
      }
    } on Exception catch (e, _) {
      print('HF: Error disconnecting: $e');
    }
  }


  Future<void> setDisconnectFlag() async {
    stopProcessingBeats();
    if (_char6 == null) {
      print('HF: setDisconnectFlag: error: null characteristic');
      // error
    } else {
      print('HF: set disconnect flag');
      await _ble.writeCharacteristicWithResponse(
          _char6, value: [0x40]);
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
      await _ble.writeCharacteristicWithResponse(
          _char6, value: [0x00]);
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
      await _ble.writeCharacteristicWithResponse(
          _char6, value: [0x01]);
    }
  }

  // set bit 7 of char6, the beat enable flag
  Future<void> enableTestMode() async {
    if (_char6 == null) {
      print('HF: enableTestMode: error: null characteristic');
      // error
    } else {
      print('HF: enabling test mode: HF will send beats at a fixed rate');
      await _ble.writeCharacteristicWithResponse(
          _char6, value: [0x80]);
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
      await _ble.writeCharacteristicWithResponse(
          _char3, value: [value]);
    }
  }

  // method to process beats received as notifications on char4
  processBeats() async {

    await _beatSubscription?.cancel();
    try {
      _char4 = QualifiedCharacteristic(
          serviceId: Uuid.parse(HF_SERVICE_UUID),
          characteristicId: Uuid.parse(CHAR4_CHARACTERISTIC_UUID),
          deviceId: targetDevice!.id);
      if (_char4 == null) {
        print("HF: processBeats: _char4 is null");
        return;
      }

      print("HF: process beats");
      _beatSubscription = _ble.subscribeToCharacteristic(_char4).listen((data) {
//        var time = DateTime.now();   // get system time
        print('HF:   notify received with data: $data');
        if (data.isNotEmpty) {
          if ((data[0] & 0xFF) == 0xFF) {
            // heartbeat = 0xFF
//            print("HF: heartbeat notify received");
            heartbeatCount++;
            if (heartbeatCount >= 360) {
              print('HF: timeout error.  No beat received for 30min');
              Get.snackbar('Bluetooth status'.tr, 'Disconnecting since no beats detected for 30 minutes'.tr, snackPosition: SnackPosition.BOTTOM);
              disconnectFromDevice();
            }
//              Timeline.timeSync("HF: heartbeat received", () {});
          } else if ((data[0] & 0x20) == 0x20) {  // foot-switch notify received
            if (footSwitch) { // only take action if the foot-switch is enabled            //  bit 5
              print('HF: foot-switch toggle notify received');
              if (_playState.value) {
                print('HF: beats currently on, being disabled');
                // disable beats
                this.disableBeat();
                _playState.value = false;
                Get.snackbar('Status'.tr, 'Beats disabled by foot'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(seconds: 2));
              } else {
                // enable beats
                print('HF: beats currently off, being enabled');
                groove.reset();
                this.enableBeat();
                _playState.value = true;
                Get.snackbar('Status'.tr, 'Beats enabled by foot'.tr,
                    snackPosition: SnackPosition.BOTTOM,
                    duration: Duration(seconds: 2));
              }
            }
          } else {
            print('HF: beat received');
            heartbeatCount = 0;
            // play the next note in the groove
            groove.play(data[0]);
//              Timeline.timeSync("HF: play note", () {
//                groove.play(data[0]);
//              });
          }
        } else {print('HF:  data is empty');}
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
        List<int> value = await _ble.readCharacteristic(_char1!);
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
        List<int> value = await _ble.readCharacteristic(_char2!);
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


  // read the model number
  Future<String>? readModelNumber() async {
    String result = 'Error'.tr;
    if (!isBleConnected()) {
      // not connected
      result = 'not connected'.tr;
      return result;
    } else {  // connected
      if (_modelNumber == null) {
        print('HF: readModelNumber: _modelNumber is null');
        return result;
      } else {
        try {
          print('HF: reading model number...');
          List<int> value = await _ble.readCharacteristic(_modelNumber!);
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
    if (!isBleConnected()) {
      // not connected
      result = 'not connected'.tr;
      return result;
    } else {  // connected
      if (_firmwareRev == null) {
        print('HF: readFirmwareRevision: _firmwareRev is null');
        return result;
      } else {
        try {
          print('HF: reading firmware revision...');
          List<int> value = await _ble.readCharacteristic(_firmwareRev!);
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
      return(false);
    } else {
      try {
        List<int> value = await _ble.readCharacteristic(_char6!);
        if (value[0] == 0x00) {
          print("HF: beats currently disabled.  Value = $value[0]");
          return(false);
        } else {
          print("HF: beats currently enabled.  Value = $value[0]");
          return(true);
        }
      } catch (err) {
        print("HF: error readBeatEnable");
        print(err);
        return(false);
      }
    }
  }

}
