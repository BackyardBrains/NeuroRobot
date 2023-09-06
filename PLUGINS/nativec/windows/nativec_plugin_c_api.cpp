#include "include/nativec/nativec_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "nativec_plugin.h"

void NativecPluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  nativec::NativecPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
