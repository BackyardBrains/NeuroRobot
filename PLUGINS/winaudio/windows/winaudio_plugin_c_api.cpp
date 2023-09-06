#include "include/winaudio/winaudio_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "winaudio_plugin.h"

void WinaudioPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  winaudio::WinaudioPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
