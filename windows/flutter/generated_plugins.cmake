#
# Generated file, do not edit.
#

list(APPEND FLUTTER_PLUGIN_LIST
  app_links
  dynamic_color
  flutter_qjs
  flutter_secure_storage_windows
  flutter_timezone
  isar_community_flutter_libs
  anymex_extension_runtime_bridge
  local_auth_windows
  media_kit_libs_windows_video
  permission_handler_windows
  screen_brightness_windows
  screen_retriever_windows
  url_launcher_windows
  share_plus
  volume_controller
  media_kit_video
  webview_all_windows
  window_manager
  window_to_front
)

list(APPEND FLUTTER_FFI_PLUGIN_LIST
  flutter_discord_rpc_fork
  flutter_local_notifications_windows
  jni
  rhttp
)

set(PLUGIN_BUNDLED_LIBRARIES)

foreach(plugin ${FLUTTER_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${plugin}/windows plugins/${plugin})
  target_link_libraries(${BINARY_NAME} PRIVATE ${plugin}_plugin)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES $<TARGET_FILE:${plugin}_plugin>)
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${plugin}_bundled_libraries})
endforeach(plugin)

foreach(ffi_plugin ${FLUTTER_FFI_PLUGIN_LIST})
  add_subdirectory(flutter/ephemeral/.plugin_symlinks/${ffi_plugin}/windows plugins/${ffi_plugin})
  list(APPEND PLUGIN_BUNDLED_LIBRARIES ${${ffi_plugin}_bundled_libraries})
endforeach(ffi_plugin)
