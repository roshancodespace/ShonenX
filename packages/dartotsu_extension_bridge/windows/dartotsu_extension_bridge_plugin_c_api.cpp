#include "include/dartotsu_extension_bridge/dartotsu_extension_bridge_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "dartotsu_extension_bridge_plugin.h"

void DartotsuExtensionBridgePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  dartotsu_extension_bridge::DartotsuExtensionBridgePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
