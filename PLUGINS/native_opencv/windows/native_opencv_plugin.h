#ifndef FLUTTER_PLUGIN_NATIVE_OPENCV_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVE_OPENCV_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace native_opencv {

class NativeOpencvPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NativeOpencvPlugin();

  virtual ~NativeOpencvPlugin();

  // Disallow copy and assign.
  NativeOpencvPlugin(const NativeOpencvPlugin&) = delete;
  NativeOpencvPlugin& operator=(const NativeOpencvPlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace native_opencv

#endif  // FLUTTER_PLUGIN_NATIVE_OPENCV_PLUGIN_H_
