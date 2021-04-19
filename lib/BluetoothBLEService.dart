import 'dart:async';

// import 'package:bluelight_bloc/bloc_lib.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:rxdart/rxdart.dart';

import 'BluetoothConnectionStateDTO.dart';
import 'bluetoothConnectionState.dart';

class BluetoothBLEService {
  static const String DATA_SERVICE_UUID =
      "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  static const String DATA_WRITE_CHARACTERISTIC_UUID =
      "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  static const String DATA_READ_CHARACTERISTIC_UUID =
      "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  static const String PROTOCOL_READ_CHARACTERISTIC_UUID =
      "6e400004-b5a3-f393-e0a9-e50e24dcca9e";
  static const TARGET_DEVICE_NAMES = ["checkUP Device", "checkMARC"];

  FlutterBlue? flutterBlue = FlutterBlue.instance;
  StreamSubscription<ScanResult>? scanSubScription;

  BluetoothDevice? targetDevice;
  BluetoothCharacteristic? _dataReadCharacteristic;
  BluetoothCharacteristic? _dataWriteCharacteristic;

  StreamSubscription<List<int>>? _dataReadCharacteristicSubscription;

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
            .scan(scanMode: ScanMode.lowPower, timeout: Duration(seconds: 4))
            .listen(
                (scanResult) {
                  try {
                    // if (scanResult.device.name.isEmpty) return;

                    _devicesList!.add(scanResult.device);

                    String foundDevice = TARGET_DEVICE_NAMES
                        .firstWhere((e) => e == scanResult.device.name);
                    if (foundDevice.isNotEmpty) {
                      print('DEVICE found');
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
      print('DEVICE CONNECTED');
      _connectionStateSubject.add(BluetoothConnectionStateDTO(
          bluetoothConnectionState: BluetoothConnectionState.DEVICE_CONNECTED));
    } catch (err) {
      print('DEVICE ALREADY CONNECTED');
    }

    discoverServices();
  }

  disconnectFromDevice() async {
    await _dataReadCharacteristicSubscription?.cancel();
    _dataReadCharacteristicSubscription = null;
    print("_dataReadCharacteristicSubscription is cancelled");

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
        if (service.uuid.toString() == DATA_SERVICE_UUID) {
          // for Android, set MTU to send data at the maximum as possible.
          final mtu = await targetDevice!.mtu.first;
          print("mtu: ");
          print(mtu);
          await targetDevice!.requestMtu(509);

          await Future.delayed(Duration(milliseconds: 1000));

          service.characteristics.forEach((characteristic) async {
            if (characteristic.uuid.toString() ==
                DATA_READ_CHARACTERISTIC_UUID) {
              _dataReadCharacteristic = characteristic;
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

  writeData(List<int> bytes) async {
    if (_dataWriteCharacteristic == null) return;

    if (_dataWriteCharacteristic!.properties.write) {
      try {
        await _dataWriteCharacteristic!.write(bytes);
        print("sent data to device");
      } catch (err) {
        print(err);
      }
    }
  }

  readData(int round) async {
    if (_dataReadCharacteristic == null) return;

    print("readData");

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
    print("BluetoothBLE is disposed.");
  }
}
