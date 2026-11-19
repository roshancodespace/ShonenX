# Settings UI exceptions

Settings screens render ordinary section headers, navigation rows, switches,
actions, sliders, dropdowns and selection rows through the shared primitives in
`lib/features/settings/presentation/widgets/settings_ui_components.dart`. The
raw `ListTile` / `CheckboxListTile` sites below remain deliberately because they
are genuinely different interactions — a shared primitive would misrepresent
what the row does or flatten information the row needs to show.

| File | Plan-time line | Why it is a different interaction |
|------|----------------|-----------------------------------|
| `lib/features/settings/presentation/about_screen.dart` | 171 | Async loading placeholder row with a spinner; no user interaction. |
| `lib/features/settings/presentation/about_screen.dart` | 179 | Async error placeholder row; no user interaction. |
| `lib/features/settings/presentation/tracking_settings_screen.dart` | 411 | Tracker profile row with a positioned banner image, remote/login state and a custom leading stack, not a nav row. |
| `lib/features/settings/presentation/widgets/preset_gallery_sheet.dart` | 715 | Preset row with three swatches and export/delete overflow actions. |
| `lib/features/settings/presentation/widgets/language_selection_sheet.dart` | 75 | Locale selection row with custom check glyph and 12px shape. |
| `lib/features/settings/presentation/widgets/subtitle_translation_settings_sheet.dart` | 144 | Reorderable provider row with a drag handle and positional index. |
| `lib/features/settings/presentation/source_settings_sheet.dart` | 283 | `CheckboxListTile` with source-specific state. |
| `lib/features/settings/presentation/import_preview_screen.dart` | 87 | Non-interactive backup manifest info row (no `onTap`). |
| `lib/features/settings/presentation/troubleshoot_settings_screen.dart` | 244 | `CheckboxListTile` within a diagnostic action list. |
| `lib/features/settings/presentation/troubleshoot_settings_screen.dart` | 895 | Second `CheckboxListTile` within a different diagnostic action list. |
| `lib/features/settings/presentation/download_settings_screen.dart` | 494 | `CheckboxListTile` for a download option. |

The theme variant picker row is no longer an exception: it now renders through
`SettingsSelectionTile`, which supplies the swatch leading, title/subtitle,
selected state and tap callback as the shared selection affordance.

Hand-rolled section headers outside the primitives are limited to
palette-showcase and preset-gallery preview headers. Those are visual previews
of a scheme or preset rather than settings sections, so `SettingsSection` is not
the right primitive for them.
