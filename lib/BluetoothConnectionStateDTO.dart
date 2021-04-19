import 'bluetoothConnectionState.dart';

class BluetoothConnectionStateDTO {
  dynamic error;
  BluetoothConnectionState? bluetoothConnectionState;


  BluetoothConnectionStateDTO(
      {this.error, this.bluetoothConnectionState}
      );

  BluetoothConnectionStateDTO.fromJson(Map<String, dynamic> parsedJson){
    error = parsedJson['error'];
    bluetoothConnectionState = parsedJson['bluetoothConnectionState'] == null? BluetoothConnectionState.OFF :
      getFruitFromString(parsedJson['bluetoothConnectionState']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['error'] = this.error;
    data['bluetoothConnectionState'] = this.bluetoothConnectionState;
    return data;
  }
}