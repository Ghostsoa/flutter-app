import Flutter
import UIKit
import Photos

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(
      name: "my_app/image_saver",
      binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      guard let strongSelf = self else { return }
      
      if call.method == "saveImage" {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let image = UIImage(contentsOfFile: path) else {
          result(FlutterError(code: "INVALID_PATH",
                            message: "图片路径无效",
                            details: nil))
          return
        }
        
        PHPhotoLibrary.requestAuthorization { status in
          switch status {
          case .authorized, .limited:
            PHPhotoLibrary.shared().performChanges({
              PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: { success, error in
              DispatchQueue.main.async {
                if success {
                  result(true)
                } else {
                  result(FlutterError(code: "SAVE_FAILED",
                                    message: "保存图片失败",
                                    details: error?.localizedDescription))
                }
              }
            })
          default:
            DispatchQueue.main.async {
              result(FlutterError(code: "PERMISSION_DENIED",
                                message: "没有相册访问权限",
                                details: nil))
            }
          }
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
    
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
