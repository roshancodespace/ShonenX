# Extension Bridge

To leverage existing community ecosystems, ShonenX supports executing third-party extensions natively. This is powered by [`anymex_extension_bridge`](https://github.com/roshancodespace/shonenx/tree/main/packages/anymex_extension_bridge/).

## Architecture


1.  **Initialization:** During application startup (`AppInit`), the bridge initializes its supported execution engines. For extensions that require it (such as Sora and Mangayomi), it spawns background JavaScript environments (via QuickJS or FlutterJS).
2.  **Execution:** When a request is made, it is routed to the appropriate engine. Depending on the extension's format, the bridge evaluates the script (natively or via JS), parses the remote content, and passes the normalized payload back to the application.
3.  **Registration:** The parsed extensions are exposed to Riverpod state via [`source_registry.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/source_engine/source_registry.dart).

## Modifying the Bridge

::: danger IMPORTANT
**Do not modify the bridge code directly in this repository.** 
:::

ShonenX utilizes a custom fork of the [AnymeX Extension Runtime Bridge](https://github.com/RyanYuuki/AnymeXExtensionRuntimeBridge), originally created by RyanYuuki. 

Because the bridge is maintained as a separate project, Pull Requests submitted to the ShonenX repository that attempt to fix or modify the bridge's internal parsing logic or runtime environments will not be accepted.

## Broken Extensions

If a specific extension breaks due to a website DOM change or API update, the fix **must** occur within the external community repository for that extension (e.g., the official Mangayomi or Aniyomi extension repos), not within ShonenX or the bridge.
