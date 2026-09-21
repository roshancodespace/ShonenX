# Contributing Guide

Contributions are welcome! However, to maintain stability, maintainability, and a unified vision, please adhere to the following rules:

- **Architectural Authority:** The architecture, design system, state management patterns, and project direction remain strictly at the discretion of [@roshancodespace](https://github.com/roshancodespace).
- **No Unsolicited Architectural Changes:** Do not submit PRs that alter the core architecture, restructure directory conventions, replace major dependencies, or rewrite foundational patterns. Unsolicited refactors will be closed.
- **Discuss Major Changes First:** If you want to propose a significant feature or structural adjustment, open an Issue to discuss and obtain approval before starting work.
- **What is Welcome:** Bug fixes, provider and extension bridge improvements, performance optimizations, localized UI polish matching existing design tokens, and features that adhere cleanly to the established architecture.
## Development Workflow

1. **Check the Issue Tracker**: Before starting work on a major feature, check if an issue exists. If not, open one to discuss the architectural approach.
2. **Branching**: Branch off `main`.
3. **Running the App**: Ensure you can build the app locally (see [Local Setup](/setup/)).
4. **Code Generation**: If you modify any Riverpod providers (`@riverpod`) or Isar models (`@collection`), run the build runner:
   ```bash
   dart run build_runner build -d
   ```
5. **Testing**: Run `flutter analyze` and `flutter test` before submitting a PR.
6. **Pull Requests**: Keep PRs focused. Do not mix unrelated architectural refactors with feature additions. 

## Architectural Boundaries

Please respect the boundaries outlined in the [Architecture Walkthrough](/setup/architecture).

- **No Cross-Feature Bleeding**: A screen in `features/library/` should not directly import a private widget from `features/discovery/`. If a widget is needed by both, move it to `lib/shared/`.
- **No Direct Engine Access**: The UI (`presentation/`) must never instantiate an API client, Engine, or Service directly. It must read it through a Riverpod provider from `providers/`.
- **Use `Rhttp`**: For network calls, always inject the `HTTP` client rather than using `dart:io` or the generic `http` package directly, to ensure caching and Cloudflare bypass logic applies.
