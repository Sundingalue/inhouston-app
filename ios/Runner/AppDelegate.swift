import UIKit
import Flutter
import Firebase // ✅ Importamos Firebase

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // ✅ Inicializamos Firebase
    FirebaseApp.configure()

    let controller = window?.rootViewController as! FlutterViewController
    let shareChannel = FlutterMethodChannel(name: "com.inhouston.share", binaryMessenger: controller.binaryMessenger)
    
    shareChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "shareText" {
        if let args = call.arguments as? [String: Any],
           let text = args["text"] as? String {
          let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
          controller.present(activityVC, animated: true, completion: nil)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT", message: "No text to share", details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
