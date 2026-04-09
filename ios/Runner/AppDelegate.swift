import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {

  var pendingFilePath: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let url = launchOptions?[.url] as? URL, url.pathExtension == "brain" {
      if let copiedPath = copyBrainFileToDocuments(url: url) {
        pendingFilePath = copiedPath
      }
    }

    // Send pending file after Flutter engine is ready
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
      self?.trySendPendingFile()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      self?.trySendPendingFile()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak self] in
      self?.trySendPendingFile()
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    if url.pathExtension == "brain" {
      NSLog("SpikerBot iOS: open url called with \(url)")
      if let copiedPath = copyBrainFileToDocuments(url: url) {
        pendingFilePath = copiedPath
        trySendPendingFile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
          self?.trySendPendingFile()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
          self?.trySendPendingFile()
        }
      }
      return true
    }
    return super.application(app, open: url, options: options)
  }

  /// Copy the .brain file to Documents/spikerbot/text/ while security-scoped access is active
  private func copyBrainFileToDocuments(url: URL) -> String? {
    let accessing = url.startAccessingSecurityScopedResource()
    defer {
      if accessing {
        url.stopAccessingSecurityScopedResource()
      }
    }

    let fileManager = FileManager.default
    guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
      NSLog("SpikerBot iOS: Could not find Documents directory")
      return nil
    }

    let targetDir = documentsURL.appendingPathComponent("spikerbot/text")
    do {
      try fileManager.createDirectory(at: targetDir, withIntermediateDirectories: true)
    } catch {
      NSLog("SpikerBot iOS: Could not create target directory: \(error)")
      return nil
    }

    let fileName = url.lastPathComponent
    let destURL = targetDir.appendingPathComponent(fileName)

    do {
      if fileManager.fileExists(atPath: destURL.path) {
        try fileManager.removeItem(at: destURL)
      }
      try fileManager.copyItem(at: url, to: destURL)
      NSLog("SpikerBot iOS: Copied file to \(destURL.path)")
      return destURL.path
    } catch {
      NSLog("SpikerBot iOS: Copy failed: \(error)")
      return nil
    }
  }

  private func trySendPendingFile() {
    guard let path = pendingFilePath else { return }
    NSLog("SpikerBot iOS: trySendPendingFile path=\(path)")

    guard let controller = window?.rootViewController as? FlutterViewController else {
      NSLog("SpikerBot iOS: FlutterViewController not available yet")
      return
    }

    NSLog("SpikerBot iOS: Sending openFile to Flutter")
    let channel = FlutterMethodChannel(name: "com.backyardbrains.spikerbot/fileopen",
                                        binaryMessenger: controller.binaryMessenger)
    channel.invokeMethod("openFile", arguments: path)
    pendingFilePath = nil
  }
}
