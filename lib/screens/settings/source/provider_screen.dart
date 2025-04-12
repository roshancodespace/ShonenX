import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:iconsax/iconsax.dart';
import 'dart:async';
import 'dart:convert';

import 'package:shonenx/api/registery/anime_source_registery_provider.dart';
import 'package:shonenx/providers/selected_provider.dart';

// State classes for better type safety
class ApiStatus {
  final bool isChecking;
  final bool isValid;

  const ApiStatus({this.isChecking = false, this.isValid = false});

  ApiStatus copyWith({bool? isChecking, bool? isValid}) {
    return ApiStatus(
      isChecking: isChecking ?? this.isChecking,
      isValid: isValid ?? this.isValid,
    );
  }
}

class ServerStatus {
  final String status;
  final String message;
  final DateTime lastChecked;

  const ServerStatus({
    this.status = 'unknown',
    this.message = 'Status unknown',
    required this.lastChecked,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      status: json['status'] ?? 'unknown',
      message: json['message'] ?? 'Status unknown',
      lastChecked: DateTime.parse(
          json['lastChecked'] ?? DateTime.now().toIso8601String()),
    );
  }

  static ServerStatus unknown() {
    return ServerStatus(
      lastChecked: DateTime.now(),
    );
  }
}

// Providers
final temporarySelectionProvider = StateProvider<String?>((ref) => null);

final serverStatusProvider =
    FutureProvider<Map<String, ServerStatus>>((ref) async {
  try {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/Darkx-dev/ShonenX-Providers-Status/refs/heads/main/server_status.json'));

    if (response.statusCode == 200) {
      final data = Map<String, dynamic>.from(json.decode(response.body));
      return data.map((key, value) => MapEntry(
          key, ServerStatus.fromJson(Map<String, dynamic>.from(value))));
    }
    throw Exception('Failed to load server status');
  } catch (e) {
    return {};
  }
});

final apiStatusProvider = StateProvider<ApiStatus>((ref) => const ApiStatus());

final customApiUrlProvider = StateProvider<String>((ref) {
  final selectedKey = ref.watch(selectedProviderKeyProvider);
  return selectedKey.customApiUrl ?? '';
});

// Controller for API URL input with proper debouncing
class ApiUrlController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  Timer? _debounceTimer;
  final Duration debounceDuration;

  ApiUrlController({this.debounceDuration = const Duration(milliseconds: 500)});

  void initializeUrl(String? url) {
    if (url != null && url.isNotEmpty && textController.text != url) {
      textController.text = url;
    }
  }

  void debounceCheck(WidgetRef ref, String value) {
    _debounceTimer?.cancel();
    ref.read(apiStatusProvider.notifier).state =
        ref.read(apiStatusProvider).copyWith(isChecking: true, isValid: false);

    _debounceTimer = Timer(debounceDuration, () async {
      if (value.isEmpty) {
        ref.read(apiStatusProvider.notifier).state = ref
            .read(apiStatusProvider)
            .copyWith(isChecking: false, isValid: false);
        return;
      }

      final cleanUrl = _cleanUrl(value);
      final isValid = await _checkApi(cleanUrl);
      ref.read(apiStatusProvider.notifier).state = ref
          .read(apiStatusProvider)
          .copyWith(isChecking: false, isValid: isValid);
    });
  }

  String get url => textController.text;

  static String _cleanUrl(String url) {
    url = url.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasAuthority
        ? '${uri.scheme}://${uri.host}${uri.port != 80 && uri.port != 443 ? ':${uri.port}' : ''}'
        : url;
  }

  static Future<bool> _checkApi(String url) async {
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    textController.dispose();
    super.dispose();
  }
}

class ProviderSettingsScreen extends ConsumerStatefulWidget {
  const ProviderSettingsScreen({super.key});

  @override
  ConsumerState<ProviderSettingsScreen> createState() =>
      _ProviderSettingsScreenState();
}

