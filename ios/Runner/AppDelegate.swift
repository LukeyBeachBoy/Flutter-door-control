import UIKit
import LocalAuthentication
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
  ) -> Bool {

    let controller = window?.rootViewController as! FlutterViewController
    
    
    let authChannel = FlutterMethodChannel(name: "auth", binaryMessenger: controller)
    authChannel.setMethodCallHandler({(call:FlutterMethodCall, result: FlutterResult) -> Void in
        guard call.method == "getTouchID" else {
            result(FlutterMethodNotImplemented)
            return
        }
        self.authenticationWithTouchID()
    })
    let channel = FlutterMethodChannel(name: "battery", binaryMessenger: controller)
    channel.setMethodCallHandler({
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
    
    private func authenticationWithTouchID(){
        let localAuthenticationContext = LAContext();
 	localAuthenticationContext.localizedFallbackTitle = "Enter your passcode, Luke"
        var authError: NSError?
        let reasonString = "To confirm identity"
        
    if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { success, evaluateError in
                if success {
                    
                } else {
                    guard let error = evaluateError else {
                        return
                    }
                    print(self.evaluateAuthenticationPolicyMessageForLA(errorCode: error._code))
                    
                }
                
            }
        }
    }
    func evaluateAuthenticationPolicyMessageForLA(errorCode: Int) -> String {
        
        var message = ""
        
        switch errorCode {
            
        case LAError.authenticationFailed.rawValue:
            message = "The user failed to provide valid credentials"
            
        case LAError.appCancel.rawValue:
            message = "Authentication was cancelled by application"
            
        case LAError.invalidContext.rawValue:
            message = "The context is invalid"
            
        case LAError.notInteractive.rawValue:
            message = "Not interactive"
            
        case LAError.passcodeNotSet.rawValue:
            message = "Passcode is not set on the device"
            
        case LAError.systemCancel.rawValue:
            message = "Authentication was cancelled by the system"
            
        case LAError.userCancel.rawValue:
            message = "The user did cancel"
            
        case LAError.userFallback.rawValue:
            message = "The user chose to use the fallback"
            
        default:
            message = "Default message" //evaluatePolicyFailErrorMessageForLA(errorCode: errorCode)
        }
        
        return message
    }
}
