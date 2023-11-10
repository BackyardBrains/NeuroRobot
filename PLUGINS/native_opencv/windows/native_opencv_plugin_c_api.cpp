#include "include/native_opencv/native_opencv_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "native_opencv_plugin.h"

void NativeOpencvPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  native_opencv::NativeOpencvPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
