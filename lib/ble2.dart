import 'dart:async';
//import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';
import 'package:synchronized/synchronized.dart';

//import 'BluetoothConnectionStateDTO.dart';
//import 'bluetoothConnectionState.dart';

import 'groove.dart';

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

  static const String HF_SERVICE_UUID =
      "0000fff0-0000-1000-8000-00805f9b34fb";

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

  FlutterBlue? _ble = FlutterBlue.instance;
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
  final isConnected=false.obs;
  int heartbeatCount = 0;

  String? connectionText = "";
  List<BluetoothDevice>? _devicesList;

  BluetoothBLEService() {
    _devicesList = [];

    isDeviceBluetoothOn();
  }


  final _deviceBluetoothStateSubject = BehaviorSubject<bool>();
  Stream<bool> get deviceBluetoothStateStream =>
      _deviceBluetoothStateSubject.stream;

//final _connectionStateSubject =
//BehaviorSubject<BluetoothConnectionStateDTO>();
//Stream<BluetoothConnectionStateDTO> get connectionStateStream =>
//    _connectionStateSubject.stream;

//  final _beatSubject = BehaviorSubject<List<int>>();
//  Stream<List<int>> get beatStream => _beatSubject.stream;

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
    isConnected(false);
    _ble!.state.listen((status) {
      switch(status) {
        case BluetoothState.unknown:
          print('HF: BLE status unknown');
          isReady = false;
          break;
        case BluetoothState.unavailable:
          print('HF: BLE status unsupported');
          Get.snackbar('Bluetooth status'.tr, 'This device does not support Bluetooth'.tr, snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BluetoothState.unauthorized:
          print('HF: BLE status unauthorized');
          Get.snackbar('Bluetooth status'.tr, 'Authorize the HappyFeet app to use Bluetooth and location'.tr, snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BluetoothState.off:
          print('HF: BLE status powered off');
          Get.snackbar('Bluetooth status'.tr, 'Bluetooth is turned off.  Please turn it on'.tr, snackPosition: SnackPosition.BOTTOM);
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
    if (targetDevice == null) {
 //   _connectionStateSubject.add(BluetoothConnectionStateDTO(
 //       bluetoothConnectionState: BluetoothConnectionState.SCANNING));

      try {
        stopScan();
        scanSubscription = _ble!
            .scan(scanMode: ScanMode.lowLatency,
              withServices: [Guid(HF_SERVICE_UUID)],
              timeout: Duration(seconds: 7))
            .listen(
                (scanResult) {
              try {
                // if (scanResult.device.name.isEmpty) return;

                _devicesList!.add(scanResult.device);

                String foundDevice = TARGET_DEVICE_NAMES
                    .firstWhere((e) => e == scanResult.device.name);
                if (foundDevice.isNotEmpty) {
                  print('HF: HappyFeet found');
                  print('HF: RSSI = $scanResult.device.rssi.toString()');
                  stopScan();

//                _connectionStateSubject.add(BluetoothConnectionStateDTO(
//                    bluetoothConnectionState:
//                    BluetoothConnectionState.DEVICE_FOUND));

                  targetDevice = scanResult.device;
                  connectToDevice();
                }
              } catch (err) {
                print(err);
              }
            },
            onDone: () => _onDoneScan(),
            onError: (err) {
              print('HF: connection failed 1');
 //           _connectionStateSubject.add(BluetoothConnectionStateDTO(
 //               bluetoothConnectionState: BluetoothConnectionState.FAILED,
 //               error: err));
            });
      } catch (err) {
        print('HF: connection failed 2');
//      _connectionStateSubject.add(BluetoothConnectionStateDTO(
//          bluetoothConnectionState: BluetoothConnectionState.FAILED,
//          error: err));
      }
    } else {
      connectToDevice();
    }
  }

  _onDoneScan() {
    stopScan();
    if (targetDevice == null) {
//    _connectionStateSubject.add(BluetoothConnectionStateDTO(
//        bluetoothConnectionState: BluetoothConnectionState.FAILED));
    }
  }

  stopScan() {
    _ble!.stopScan();
    scanSubscription?.cancel();
    scanSubscription = null;
    //_connectionStateSubject.add(BluetoothConnectionState.STOP_SCANNING);
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
        switch(connectionStateUpdate) {
          case BluetoothDeviceState.connected:
            isConnected(true);
             print('HF: device connected');
            Get.snackbar('Bluetooth status'.tr, 'Connected!'.tr,
                snackPosition: SnackPosition.BOTTOM);
            heartbeatCount = 0;
            discoverServices();
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
            if (characteristic.uuid.toString() ==
                CHAR1_CHARACTERISTIC_UUID) {
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
      }
    );

      // disable the sending of notifications on char4 by
      // writing to char6.  This is in case the value of char6
      // is remembered from the last connection, or it is
      // currently enabled.
      // disableBeat();

//    await Future.delayed(Duration(milliseconds: 1000));

      //print("HF: enable processing notifications on char4...");
      // they should not actually be sent yet because of the call
      // to disableBeat above.
      //processBeats();


    } catch (e) {
      print(e.toString());
    }
  }


  disconnectFromDevice() async {
    isConnected(false);
    setDisconnectFlag();

    await _beatSubscription?.cancel();
    _beatSubscription = null;
    print("HF: _beatSubscription is cancelled");

    if (_char1 != null) _char1 = null;
    if (_char2 != null) _char2 = null;
    if (_char3 != null) _char3 = null;
    if (_char4 != null) _char4 = null;
    if (_char5 != null) _char5 = null;
    if (_char6 != null) _char6 = null;

    if (targetDevice == null) return;

    await targetDevice!.disconnect();
    Get.snackbar('Bluetooth status'.tr, 'Disconnecting'.tr, snackPosition: SnackPosition.BOTTOM);

//  _connectionStateSubject.add(BluetoothConnectionStateDTO(
//      bluetoothConnectionState:
//      BluetoothConnectionState.DEVICE_DISCONNECTED));
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
    stopProcessingBeats();
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


  Future<void> writeThreshold(int threshold) async {
    if (_char3 == null) {
      print('HF: writeThreshold: error: null characteristic');
      // error
    } else {
      int value = threshold & 0xFF;
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
    await _lock.synchronized(() async {
      await _char4!.setNotifyValue(true);
    },
    );
//    await _char4!.setNotifyValue(true);
    try {
      _beatSubscription = _char4!.value.listen((data) {
        var time = DateTime.now();   // get system time
        print('HF:   notify received at time: $time with data: $data');
        if (data.isNotEmpty) {
          if ((data[0] & 0xFF) == 0xFF) {
            print("HF: heartbeat notify received");
            heartbeatCount++;
            if (heartbeatCount >= 360) {
              print('HF: timeout error.  No beat received for 30min');
              Get.snackbar('Bluetooth status'.tr, 'Disconnecting since no beats detected for 30 minutes'.tr, snackPosition: SnackPosition.BOTTOM);
              disconnectFromDevice();
            }
//              Timeline.timeSync("HF: heartbeat received", () {});
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

  // read the model number
  Future<String>? readModelNumber() async {
    String result = 'Error'.tr;
    if (!isConnected()) {
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
    } else {  // connected
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

  // read char6 to see if beat sending is enabled or not
  Future<bool>? readBeatEnable() async {
    if (_char6 == null) {
      print('HF: readBeatEnable: _char6 is null');
      return(false);
    } else {
      try {
        List<int> value = await _char6!.read();
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


  Future<void> dispose() async {
    await disconnectFromDevice();
    print("HF: BluetoothBLE is disposed.");
  }

}