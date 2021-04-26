import 'dart:async';

// import 'package:bluelight_bloc/bloc_lib.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';

import 'BluetoothConnectionStateDTO.dart';
import 'bluetoothConnectionState.dart';

class BluetoothBLEService {

  // Sak's constants
  static const String DATA_SERVICE_UUID =
      "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String DATA_WRITE_CHARACTERISTIC_UUID =
      "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const String DATA_READ_CHARACTERISTIC_UUID =
      "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  static const String PROTOCOL_READ_CHARACTERISTIC_UUID =
      "6e400004-b5a3-f393-e0a9-e50e24dcca9e";
//  static const TARGET_DEVICE_NAMES = ["checkUP Device", "checkMARC"];

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

  FlutterBlue? flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubScription;

  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? _dataReadCharacteristic;
  BluetoothCharacteristic? _dataWriteCharacteristic;

  BluetoothCharacteristic? _char1;
  BluetoothCharacteristic? _char2;
  BluetoothCharacteristic? _char3;
  BluetoothCharacteristic? _char4;
  BluetoothCharacteristic? _char5;
  BluetoothCharacteristic? _char6;

  StreamSubscription<List<int>>? _dataReadCharacteristicSubscription;
  StreamSubscription<List<int>>? _beatSubscription;

  String? connectionText = "";
  List<BluetoothDevice>? _devicesList;

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

  final _protocalValueSubject = BehaviorSubject<List<int>>();
  Stream<List<int>> get protocalValueStream => _protocalValueSubject.stream;

  final _dataReceivedSubject = BehaviorSubject<List<int>>();
  Stream<List<int>> get dataReceivedStream => _dataReceivedSubject.stream;

  final _beatSubject = BehaviorSubject<List<int>>();
  Stream<List<int>> get beatStream => _beatSubject.stream;

