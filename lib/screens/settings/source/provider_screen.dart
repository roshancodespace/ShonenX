import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';

class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final registry = ref.watch(animeSourceRegistryProvider);
    final selectedKey = ref.watch(selectedProviderKeyProvider);
    final availableKeys = registry.allProviders;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Provider',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose your preferred anime source from the options below',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: availableKeys.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final provider = availableKeys[index];
              final isSelected =
                  provider.providerName == selectedKey.selectedProviderKey;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color:
                        isSelected ? colorScheme.primary : colorScheme.outline,
                    width: 1.5,
                  ),
                ),
                color: isSelected
                    ? colorScheme.primaryContainer
                    : colorScheme.surface,
                child: InkWell(
                  onTap: () {
                    ref
                        .watch(selectedProviderKeyProvider.notifier)
                        .updateSelectedProvider(provider.providerName);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.providerName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Current Source',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: colorScheme.primary,
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
