#ifndef FLUTTER_PLUGIN_NATIVEC_PLUGIN_H_
#define FLUTTER_PLUGIN_NATIVEC_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace nativec {

class NativecPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  NativecPlugin();

  virtual ~NativecPlugin();

  // Disallow copy and assign.
  NativecPlugin(const NativecPlugin&) = delete;
  NativecPlugin& operator=(const NativecPlugin&) = delete;

 private:
  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace nativec

#endif  // FLUTTER_PLUGIN_NATIVEC_PLUGIN_H_
