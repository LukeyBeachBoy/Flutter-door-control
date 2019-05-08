import UIKit
import LocalAuthentication
import Flutter
import MQTTClient

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

   
    
    let controller = window?.rootViewController as! FlutterViewController
    // MQTT CHANNEL SETUP
    let mqttChannel = FlutterMethodChannel(name: "mqtt", binaryMessenger: controller)
    mqttChannel.setMethodCallHandler({(call: FlutterMethodCall, result: FlutterResult) -> Void in
        let method = call.method
        switch method {
        case "connect":
            print("Connecting")
            self.mqttConnect()
        case "open":
            print("Opening")
        case "close":
            print("Closing")
        default:
            print("Not a valid MQTT command")
        }
    })
   
    // BATTERY CHANNEL SETUP
    let batteryChannel = FlutterMethodChannel(name: "battery", binaryMessenger: controller)
    batteryChannel.setMethodCallHandler({
      (call:FlutterMethodCall, result: FlutterResult) -> Void in
      guard call.method == "getBatteryLevel" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self.receiveBatteryLevel(result: result)
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    // BATTERY FUNCTIONS
  private func receiveBatteryLevel(result: FlutterResult) {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    if device.batteryState == UIDeviceBatteryState.unknown {
      result(FlutterError(code: "Unavailable", message: "Battery info unavailable", details: nil))
    } else {
        print("Battery level is: ", device.batteryLevel * 100);
      result(Int(device.batteryLevel * 100))
    }
  }
    // MQTT FUNCTIONS
    private func mqttConnect() {
        let MQTT_HOST = "m24.cloudmqtt.com"
        let MQTT_PORT: UInt32 = 12432
        let transport = MQTTCFSocketTransport()
        let session = MQTTSession()
        let completion: (()->())?
        
        
        transport.host = MQTT_HOST
        transport.port = MQTT_PORT
        session?.transport = transport
        
        session?.connect() { error in
            print("Connection completed with status \(String(describing: error))")
            if error != nil {
                
            }
        }
        
    }
}
