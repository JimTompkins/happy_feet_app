enum BluetoothConnectionState {
  OFF,
  SCANNING,
  STOP_SCANNING,
  DEVICE_FOUND,
  DEVICE_CONNECTING,
  DEVICE_CONNECTED,
  DEVICE_DISCONNECTED,
  DATA_WAITING,
  DATA_RECEIVED,
  FAILED,
  ERROR
}

BluetoothConnectionState getFruitFromString(String enumString) {
  enumString = 'BluetoothConnectionState.$enumString';
  return BluetoothConnectionState.values.firstWhere((f)=> f.toString() == enumString, orElse: () => BluetoothConnectionState.OFF);
}