enum BluetoothSignal { good, weak, poor }

BluetoothSignal bluetoothSignalOf(int rssi) => rssi >= -70
    ? BluetoothSignal.good
    : rssi >= -85
    ? BluetoothSignal.weak
    : BluetoothSignal.poor;
