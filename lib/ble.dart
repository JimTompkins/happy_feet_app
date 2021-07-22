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
final _devices = <DiscoveredDevice>[];

class BluetoothBLEService {

  static const String HF_SERVICE_UUID =
      "0000fff0-0000-1000-8000-00805f9b34fb";

  bool isReady = false;
  StreamSubscription? _subscription;

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
    print('HF: start BLE scan');
    Uuid hfServiceUUID = Uuid.parse(HF_SERVICE_UUID);

    // check that the BLE status is ready before proceeding
    if (isReady != true) {
      // take action
      return;
    }

    _devices.clear();
    _subscription?.cancel();
    _subscription =
    _ble.scanForDevices(withServices: [hfServiceUUID], scanMode: ScanMode.lowLatency).listen((device) {
      //code for handling results
      final knownDeviceIndex = _devices.indexWhere((d) => d.id == device.id);
      if (knownDeviceIndex >= 0) {
        _devices[knownDeviceIndex] = device;
        print('HF: found device!, $_devices[knownDeviceIndex]');
        stopScan();
      } else {
        _devices.add(device);
      }
    }, onError: (Object e) => print('HF: device scan fails with error: $e')
    );

  }

  Future<void> stopScan() async {
    print('HF: stopping BLE scan');
    await _subscription?.cancel();
    _subscription = null;
  }

  // disconnect from HappyFeet
  disconnect() {
  }
}