import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'package:happy_feet_app/src/ble/ble_device_connector.dart';
import 'package:happy_feet_app/src/ble/ble_device_interactor.dart';
import 'package:happy_feet_app/src/ble/ble_scanner.dart';
import 'package:happy_feet_app/src/ble/ble_status_monitor.dart';
import 'package:happy_feet_app/src/ble/ble_logger.dart';
import 'package:provider/provider.dart';

final _bleLogger = BleLogger();
final _ble = FlutterReactiveBle();
final _scanner = BleScanner(ble: _ble, logMessage: _bleLogger.addToLog);
final _monitor = BleStatusMonitor(_ble);
final _connector = BleDeviceConnector(
  ble: _ble,
  logMessage: _bleLogger.addToLog,
);
final _serviceDiscoverer = BleDeviceInteractor(
  bleDiscoverServices: _ble.discoverServices,
  readCharacteristic: _ble.readCharacteristic,
  writeWithResponse: _ble.writeCharacteristicWithResponse,
  writeWithOutResponse: _ble.writeCharacteristicWithoutResponse,
  subscribeToCharacteristic: _ble.subscribeToCharacteristic,
  logMessage: _bleLogger.addToLog,
);

class BluetoothBLEService {

  static const String HF_SERVICE_UUID =
      "0000fff0-0000-1000-8000-00805f9b34fb";
  // 6 characteristics:
  //    1 = read
  //    2 = read
  //    3 = write
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

  bool isReady = false;
  bool isConnected = false;
  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  int connectedDeviceIndex = -1;
  final _devices = <DiscoveredDevice>[];
  final _characteristics = <QualifiedCharacteristic>[];

  init() {
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

  // scan and connect to HappyFeet
  connect() {
    disconnect();
    Uuid hfServiceUUID = Uuid.parse(HF_SERVICE_UUID);

    // check that the BLE status is ready before proceeding
    if (isReady != true) {
      // take action
      return;
    }

    print('HF: start BLE scan');
    _devices.clear();
    _subscription?.cancel();
    _subscription =
    _ble.scanForDevices(
        withServices: [hfServiceUUID],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true).listen((device) {
      //code for handling results
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
        print('HF: found device!, $_devices[knownDeviceIndex], $_devices.itemCount');
        connectedDeviceIndex = knownDeviceIndex;
        stopScan();
        if (device.name == 'HappyFeet') {
          print('HF: HappyFeet found.  Connecting to device...');
          _connection = _ble.connectToDevice(
            id: device.id,
            connectionTimeout: const Duration(seconds:  2),
          ).listen((connectionState) async {
            print('HF: connection state: $connectionState.connectionState');
            switch (connectionState.connectionState) {
              case DeviceConnectionState.connected:
                isConnected = true;
                break;
              case DeviceConnectionState.connecting:
                isConnected = false;
                break;
              case DeviceConnectionState.disconnected:
                isConnected = false;
                break;
              case DeviceConnectionState.disconnecting:
                isConnected = false;
                break;
              default:
                isConnected = false;
                break;
            }
            if (connectionState.connectionState ==
               DeviceConnectionState.connected) {
              print('HF: connected to device $device');
              await _ble.discoverServices(device.toString()).then(
                    (value) => print('HF: services discovered: $value'),
              );
              // get pointers to the device characteristics
              getCharacteristics(device);
              // set the MTU size low for low latency
              await _ble.requestMtu(deviceId: device.toString(), mtu: 20);
              await Future.delayed(Duration(seconds: 1)); // not sure if this wait is needed...
            }
          },
          onError: (Object e) => print('HF: connecting to $device.toString() resulted in error: $e')
          );
        }
      } else {
        _devices.add(device);
      }
    }, onError: (Object e) => print('HF: device scan fails with error: $e')
    );
  }

  bool isBleConnected() {
    if (_connection == null) {
       return false;
    } else {
      return isConnected;
    }
  }

  int getCharacteristics(device) {
    print('HF: getCharacteristics');
    int result = 0;
    _characteristics.add(QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR1_CHARACTERISTIC_UUID),
        deviceId: device.toString()));
    _characteristics.add(QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR2_CHARACTERISTIC_UUID),
        deviceId: device.toString()));
    _characteristics.add(QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR3_CHARACTERISTIC_UUID),
        deviceId: device.toString()));
    _characteristics.add(QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR4_CHARACTERISTIC_UUID),
        deviceId: device.toString()));
    _characteristics.add(QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR5_CHARACTERISTIC_UUID),
        deviceId: device.toString()));
    _characteristics.add(QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR6_CHARACTERISTIC_UUID),
        deviceId: device.toString()));
    if (_characteristics[5] == null) {
      result = -1;
      print('HF: error adding characteristic 5');
    } else {
      print('HF: added characteristics: $_characteristics[5].characteristicId');
    }
    return result;
  }

  Future<void> stopScan() async {
    print('HF: stopping BLE scan');
    await _subscription?.cancel();
    _subscription = null;
  }

  // disconnect from HappyFeet
  Future<void> disconnect() async {
    this.isConnected = false;
    _subscription?.cancel();
    try {
      print('HF: disconnecting from device');
      if (_connection != null) {
        await _connection?.cancel();
      }
    } on Exception catch (e, _) {
      print('HF: Error disconnecting: $e');
    }
  }

  disableBeat() {
    if (_characteristics[5] == null) {
      print('HF: disableBeat: error: null characteristic');
      // error
    } else {
      print('HF: disabling beats');
      _ble.writeCharacteristicWithoutResponse(
          _characteristics[5], value: [0x00]);
    }
  }

  enableBeat() {
    if (_characteristics[5] == null) {
      print('HF: enableBeat: error: null characteristic');
      // error
    } else {
      print('HF: enabling beats');
      _ble.writeCharacteristicWithoutResponse(
          _characteristics[5], value: [0x01]);
    }
  }
}
