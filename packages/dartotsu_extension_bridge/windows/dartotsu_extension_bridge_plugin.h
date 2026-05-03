#ifndef FLUTTER_PLUGIN_DARTOTSU_EXTENSION_BRIDGE_PLUGIN_H_
#define FLUTTER_PLUGIN_DARTOTSU_EXTENSION_BRIDGE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace dartotsu_extension_bridge {

class DartotsuExtensionBridgePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  DartotsuExtensionBridgePlugin();

  virtual ~DartotsuExtensionBridgePlugin();

  // Disallow copy and assign.
  DartotsuExtensionBridgePlugin(const DartotsuExtensionBridgePlugin&) = delete;
  DartotsuExtensionBridgePlugin& operator=(const DartotsuExtensionBridgePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace dartotsu_extension_bridge

#endif  // FLUTTER_PLUGIN_DARTOTSU_EXTENSION_BRIDGE_PLUGIN_H_
