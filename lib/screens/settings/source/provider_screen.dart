import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final registry = ref.watch(animeSourceRegistryProvider);
    final selectedKey = ref.watch(selectedProviderKeyProvider);
    final availableKeys = registry.allProviders;

    // Fetch server status data from the API
    Future<Map<String, Map<String, dynamic>>> fetchServerStatus() async {
      final response = await http.get(Uri.parse(
          'https://raw.githubusercontent.com/Darkx-dev/ShonenX-Providers-Status/refs/heads/main/server_status.json'));
      if (response.statusCode == 200) {
        return Map<String, Map<String, dynamic>>.from(
            json.decode(response.body));
      } else {
        throw Exception('Failed to load server status');
      }
    }

    // Use a FutureBuilder to handle the asynchronous fetch
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: fetchServerStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final serverStatus = snapshot.data!;

        // Helper function to get status icon and color
        IconData getStatusIcon(String status) {
          switch (status) {
            case 'online':
              return Icons.check_circle;
            case 'issues':
              return Icons.warning_amber;
            case 'offline':
              return Icons.error;
            default:
              return Icons.help;
          }
        }

        Color getStatusColor(String status, ColorScheme colors) {
          switch (status) {
            case 'online':
              return Colors.green;
            case 'issues':
              return Colors.orange;
            case 'offline':
              return Colors.red;
            default:
              return colors.onSurface.withValues(alpha: 0.5);
          }
        }

        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Provider',
                    style: TextStyle(
                      fontSize: 24,
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
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: availableKeys.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final provider = availableKeys[index];
                  final isSelected =
                      provider.providerName == selectedKey.selectedProviderKey;

                  // Get server status info for this provider
                  final providerStatus =
                      serverStatus[provider.providerName.toLowerCase()] ??
                          {
                            'status': 'unknown',
                            'message': 'Status unknown',
                            'lastChecked': DateTime.now().toIso8601String()
                          };

                  // Convert lastChecked to DateTime
                  DateTime lastChecked =
                      DateTime.tryParse(providerStatus['lastChecked']) ??
                          DateTime.now();

                  final statusColor =
                      getStatusColor(providerStatus['status'], colorScheme);
                  final statusIcon = getStatusIcon(providerStatus['status']);

                  // Create the transform matrix correctly
                  final Matrix4 transform = Matrix4.identity();
                  if (isSelected) {
                    transform.translate(0.0, -2.0);
                  }

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    transform: transform,
                    child: Card(
                      elevation: isSelected ? 4 : 1,
                      shadowColor: isSelected
                          ? colorScheme.primary.withValues(alpha: 0.4)
                          : colorScheme.shadow.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outline.withValues(alpha: 0.3),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      color: isSelected
                          ? colorScheme.primaryContainer.withValues(alpha: 0.8)
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Text(
                                        provider.providerName
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        const SizedBox(height: 4),
                                        Text(
                                          isSelected
                                              ? 'Current Source'
                                              : 'Tap to select this source',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isSelected
                                                ? colorScheme.primary
                                                : colorScheme.onSurface
                                                    .withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.check,
                                        color: colorScheme.onPrimary,
                                        size: 18,
                                      ),
                                    ),
                                ],
                              ),

                              // Server status section
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      statusIcon,
                                      size: 16,
                                      color: statusColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        providerStatus['message'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Updated ${_formatTimeAgo(lastChecked)}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: colorScheme.onSurfaceVariant
                                            .withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply & Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // Helper function to format time ago
  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
