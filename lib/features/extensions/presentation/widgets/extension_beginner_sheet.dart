import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_card_group.dart';
import 'package:shonenx/shared/widgets/app_chip.dart';
import 'package:url_launcher/url_launcher.dart';
import 'manage_repos_sheet.dart';

class ExtensionBeginnerSheet extends ConsumerStatefulWidget {
  const ExtensionBeginnerSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ExtensionBeginnerSheet(),
    );
  }

  @override
  ConsumerState<ExtensionBeginnerSheet> createState() =>
      _ExtensionBeginnerSheetState();
}

class _ExtensionBeginnerSheetState
    extends ConsumerState<ExtensionBeginnerSheet> {
  String _selectedEngine = 'Aniyomi';

  final List<String> _engines = [
    'Aniyomi',
    'CloudStream',
    'Kotatsu',
    'Mangayomi',
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBottomSheet(
      title: 'Beginner Extension Guide',
      titleIcon: Icons.help_outline_rounded,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppCardGroup(
              padding: EdgeInsets.zero,
              children: [
                AppCardSurface(
                  color: cs.errorContainer.withValues(alpha: 0.6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: cs.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'BEFORE YOU START:\nYou must have the Runtime installed for extensions to work.',
                          style: textTheme.bodyMedium?.copyWith(
                            color: cs.onErrorContainer,
                            fontWeight: FontWeight.bold,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Step 1: Engine Selection
            _buildTimelineStep(
              cs: cs,
              textTheme: textTheme,
              stepNumber: '1',
              title: 'Choose your engine',
              isLast: false,
              content: AppChipGroup(
                children: _engines.map((engine) {
                  return AppChip(
                    label: engine,
                    selected: _selectedEngine == engine,
                    onSelected: (_) => setState(() => _selectedEngine = engine),
                  );
                }).toList(),
              ),
            ),

            // Step 2: Search & Open
            _buildTimelineStep(
              cs: cs,
              textTheme: textTheme,
              stepNumber: '2',
              title: 'Find the repository',
              isLast: false,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap below to search Google. Open the first result (usually a Wotaku website).',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Search "$_selectedEngine Wotaku"',
                    icon: Icons.search_rounded,
                    variant: AppButtonVariant.tonal,
                    size: AppButtonSize.medium,
                    onPressed: () {
                      final query = '$_selectedEngine Wotaku Extensions';
                      final url =
                          'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
                      launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                  ),
                ],
              ),
            ),

            // Step 3: Installation Methods
            _buildTimelineStep(
              cs: cs,
              textTheme: textTheme,
              stepNumber: '3',
              title: 'Install inside ShonenX',
              isLast: true,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Once on the site, choose the method that works for your device:',
                    style: textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCardGroup(
                    padding: EdgeInsets.zero,
                    children: [
                      AppCardSurface(
                        color: cs.secondaryContainer.withValues(alpha: 0.4),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 18,
                                  color: cs.secondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Method 1: One-Click (Android)',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Just tap the Install/Download button on the site. ShonenX will open and add it automatically.\n(Note: May be broken on Windows/Linux).',
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppCardSurface(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.content_paste_rounded,
                                  size: 18,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Method 2: Manual Link',
                                  style: textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '1. Find the repo link on the site and tap the Copy icon.\n'
                              '2. Open Manage Repos below.\n'
                              '3. Select your engine, paste the link, and save.\n'
                              '(Leaving the type as "All" is perfectly fine!).',
                              style: textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Open Manage Repos',
                              icon: Icons.settings_rounded,
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.small,
                              onPressed: () {
                                Navigator.pop(context);
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (context) =>
                                      const ManageReposSheet(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            AppButton(
              label: 'Close Guide',
              variant: AppButtonVariant.text,
              size: AppButtonSize.medium,
              isExpanded: true,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep({
    required ColorScheme cs,
    required TextTheme textTheme,
    required String stepNumber,
    required String title,
    required Widget content,
    required bool isLast,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Indicator Column
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  stepNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: cs.onPrimaryContainer,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          // Step Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
