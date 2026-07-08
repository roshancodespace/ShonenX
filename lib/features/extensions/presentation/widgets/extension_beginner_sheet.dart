import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
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
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.school_rounded, color: cs.primary, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Don\'t know how to install extensions? Follow these 3 easy interactive steps below!',
                      style: textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'SELECT YOUR ENGINE',
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: cs.primary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _engines.map((e) {
                  final isSelected = _selectedEngine == e;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedEngine = e);
                        }
                      },
                      selectedColor: cs.primary,
                      labelStyle: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _buildStepCard(
              cs: cs,
              textTheme: textTheme,
              step: '1',
              title: 'Search & Open 1st Website',
              content:
                  'Tap the button below to search Google for your chosen engine. You MUST open the 1st website shown (usually wotaku).',
              action: FilledButton.icon(
                onPressed: () {
                  final query = '$_selectedEngine Wotaku Extensions';
                  final url =
                      'https://www.google.com/search?q=${Uri.encodeComponent(query)}';
                  launchUrl(
                    Uri.parse(url),
                    mode: LaunchMode.externalApplication,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                ),
                icon: const Icon(Icons.search_rounded, size: 18),
                label: Text(
                  'Search Google: "$_selectedEngine Wotaku Extensions"',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildStepCard(
              cs: cs,
              textTheme: textTheme,
              step: '2',
              title: 'Copy the Repository URL',
              content:
                  'On the 1st website you opened, find the repository index link (ending with .json or index.min.json) and tap Copy.',
            ),
            const SizedBox(height: 14),
            _buildStepCard(
              cs: cs,
              textTheme: textTheme,
              step: '3',
              title: 'Paste & Install in ShonenX',
              content:
                  'Come right back to ShonenX, open Manage Repos below, and paste your copied repository URL to unlock your extensions!',
              action: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const ManageReposSheet(),
                  );
                },
                icon: const Icon(Icons.add_link_rounded, size: 18),
                label: const Text(
                  'Open "Manage Repos" Sheet Now',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Close Guide',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard({
    required ColorScheme cs,
    required TextTheme textTheme,
    required String step,
    required String title,
    required String content,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  step,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: cs.onPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }
}
