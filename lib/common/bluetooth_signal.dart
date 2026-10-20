enum BluetoothSignal { good, weak, poor }

BluetoothSignal bluetoothSignalOf(int rssi) => rssi >= -70
    ? BluetoothSignal.good
    : rssi >= -85
    ? BluetoothSignal.weak
    : BluetoothSignal.poor;

/// How many of the four signal bars are lit for [rssi] (0-4).
int signalBarCount(int rssi) => rssi >= -60
    ? 4
    : rssi >= -70
    ? 3
    : rssi >= -80
    ? 2
    : rssi >= -90
    ? 1
    : 0;

/// Whether the signal indicator would look different for the two readings:
/// a different number of bars, or a different colour (good / weak / poor).
bool signalLooksDifferent(int a, int b) =>
    signalBarCount(a) != signalBarCount(b) ||
    bluetoothSignalOf(a) != bluetoothSignalOf(b);
