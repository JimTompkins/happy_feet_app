import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import 'BluetoothConnectionStateDTO.dart';
import 'package:rxdart/rxdart.dart';

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

//  var _char1;
  var _char2;
//  var _char3;
  var _char4;
//  var _char5;
  var _char6;

  var _modelNumber;
//  var _serialNumber;
//  var _firmwareRev;
//  var _hardwareRev;
//  var _softwareRev;
//  var _manufacturerName;

  StreamSubscription<List<int>>? _beatSubscription;

  final _connectionStateSubject =
  BehaviorSubject<BluetoothConnectionStateDTO>();
  Stream<BluetoothConnectionStateDTO> get connectionStateStream =>
      _connectionStateSubject.stream;

  bool isReady = false;
  bool isConnected = false;
  StreamSubscription? _subscription;
  StreamSubscription<ConnectionStateUpdate>? _connection;
  final _devices = <DiscoveredDevice>[];
  DiscoveredDevice? targetDevice;

  init() {
    isReady = false;
    isConnected = false;
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
          Get.snackbar('Bluetooth status', 'Enable location services', snackPosition: SnackPosition.BOTTOM);
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
    _devices.clear();
    _subscription?.cancel();
    _subscription =
    _ble.scanForDevices(
        withServices: [hfServiceUUID],
        scanMode: ScanMode.lowLatency,
        requireLocationServicesEnabled: true).listen((device) {
        if (device.name == 'HappyFeet') {
           print('HF: found HappyFeet, connecting to device...');
           print('HF:    $device');
           var rssi = device.rssi;
           print('HF: RSSI = $rssi');
           stopScan();
           targetDevice = device;
           Get.snackbar('Bluetooth status', 'Found Happy Feet!  Connecting...', snackPosition: SnackPosition.BOTTOM);
           connectToDevice();
           }
        },
        onError: (Object e) => print('HF: device scan fails with error: $e'),
        onDone: () => _onDoneScan(),
        );
  }

  _onDoneScan() {
    stopScan();
    if (targetDevice == null) {
 //     _connectionStateSubject.add(BluetoothConnectionStateDTO(
 //         bluetoothConnectionState: BluetoothConnectionState.FAILED));
    }
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

    try {
      _connection = _ble.connectToDevice(
        id: targetDevice!.id,
        connectionTimeout: const Duration(seconds:  30),
      ).listen((connectionState) async {
        if (connectionState.connectionState == DeviceConnectionState.connected) {
          isConnected = true;
          // for HappyFeet, set the MTU as small as possible
//          final mtu = await _ble.requestMtu(
//              deviceId: targetDevice!.id, mtu: 20);
//          print("HF: MTU size: $mtu");
//          await Future.delayed(Duration(milliseconds: 1000));
          print('HF: device connected');
          Get.snackbar('Bluetooth status', 'Connected!', snackPosition: SnackPosition.BOTTOM);
          getCharacteristics();
          print("HF: enable processing notifications on char4...");
          // they should not actually be sent yet because of the call
          // to disableBeat above.
          processBeats();

         } else {
          isConnected = false;
        }
      },
      onError: (Object e) => print('HF: connect to device fails with error: $e'),
      );
    } catch (err) {
      print('HF: device already connected');
    }
  }

  void getCharacteristics() {
    print('HF: getCharacteristics');
    if (targetDevice == null) {
      print('HF:    error: targetDevice is null!');
      return;
    }
//     _char1 = QualifiedCharacteristic(
//        serviceId: Uuid.parse(HF_SERVICE_UUID),
//        characteristicId: Uuid.parse(CHAR1_CHARACTERISTIC_UUID),
//        deviceId: targetDevice!.id);
    _char2 = QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR2_CHARACTERISTIC_UUID),
        deviceId: targetDevice!.id);
//    _char3 = QualifiedCharacteristic(
//        serviceId: Uuid.parse(HF_SERVICE_UUID),
//        characteristicId: Uuid.parse(CHAR3_CHARACTERISTIC_UUID),
//        deviceId: targetDevice!.id);
    _char4 = QualifiedCharacteristic(
        serviceId: Uuid.parse(HF_SERVICE_UUID),
        characteristicId: Uuid.parse(CHAR4_CHARACTERISTIC_UUID),
        deviceId: targetDevice!.id);
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
    if (_char6 == null) {
      print('HF: error adding characteristic 6');
    } else {
      print('HF: added characteristics: $_char6.characteristicId');
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
    this.isConnected = false;
    _subscription?.cancel();
    try {
      print('HF: disconnecting from device');
      if (_connection != null) {
        await _connection?.cancel();
        Get.snackbar('Bluetooth status', 'Disconnecting', snackPosition: SnackPosition.BOTTOM);
      }
    } on Exception catch (e, _) {
      print('HF: Error disconnecting: $e');
    }
  }

  Future<void> disableBeat() async {
    if (_char6 == null) {
      print('HF: disableBeat: error: null characteristic');
      // error
    } else {
      print('HF: disabling beats');
      await _ble.writeCharacteristicWithoutResponse(
          _char6, value: [0x00]);
    }
  }
  Future<void> enableBeat() async {
    if (_char6 == null) {
      print('HF: enableBeat: error: null characteristic');
      // error
    } else {
      print('HF: enabling beats');
      await _ble.writeCharacteristicWithoutResponse(
          _char6, value: [0x01]);
    }
  }

  Future<void> enableTestMode() async {
    if (_char6 == null) {
      print('HF: enableTestMode: error: null characteristic');
      // error
    } else {
      print('HF: enabling test mode: HF will send beats at a fixed rate');
      await _ble.writeCharacteristicWithoutResponse(
          _char6, value: [0x80]);
    }
  }


  // method to process beats received as notifications on char4
  processBeats() async {
    if (_char4 == null) {
      print("HF: processBeats: _char4 is null");
      return;
    }

    print("HF: process beats");

    _beatSubscription?.cancel();
    _beatSubscription = _ble.subscribeToCharacteristic(_char4).listen((data) {
          if (data.isNotEmpty) {
//            var time = DateTime.now();   // get system time
//            print('HF:   notify received at time: $time');
            if ((data[0] & 0xFF) == 0xFF) {
//              print("HF: heartbeat notify received");
              Timeline.timeSync("HF: heartbeat received", () {});
            } else {
              // play the next note in the groove
              //groove.play(data[0]);
              Timeline.timeSync("HF: play note", () {
                groove.play(data[0]);
              });
            }
          }
        }, onError: (dynamic e) {
              print('HF: error on chr4 subscription: $e');
        });
    }


  // read the accelerometer's whoAmI register reading from char2
  // the value should be 0x44
  Future<void> readWhoAmI() async {
    if (_char2 == null) return;
     try {
        List<int> value = await _ble.readCharacteristic(_char2!);
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

  // read the model number
  Future<String?> readModelNumber() async {
    String result = "ERROR";
    if (_modelNumber == null) return result;
      try {
        List<int> value = await _ble.readCharacteristic(_modelNumber!);
        // convert list of character codes to string
        return String.fromCharCodes(value);
      } catch (e) {
        print("HF: error readModelNumber $e");
      }
  }

  // read char6 to see if beat sending is enabled or not
  Future readBeatEnable() async {
    if (_char6 == null) {
      print('HF: readBeatEnable: _char6 is null');
      return;
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
      }
    }
  }




}
