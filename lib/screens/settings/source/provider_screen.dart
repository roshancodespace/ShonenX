import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/providers/selected_provider.dart';
import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Create a provider to store the temporary selection
final temporarySelectionProvider = StateProvider<String?>((ref) => null);

// Create a provider to cache the server status data
final serverStatusProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  try {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/Darkx-dev/ShonenX-Providers-Status/refs/heads/main/server_status.json'));
    if (response.statusCode == 200) {
      return Map<String, Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load server status');
    }
  } catch (e) {
    // Return empty map with unknown status if fetch fails
    return {};
  }
});

class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final registry = ref.watch(animeSourceRegistryProvider);
    final selectedKey = ref.watch(selectedProviderKeyProvider);
    final availableKeys = registry.allProviders;

    // Get the current temporary selection or use the actual selection
    final temporarySelection = ref.watch(temporarySelectionProvider) ??
        selectedKey.selectedProviderKey;

    // Watch the server status (only fetched once)
    final serverStatusAsync = ref.watch(serverStatusProvider);

    return Scaffold(
      body: SafeArea(
        child: serverStatusAsync.when(
          loading: () => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Checking provider status...',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          error: (error, stackTrace) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_off,
                  size: 48,
                  color: colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Could not fetch provider status',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    ref.refresh(serverStatusProvider);
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (serverStatus) {
            return CustomScrollView(
              slivers: [
                // App bar with animated background
                SliverAppBar(
                  expandedHeight: 120,
                  pinned: true,
                  backgroundColor: colorScheme.surface,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withValues(alpha: 0.8),
                            colorScheme.primaryContainer,
                          ],
                        ),
                      ),
                    ),
                    title: const Text(
                      'Anime Sources',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    centerTitle: true,
                  ),
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),

                // Header section
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
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
                        const SizedBox(height: 16),
                        _buildStatusLegend(colorScheme),
                      ],
                    ),
                  ),
                ),

                // Provider list
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final provider = availableKeys[index];

                        // Check against temporary selection instead of actual selection
                        final isSelected =
                            provider.providerName == temporarySelection;

                        // Get server status info for this provider
                        final providerStatus =
                            serverStatus[provider.providerName.toLowerCase()] ??
                                {
                                  'status': 'unknown',
                                  'message': 'Status unknown',
                                  'lastChecked':
                                      DateTime.now().toIso8601String()
                                };

                        // Convert lastChecked to DateTime
                        DateTime lastChecked =
                            DateTime.tryParse(providerStatus['lastChecked']) ??
                                DateTime.now();

                        final statusColor = _getStatusColor(
                            providerStatus['status'], colorScheme);
                        final statusIcon =
                            _getStatusIcon(providerStatus['status']);

                        // Create the transform matrix correctly
                        final Matrix4 transform = Matrix4.identity();
                        if (isSelected) {
                          transform.translate(0.0, -2.0);
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildProviderCard(
                            context,
                            ref,
                            provider,
                            isSelected,
                            providerStatus,
                            statusColor,
                            statusIcon,
                            lastChecked,
                            colorScheme,
                            transform,
                          ),
                        );
                      },
                      childCount: availableKeys.length,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: serverStatusAsync.when(
          loading: () => ElevatedButton(
            onPressed: null, // Disabled while loading
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: 0.6),
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          error: (_, __) => ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          data: (_) => ElevatedButton(
            onPressed: () {
              // Apply the change only when the button is pressed
              final temporarySelect = ref.read(temporarySelectionProvider);
              if (temporarySelect != null) {
                ref
                    .read(selectedProviderKeyProvider.notifier)
                    .updateSelectedProvider(temporarySelect);
              }
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
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
    );
  }

  // Helper method to build the status legend
  Widget _buildStatusLegend(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
              Icons.check_circle, 'Online', Colors.green, colorScheme),
          _buildLegendItem(
              Icons.warning_amber, 'Issues', Colors.orange, colorScheme),
          _buildLegendItem(Icons.error, 'Offline', Colors.red, colorScheme),
          _buildLegendItem(Icons.help, 'Unknown',
              colorScheme.onSurface.withValues(alpha: 0.5), colorScheme),
        ],
      ),
    );
  }

  // Helper method to build a legend item
  Widget _buildLegendItem(
      IconData icon, String text, Color color, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  // Helper method to build a provider card
  Widget _buildProviderCard(
    BuildContext context,
    WidgetRef ref,
    dynamic provider,
    bool isSelected,
    Map<String, dynamic> providerStatus,
    Color statusColor,
    IconData statusIcon,
    DateTime lastChecked,
    ColorScheme colorScheme,
    Matrix4 transform,
  ) {
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
            // Only update the temporary selection, not the actual provider
            ref.read(temporarySelectionProvider.notifier).state =
                provider.providerName;

            // Add haptic feedback
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Avatar/logo container with gradient background
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [
                                  colorScheme.primary,
                                  colorScheme.primary.withValues(alpha: 0.8),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: isSelected
                            ? null
                            : colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          provider.providerName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    provider.providerName ==
                                            ref
                                                .watch(
                                                    selectedProviderKeyProvider)
                                                .selectedProviderKey
                                        ? 'CURRENT'
                                        : 'SELECTED',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSelected
                                ? provider.providerName ==
                                        ref
                                            .watch(selectedProviderKeyProvider)
                                            .selectedProviderKey
                                    ? 'Your current anime source'
                                    : 'Click Apply & Save to confirm'
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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          statusIcon,
                          size: 14,
                          color: statusColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          providerStatus['message'],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 10,
                              color: colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatTimeAgo(lastChecked),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper function to get status icon
  IconData _getStatusIcon(String status) {
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

  // Helper function to get status color
  Color _getStatusColor(String status, ColorScheme colors) {
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
