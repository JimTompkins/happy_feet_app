import 'dart:async';
import 'dart:developer';

import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:rxdart/rxdart.dart';
import 'package:get/get.dart';

import 'BluetoothConnectionStateDTO.dart';
import 'bluetoothConnectionState.dart';

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

  bool isReady = false;
  bool isConnected = false;

  static const TARGET_DEVICE_NAMES = ["HappyFeet"];

  FlutterReactiveBle _ble;
 // FlutterBlue? flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubScription;

  final targetDevice;

  final _char1;
  final _char2;
  final _char3;
  final _char4;
  final _char5;
  final _char6;

  final _modelNumber;
  final _serialNumber;
  final _firmwareRev;
  final _hardwareRev;
  final _softwareRev;
  final _manufacturerName;

  StreamSubscription<List<int>>? _beatSubscription;

  String? connectionText = "";
  List? _devicesList;

  BluetoothBLEService() {
    _devicesList = [];

    isDeviceBluetoothOn();
  }

  
  final _deviceBluetoothStateSubject = BehaviorSubject<bool>();
  Stream<bool> get deviceBluetoothStateStream =>
      _deviceBluetoothStateSubject.stream;

  final _connectionStateSubject =
      BehaviorSubject<BluetoothConnectionStateDTO>();
  Stream<BluetoothConnectionStateDTO> get connectionStateStream =>
      _connectionStateSubject.stream;

  final _beatSubject = BehaviorSubject<List<int>>();
  Stream<List<int>> get beatStream => _beatSubject.stream;

  init() {
    _ble.logLevel = LogLevel.verbose;  // change to none for release version
    _ble.statusStream.listen((status) {
      switch (_ble.status) {
        case BleStatus.unknown:
          print('HF: BLE status unknown');
          isReady = false;
          break;
        case BleStatus.unsupported:
          print('HF: BLE status unsupported');
          Get.snackbar('Bluetooth status', 'This device does not support Bluetooth', snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.unauthorized:
          print('HF: BLE status unauthorized');
          Get.snackbar('Bluetooth status', 'Authorize the HappyFeet app to use Bluetooth and location', snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.poweredOff:
          print('HF: BLE status powered off');
          Get.snackbar('Bluetooth status', 'Bluetooth is turned off.  Please turn it on', snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.locationServicesDisabled:
          print('HF: BLE status powered off');
          Get.snackbar('Bluetooth status', 'Enable location servies', snackPosition: SnackPosition.BOTTOM);
          isReady = false;
          break;
        case BleStatus.ready:
          print('HF: BLE status ready');
          isReady = true;
          break;
        default:
          print('HF: BLE status unknown');
          break;
      }
    });
  }

  isDeviceBluetoothOn() async {
     return isReady;
  }

  startConnection() {
    if (targetDevice == null) {
      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.SCANNING));

      try {
        stopScan();
        scanSubScription =
            _ble.scanForDevices(
                withServices: [Uuid.parse(HF_SERVICE_UUID)],
                scanMode: ScanMode.lowLatency,
                requireLocationServicesEnabled: true).listen((scanResult) {
//        scanSubScription = flutterBlue!
//            .scan(scanMode: ScanMode.lowPower, timeout: Duration(seconds: 7))
//            .listen(
//                (scanResult) {
                  try {
                    _devicesList!.add(scanResult.device);

                    String foundDevice = TARGET_DEVICE_NAMES
                        .firstWhere((e) => e == scanResult.device.name);
                    if (foundDevice.isNotEmpty) {
                      print('HF: HappyFeet found');
                      print('HF: RSSI = $scanResult.device.rssi.toString()');
                      stopScan();

                      _connectionStateSubject.add(BluetoothConnectionStateDTO(
                          bluetoothConnectionState:
                              BluetoothConnectionState.DEVICE_FOUND));

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
                  _connectionStateSubject.add(BluetoothConnectionStateDTO(
                      bluetoothConnectionState: BluetoothConnectionState.FAILED,
                      error: err));
                });
      } catch (err) {
        print('HF: connection failed 2');
        _connectionStateSubject.add(BluetoothConnectionStateDTO(
            bluetoothConnectionState: BluetoothConnectionState.FAILED,
            error: err));
      }
    } else {
      connectToDevice();
    }
  }

  _onDoneScan() {
    stopScan();
    if (targetDevice == null) {
      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.FAILED));
    }
  }

  stopScan() {
//    flutterBlue!.stopScan();
    scanSubScription?.cancel();
    scanSubScription = null;
  }

  bool isBleConnected() {
    if (_connection == null) {
      return false;
    } else {
      return isConnected;
    }
  }

  connectToDevice() async {
    if (targetDevice == null) {
      print("HF: connectToDevice: targetDevice is null");
      return;
    } else {
      print("HF: connectToDevice");
    }

      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.DEVICE_CONNECTING));

      try {
        await targetDevice!.connect();
        _connection = _ble.connectToDevice(
          id: targetDevice.id,
          connectionTimeout: const Duration(seconds:  2),
        ).listen((connectionState) async {
          print('HF: device connected');
          _connectionStateSubject.add(BluetoothConnectionStateDTO(
              bluetoothConnectionState: BluetoothConnectionState
                  .DEVICE_CONNECTED));
          })
        } catch (err) {
        print('HF: device already connected');
        }
      discoverServices();
  }

  disconnectFromDevice() async {

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

    _connectionStateSubject.add(BluetoothConnectionStateDTO(
        bluetoothConnectionState:
            BluetoothConnectionState.DEVICE_DISCONNECTED));
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

            await Future.delayed(Duration(milliseconds: 1000));

            // disable the sending of notifications on char4 by
            // writing to char6.  This is in case the value of char6
            // is remembered from the last connection, or it is
            // currently enabled.
            disableBeat();

            await Future.delayed(Duration(milliseconds: 1000));

            print("HF: enable processing notifications on char4...");
            // they should not actually be sent yet because of the call
            // to disableBeat above.
            processBeats();
          }
        });
      } catch (e) {
        print(e.toString());
      }
  }

  // write a characteristic on HappyFeet.  Char 3 and 6 are
  // writable and single byte
  writeChar(List<int> bytes, int charNum) async {
    switch(charNum) {
      case 3: {
        if (_char3 == null) return;
        if (_char3!.properties.write) {
          try {
            await _char3!.write(bytes);
            print("HF: wrote char 3");
          } catch (err) {
            print(err);
          }
        }
      }
      break;

      case 6: {
        if (_char6 == null) return;
        if (_char6!.properties.write) {
          try {
            await _char6!.write(bytes);
            print("HF: wrote char 6");
          } catch (err) {
            print(err);
          }
        }
      }
      break;

      default: {
        // shouldn't get here...
      }
      break;
    }
  }

  // write the beat detection threshold to char3
  writeThreshold(int threshold) async {
    List<int> data = [threshold];
    if (_char3 == null) {
      print("HF: writeThreshold: _char3 is null");
      return;
    }
    if (_char3!.properties.write) {
      try {
        await _char3!.write(data);
        print("HF: write beat detection threshold to $threshold");
      } catch (err) {
        print("HF: error writeThreshold");
        print(err);
      }
    }
  }

  // enable the beat notification by writing char6 bit 0 to 1.  The local
  // time is written in bits 7:1.
  enableBeat() async {
    var time = DateTime.now();   // get system time
    int temp = ((time.millisecond & 0x3F) << 1) | 0x01;
    List<int> data = [temp];
    if (_char6 == null) {
      print("HF: enableBeat: _char6 is null");
      return;
    }
      if (_char6!.properties.write) {
        try {
          await _char6!.write(data);
          print("HF: enabled beat detection");
        } catch (err) {
          print("HF: error enable beat");
          print(err);
        }
      }
    }

  // disable the beat notification by writing char6 bit 0 to 0.
  // The local time is also written to char6[7:1];
  disableBeat() async {
    var time = DateTime.now();   // get system time
    int temp = ((time.millisecond & 0x3F) << 1) & 0xFE;
    List<int> data = [temp];
    if (_char6 == null) {
      print("HF: disableBeat: _char6 is null");
      return;
    }
    if (_char6!.properties.write) {
      try {
        await _char6!.write(data);
        print("HF: disabled beat detection");
      } catch (err) {
        print("HF: error disableBeat");
        print(err);
      }
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

  // read the model number
  Future<String?> readModelNumber() async {
    String result = "ERROR";
    if (_modelNumber == null) return result;
    if (_modelNumber!.properties.read) {
      try {
        List<int> value = await _modelNumber!.read();
        // convert list of character codes to string
        result = String.fromCharCodes(value);
        if (result == null) {
          result = "ERROR: null result";
        }
        return result;
      } catch (err) {
        print("HF: error readModelNumber");
        print(err);
      }
    }
  }

  // read char6 to see if beat sending is enabled or not
  readBeatEnable(bool result) async {
    if (_char6 == null) return;
    if (_char6!.properties.read) {
      try {
        List<int> value = await _char6!.read();
        if (value[0] == 0x00) {
          print("HF: beats currently disabled");
          return(false);
        } else {
          print("HF: beats currently enabled");
          return(true);
        }
      } catch (err) {
        print("HF: error readBeatEnable");
        print(err);
      }
    }
  }

  // method to process beats received as notifications on char4
  processBeats() async {
    if (_char4 == null) {
      print("HF: processBeats: _char4 is null");
      return;
    }

    print("HF: process beats");

    // enable notifies on char4
      try {
        await _char4?.setNotifyValue(true);
      } catch (err) {
        print("HF: error enabling _char4 notifies");
        print(err);
      }

    _beatSubscription?.cancel();
    _beatSubscription =
        _char4!.value.listen((data) {
          if (data.isNotEmpty) {
            var time = DateTime.now();   // get system time
            print('HF:   notify received at time: $time');
            if ((data[0] & 0xFF) == 0xFF) {
              print("HF: heartbeat notify received");
              Timeline.timeSync("HF: heartbeat received", () {});
            } else {
                // play the next note in the groove
              //groove.play(data[0]);
              Timeline.timeSync("HF: play note", () {
                groove.play(data[0]);
              });
            }
          }
       });
    }

  Future<void> dispose() async {
    await disconnectFromDevice();
    _deviceBluetoothStateSubject.close();
    _connectionStateSubject.close();
    print("HF: BluetoothBLE is disposed.");
  }
}
