//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <nativec/nativec_plugin.h>

void fl_register_plugins(FlPluginRegistry* registry) {
  g_autoptr(FlPluginRegistrar) nativec_registrar =
      fl_plugin_registry_get_registrar_for_plugin(registry, "NativecPlugin");
  nativec_plugin_register_with_registrar(nativec_registrar);
}
