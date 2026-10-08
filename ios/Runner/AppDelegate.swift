import CoreBluetooth
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let bluetoothStateHandler = BluetoothStateHandler()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    if let messenger = engineBridge.pluginRegistry
      .registrar(forPlugin: "BluetoothStateHandler")?.messenger()
    {
      FlutterEventChannel(name: BluetoothStateHandler.channel, binaryMessenger: messenger)
        .setStreamHandler(bluetoothStateHandler)
    }
  }
}

/// Streams the Bluetooth radio state ("on", "off", ...) over an event channel.
/// The central manager is only created on listen, because creating it
/// triggers the Bluetooth permission prompt when it hasn't been decided yet.
class BluetoothStateHandler: NSObject, FlutterStreamHandler, CBCentralManagerDelegate {
  static let channel = "bluetoothState/events"

  private var manager: CBCentralManager?
  private var eventSink: FlutterEventSink?

  func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
    -> FlutterError?
  {
    eventSink = events
    // The delegate is called with the current state right after creation.
    manager = CBCentralManager(
      delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: false])
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    manager?.delegate = nil
    manager = nil
    eventSink = nil
    return nil
  }

  func centralManagerDidUpdateState(_ central: CBCentralManager) {
    let value: String
    switch central.state {
    case .poweredOn: value = "on"
    case .poweredOff: value = "off"
    case .resetting: value = "turningOff"
    default: value = "unknown"
    }
    eventSink?(value)
  }
}
