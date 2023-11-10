//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <native_opencv/native_opencv_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) native_opencv_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NativeOpencvPlugin");
  native_opencv_plugin_register_with_registrar(native_opencv_registrar);
}
