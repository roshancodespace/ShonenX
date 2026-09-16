# Contributing Guidelines

## General Rules & Authority

Contributions are welcome! However, to maintain stability, maintainability, and a unified vision, please adhere to the following rules:

*   **Architectural Authority:** The architecture, design system, state management patterns, and project direction remain strictly at the discretion of [@roshancodespace](https://github.com/roshancodespace).
*   **No Unsolicited Architectural Changes:** Do not submit PRs that alter the core architecture, restructure directory conventions, replace major dependencies, or rewrite foundational patterns. Unsolicited refactors will be closed.
*   **Discuss Major Changes First:** If you want to propose a significant feature or structural adjustment, open an Issue to discuss and obtain approval before starting work.
*   **What is Welcome:** Bug fixes, provider and extension bridge improvements, performance optimizations, localized UI polish matching existing design tokens, and features that adhere cleanly to the established architecture.

## Development Environment

::: tip Preferred Version
The preferred Flutter SDK version for developing ShonenX is **3.41.9**. Using newer or older versions may result in plugin incompatibilities or build failures.
:::

## Code Expectations

*   **Respect Feature Boundaries:** Do not inject cross-feature dependencies into internal engine or data files. If `player` needs data from `history`, it should observe a public provider from `history`.
*   **Theme Adherence:** ShonenX enforces a highly dynamic, Material You aesthetic driven by `flex_color_scheme`. Do not hardcode HEX or RGB values. Consume `Theme.of(context).colorScheme` exclusively.
*   **Reuse Components:** Scour [`lib/shared/`](https://github.com/roshancodespace/shonenx/tree/main/lib/shared/) before reinventing buttons, cards, or loading indicators.

## Submitting Pull Requests

1.  **Linting:** Verify changes pass the static analyzer configuration defined in [`analysis_options.yaml`](https://github.com/roshancodespace/shonenx/blob/main/analysis_options.yaml). Run `flutter analyze`.
2.  **Code Generation:** If you modified Isar schemas, ensure the generated `.g.dart` files are committed.
3.  **Cross-Platform Parity:** If you are modifying the Source Engine or the `anymex_extension_bridge`, you **must** confirm the extensions still execute correctly on both Android/iOS (FlutterJS) and Desktop (QuickJS).

## Routing

ShonenX utilizes GoRouter. 
*   Register new screens in [`app_router.dart`](https://github.com/roshancodespace/shonenx/blob/main/lib/core/router/app_router.dart). 
*   Always strictly type your route arguments. Rely on `extra` serialization configurations in `ComplexExtraCodec` for complex objects.