  isDeviceBluetoothOn() async {
    try {
      bool isBluetoothOn = await flutterBlue!.isOn;
      _deviceBluetoothStateSubject.add(isBluetoothOn);
      // flutterBlue.state.listen((state) {
      //   _deviceBluetoothStateSubject.add(state == BluetoothState.on);
      // });
      // .onError(() {
      //   _deviceBluetoothStateSubject.add(false);
      // });
    } catch (err) {
      //_deviceBluetoothStateSubject.add(false);
      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.FAILED,
          error: err));
    }
  }

  startConnection() {
    if (targetDevice == null) {
      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.SCANNING));

      try {
        stopScan();
        scanSubScription = flutterBlue!
            .scan(scanMode: ScanMode.lowPower, timeout: Duration(seconds: 7))
            .listen(
                (scanResult) {
                  try {
                    // if (scanResult.device.name.isEmpty) return;

                    _devicesList!.add(scanResult.device);

                    String foundDevice = TARGET_DEVICE_NAMES
                        .firstWhere((e) => e == scanResult.device.name);
                    if (foundDevice.isNotEmpty) {
                      print('HF: HappyFeet found');
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
                  print('HF: connection failed');
                  _connectionStateSubject.add(BluetoothConnectionStateDTO(
                      bluetoothConnectionState: BluetoothConnectionState.FAILED,
                      error: err));
                });
      } catch (err) {
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
    flutterBlue!.stopScan();
    scanSubScription?.cancel();
    scanSubScription = null;
    //_connectionStateSubject.add(BluetoothConnectionState.STOP_SCANNING);
  }

  connectToDevice() async {
    if (targetDevice == null) return;

    _connectionStateSubject.add(BluetoothConnectionStateDTO(
        bluetoothConnectionState: BluetoothConnectionState.DEVICE_CONNECTING));

    try {
      await targetDevice!.connect();
      print('HF: DEVICE CONNECTED');
      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.DEVICE_CONNECTED));
    } catch (err) {
      print('HF: DEVICE ALREADY CONNECTED');
    }

    discoverServices();
  }

  disconnectFromDevice() async {
    await _dataReadCharacteristicSubscription?.cancel();
    _dataReadCharacteristicSubscription = null;
    print("HF: _dataReadCharacteristicSubscription is cancelled");

    if (_dataReadCharacteristic != null) {
      _dataReadCharacteristic = null;
    }
    if (_dataWriteCharacteristic != null) _dataWriteCharacteristic = null;

    if (targetDevice == null) return;

    await targetDevice!.disconnect();

    _connectionStateSubject.add(BluetoothConnectionStateDTO(
        bluetoothConnectionState:
            BluetoothConnectionState.DEVICE_DISCONNECTED));
  }

  discoverServices() async {
    if (targetDevice == null) return;

    try {
      List<BluetoothService> services = await targetDevice!.discoverServices();
      services.forEach((service) async {
        // do something with service
        //if (service.uuid.toString() == DATA_SERVICE_UUID) {
        if (service.uuid.toString() == HF_SERVICE_UUID) {
          // for HappyFeet, set the MTU as small as possible
          final mtu = await targetDevice!.mtu.first;
          print("HF: mtu: ");
          print(mtu);
          await targetDevice!.requestMtu(23);

          await Future.delayed(Duration(milliseconds: 1000));

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
            } else if (characteristic.uuid.toString() ==
                DATA_WRITE_CHARACTERISTIC_UUID) {
              _dataWriteCharacteristic = characteristic;
            } else if (characteristic.uuid.toString() ==
                PROTOCOL_READ_CHARACTERISTIC_UUID) {
              if (characteristic.properties.read) {
                final value = await characteristic.read();
                _protocalValueSubject.add(value);
              }
              // characteristic.value.listen((value) {
              //   _protocalValueSubject.add(value);
              // });
              // await characteristic.setNotifyValue(!characteristic.isNotifying);
            }
          });
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

  // enable the beat notification by writing char6 to 0x01
  enableBeat() async {
    List<int> data = [0x01];
    if (_char6 == null) return;
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

  // disable the beat notification by writing char6 to 0x00
  disableBeat() async {
    List<int> data = [0x00];
    if (_char6 == null) return;
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

  // method to process beats received as notifications on char4
  processBeats() async {
    if (_char4 == null) return;

    print("HF: process beats");

    try {
      if (_char4!.properties.notify) {
        await _char4!.setNotifyValue(true);

        _beatSubscription?.cancel();
        _beatSubscription =
            _char4!.value.listen((data) {
              print("Beat data received: ");
              print(data);
              print("last value:");
              print(_char4!.lastValue);
              // play the next note in the groove
              if (data.length > 0) {
                // this is to fix the bluetooth still remembers the last values from previous connection.
                if (_char4!.lastValue != data) {
                  _beatSubject.add(data);
                }
              }
            });
      }
    } catch (err) {
      print("HF: error _char4: ");
      print(err);
    }
  }

  readData(int round) async {
    if (_dataReadCharacteristic == null) return;

    print("HF: readData");

    try {
      if (_dataReadCharacteristic!.properties.notify) {
        await _dataReadCharacteristic!.setNotifyValue(true);

        _dataReadCharacteristicSubscription?.cancel();
        _dataReadCharacteristicSubscription =
            _dataReadCharacteristic!.value.listen((data) {
          print("_dataReadCharacteristic.value.listen for round " +
              round.toString());
          print("_dataReadCharacteristic.value.listen got data");
          print(data);
          print("last value:");
          print(_dataReadCharacteristic!.lastValue);
          if (data.length > 0) {
            // this is to fix the bluetooth still remembers the last values from previous connection.
            if (_dataReadCharacteristic!.lastValue != data) {
              _dataReceivedSubject.add(data);
            }
          }
        });
      }
    } catch (err) {
      print("error _dataReadCharacteristic: ");
      print(err);
    }
  }

  Future<void> dispose() async {
    await disconnectFromDevice();
    _deviceBluetoothStateSubject.close();
    _connectionStateSubject.close();
    _protocalValueSubject.close();
    _dataReceivedSubject.close();
    print("HF: BluetoothBLE is disposed.");
  }
}
