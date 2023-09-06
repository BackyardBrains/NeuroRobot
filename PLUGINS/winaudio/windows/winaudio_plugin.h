#ifndef FLUTTER_PLUGIN_WINAUDIO_PLUGIN_H_
#define FLUTTER_PLUGIN_WINAUDIO_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>
// #include <bass.h>

namespace winaudio {

class WinaudioPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  WinaudioPlugin();

  virtual ~WinaudioPlugin();

  // Disallow copy and assign.
  WinaudioPlugin(const WinaudioPlugin&) = delete;
  WinaudioPlugin& operator=(const WinaudioPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace winaudio

#endif  // FLUTTER_PLUGIN_WINAUDIO_PLUGIN_H_