class _ProviderSettingsScreenState
    extends ConsumerState<ProviderSettingsScreen> {
  late final ApiUrlController _apiController;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _apiController = ApiUrlController();

    // Initialize with current selection
    final selectedKey = ref.read(selectedProviderKeyProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(temporarySelectionProvider.notifier).state =
          selectedKey.selectedProviderKey;
    });
    // Initialize controller with current API URL
    _apiController.initializeUrl(selectedKey.customApiUrl);

    // Listen for changes to detect if user made modifications
    _apiController.textController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final currentSelection = ref.read(temporarySelectionProvider);
    final originalSelection =
        ref.read(selectedProviderKeyProvider).selectedProviderKey;
    final originalUrl = ref.read(selectedProviderKeyProvider).customApiUrl;
    final currentUrl = _apiController.url;

    final hasChanges =
        currentSelection != originalSelection || currentUrl != originalUrl;

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _apiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final registryState = ref.watch(animeSourceRegistryProvider);
    final selectedKey = ref.watch(selectedProviderKeyProvider);
    final serverStatusAsync = ref.watch(serverStatusProvider);
    final apiStatus = ref.watch(apiStatusProvider);

    // Check if the registry is initialized
    if (!registryState.registry.isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Anime Providers'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Initializing anime providers...',
                style: TextStyle(color: colorScheme.onSurface),
              ),
              if (registryState.error != null)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Error: ${registryState.error}',
                    style: TextStyle(color: colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      );
    }

    ref.listen(temporarySelectionProvider, (_, __) {
      _checkForChanges();
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anime Sources',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_2),
        ),
        actions: [
          _buildSaveButton(context),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primaryContainer,
              ],
            ),
          ),
        ),
      ),
      body: serverStatusAsync.when(
        loading: () => _buildLoadingState(colorScheme),
        error: (error, stack) => _buildErrorState(error, colorScheme),
        data: (serverStatus) => _buildMainContent(
          context,
          registryState.registry.allProviders,
          selectedKey.selectedProviderKey,
          serverStatus,
          colorScheme,
          apiStatus,
        ),
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: IconButton(
        onPressed: _hasChanges ? _saveChanges : null,
        icon: const Icon(Iconsax.tick_square),
        tooltip: 'Save Changes',
      ),
    );
  }

  void _saveChanges() {
    final tempSelect = ref.read(temporarySelectionProvider);
    final apiStatus = ref.read(apiStatusProvider);
    final apiUrl = apiStatus.isValid && _apiController.url.isNotEmpty
        ? ApiUrlController._cleanUrl(_apiController.url)
        : null;

    if (tempSelect != null) {
      ref
          .read(selectedProviderKeyProvider.notifier)
          .updateSelectedProvider(tempSelect, apiUrl);

      // Reset changes tracker
      setState(() {
        _hasChanges = false;
      });

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Provider settings saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Checking provider status...',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error, ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.cloud_cross, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Could not fetch provider status',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(serverStatusProvider),
              icon: const Icon(Iconsax.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    List<dynamic> providers,
    String selectedKey,
    Map<String, ServerStatus> serverStatus,
    ColorScheme colorScheme,
    ApiStatus apiStatus,
  ) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _buildApiInputSection(colorScheme, apiStatus),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  'Providers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
                const Spacer(),
                _buildStatusLegend(colorScheme),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.builder(
            itemCount: providers.length,
            itemBuilder: (context, index) => _buildProviderTile(
              context,
              providers[index],
              serverStatus[providers[index].providerName.toLowerCase()] ??
                  ServerStatus.unknown(),
              colorScheme,
            ),
          ),
        ),
        // Add some bottom padding for safety
        const SliverToBoxAdapter(
          child: SizedBox(height: 20),
        ),
      ],
    );
  }

  Widget _buildStatusLegend(ColorScheme colorScheme) {
    return Row(
      children: [
        _buildLegendItem(Colors.green, 'Online', colorScheme),
        const SizedBox(width: 8),
        _buildLegendItem(Colors.orange, 'Issues', colorScheme),
        const SizedBox(width: 8),
        _buildLegendItem(Colors.red, 'Offline', colorScheme),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildApiInputSection(ColorScheme colorScheme, ApiStatus apiStatus) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Iconsax.code, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Custom API URL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _apiController.textController,
          decoration: InputDecoration(
            hintText: 'e.g., https://api.example.com',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
            filled: true,
            fillColor:
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            prefixIcon: const Icon(Iconsax.link),
            suffixIcon: apiStatus.isChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _apiController.textController.text.isEmpty
                    ? null
                    : Icon(
                        apiStatus.isValid
                            ? Iconsax.tick_circle
                            : Icons.error_outline_rounded,
                        color: apiStatus.isValid
                            ? Colors.green
                            : colorScheme.error,
                      ),
            helperText: apiStatus.isValid
                ? 'API connection verified'
                : _apiController.textController.text.isNotEmpty &&
                        !apiStatus.isChecking
                    ? 'Could not verify API connection'
                    : 'Enter a custom API URL if needed',
            helperStyle: TextStyle(
              color: apiStatus.isValid
                  ? Colors.green
                  : _apiController.textController.text.isNotEmpty &&
                          !apiStatus.isChecking
                      ? colorScheme.error
                      : colorScheme.onSurfaceVariant,
            ),
          ),
          onChanged: (value) => _apiController.debounceCheck(ref, value),
        ),
      ],
    );
  }

  Widget _buildProviderTile(
    BuildContext context,
    dynamic provider,
    ServerStatus status,
    ColorScheme colorScheme,
  ) {
    final tempSelection = ref.watch(temporarySelectionProvider);
    final isSelected = provider.providerName == tempSelection;
    final statusColor = _getStatusColor(status.status, colorScheme);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: isSelected ? 4 : 1,
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
        child: InkWell(
          onTap: () {
            ref.read(temporarySelectionProvider.notifier).state =
                provider.providerName;
            HapticFeedback.mediumImpact();
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                // Provider icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.surfaceContainerLow,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      provider.providerName[0].toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? colorScheme.onPrimary
                            : colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Provider details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        provider.providerName.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              status.message,
                              style: TextStyle(
                                fontSize: 13,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status indicator
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withValues(alpha: 0.1),
                  ),
                  child: Icon(
                    _getStatusIcon(status.status),
                    size: 18,
                    color: statusColor,
                  ),
                ),
                if (isSelected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Iconsax.tick_square,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getStatusIcon(String status) => switch (status) {
        'online' => Iconsax.tick_circle,
        'issues' => Iconsax.warning_2,
        'offline' => Icons.error,
        _ => Icons.help,
      };

  Color _getStatusColor(String status, ColorScheme colors) => switch (status) {
        'online' => Colors.green,
        'issues' => Colors.orange,
        'offline' => Colors.red,
        _ => colors.onSurface.withValues(alpha: 0.5),
      };
}
