# Contributing to ShonenX

Contributions from the community are warmly welcomed! Many of ShonenX's features and refinements have been built collaboratively.

To keep development smooth, stable, and consistent across platforms, please review these guidelines before submitting a pull request.

---

## Contribution Guidelines

### 1. Discuss Major Changes First
If you plan to introduce a major architectural adjustment, replace a foundational dependency, or restructure core systems, please **open an issue first** to discuss your proposed approach with [@roshancodespace](https://github.com/roshancodespace). This ensures everyone is aligned before significant effort is spent.

### 2. Keep Pull Requests Focused
Keep PRs concise and scoped to a specific fix or feature. Avoid combining unrelated code formatting changes across dozens of files with targeted bug fixes, as large diffs make review and regression tracking much more difficult.

### 3. Respect Layer Boundaries
- The presentation layer (widgets) interacts with engines exclusively through Riverpod providers.
- Features should not import private implementation details from other features. Reusable logic belongs in `lib/shared/`.
- Use the shared `HTTP` client (`rhttp`) for remote calls to ensure proper TLS handshake handling and DoH resolution.

---

## Great Areas to Contribute

- 🐛 **Bug Fixes:** Resolving edge-case crashes, memory leaks, or platform-specific UI quirks.
- ⚡ **Performance:** Optimizing Isar database queries, stream buffering, or widget rebuild efficiency.
- 📺 **New Tracker Integrations:** Adding support for additional tracking services (e.g. Shikimori, Anime-Planet) via `RemoteTracker`.
- 🎨 **Desktop & Accessibility Polish:** Enhancing keyboard navigation, window management, or layout responsiveness across diverse screen sizes.

---

## Development Workflow

### 1. Fork and Branch
Create a descriptive branch off `main`:
```bash
git checkout -b feature/new-tracker-integration
```

### 2. Run Code Generation
If your changes affect `@riverpod` providers or `@collection` Isar entities:
```bash
dart run build_runner build -d
```

### 3. Run Analysis and Tests
Verify that there are no analyzer errors and all test suites pass:
```bash
flutter analyze
flutter test
```
*(On Linux, if running tests that touch native `rhttp` bindings, ensure the dynamic library path is set: `LD_LIBRARY_PATH=build/linux/x64/debug/bundle/lib flutter test`)*

### 4. Submit Your PR
Provide a clear description of:
1. The problem or enhancement being addressed.
2. The implementation approach taken.
3. Screenshots or screen captures for UI-related adjustments.
