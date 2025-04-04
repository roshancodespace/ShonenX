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

// Providers
final temporarySelectionProvider = StateProvider<String?>((ref) => null);
final serverStatusProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  try {
    final response = await http.get(Uri.parse(
        'https://raw.githubusercontent.com/Darkx-dev/ShonenX-Providers-Status/refs/heads/main/server_status.json'));
    return response.statusCode == 200
        ? Map<String, Map<String, dynamic>>.from(json.decode(response.body))
        : throw Exception('Failed to load server status');
  } catch (e) {
    return {};
  }
});

final apiStatusProvider = StateProvider<({bool isChecking, bool isValid})>(
    (ref) => (isChecking: false, isValid: false));

// Controller for API URL input with proper debouncing
class ApiUrlController extends ChangeNotifier {
  final TextEditingController textController = TextEditingController();
  Timer? _debounceTimer;
  final Duration debounceDuration;

  ApiUrlController({this.debounceDuration = const Duration(milliseconds: 500)});

  void initializeUrl(String? url) {
    if (url != null) {
      textController.text = url;
    }
  }

  void debounceCheck(WidgetRef ref, String value) {
    _debounceTimer?.cancel();
    ref.read(apiStatusProvider.notifier).state =
        (isChecking: true, isValid: false);

    _debounceTimer = Timer(debounceDuration, () async {
      final cleanUrl = _cleanUrl(value);
      final isValid = await _checkApi(cleanUrl);
      ref.read(apiStatusProvider.notifier).state =
          (isChecking: false, isValid: isValid);
    });
  }

  String get url => textController.text;

  static String _cleanUrl(String url) {
    url = url.trim();
    while (url.endsWith('/')) url = url.substring(0, url.length - 1);
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

class ProviderSettingsScreen extends ConsumerWidget {
  const ProviderSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final registry = ref.watch(animeSourceRegistryProvider);
    final selectedKey = ref.watch(selectedProviderKeyProvider);
    final serverStatusAsync = ref.watch(serverStatusProvider);
    final apiController = ref.watch(_apiUrlControllerProvider);

    // Initialize API URL from selectedKey
    WidgetsBinding.instance.addPostFrameCallback((_) {
      apiController.initializeUrl(selectedKey.customApiUrl);
    });

    return Scaffold(
      appBar: _buildAppBar(colorScheme, context),
      body: serverStatusAsync.when(
        loading: () => _buildLoading(colorScheme),
        error: (_, __) => _buildError(context, ref, colorScheme),
        data: (serverStatus) => _buildContent(
          context,
          ref,
          registry.allProviders,
          selectedKey.selectedProviderKey,
          serverStatus,
          colorScheme,
          apiController,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(
          context, ref, colorScheme, serverStatusAsync, apiController),
    );
  }

  // Provider for the controller
  static final _apiUrlControllerProvider =
      Provider((ref) => ApiUrlController());

  AppBar _buildAppBar(ColorScheme colorScheme, BuildContext context) => AppBar(
        title: const Text('Anime Sources',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
            onPressed: () => context.pop(), icon: Icon(Iconsax.arrow_left_2)),
        backgroundColor: colorScheme.surface,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary.withValues(alpha: .8),
                colorScheme.primaryContainer
              ],
            ),
          ),
        ),
      );

  Widget _buildLoading(ColorScheme colorScheme) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: colorScheme.primary),
            const SizedBox(height: 16),
            Text('Checking provider status...',
                style: TextStyle(color: colorScheme.onSurface)),
          ],
        ),
      );

  Widget _buildError(
          BuildContext context, WidgetRef ref, ColorScheme colorScheme) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.cloud_cross, size: 48, color: colorScheme.error),
            const SizedBox(height: 16),
            Text('Could not fetch provider status',
                style: TextStyle(color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () => ref.invalidate(serverStatusProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      );

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<dynamic> providers,
    String selectedKey,
    Map<String, Map<String, dynamic>> serverStatus,
    ColorScheme colorScheme,
    ApiUrlController apiController,
  ) {
    final apiStatus = ref.watch(apiStatusProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildApiInput(ref, apiController, apiStatus, colorScheme),
          const SizedBox(height: 16),
          Text('Providers',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary)),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) => _buildProviderTile(
                context,
                ref,
                providers[index],
                selectedKey,
                serverStatus[providers[index].providerName.toLowerCase()] ??
                    {
                      'status': 'unknown',
                      'message': 'Status unknown',
                      'lastChecked': DateTime.now().toIso8601String()
                    },
                colorScheme,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiInput(
    WidgetRef ref,
    ApiUrlController controller,
    ({bool isChecking, bool isValid}) apiStatus,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Custom API URL',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: controller.textController,
          decoration: InputDecoration(
            hintText: 'e.g., https://api.example.com',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: apiStatus.isChecking
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : controller.textController.text.isEmpty
                    ? null
                    : Icon(
                        apiStatus.isValid ? Iconsax.tick_circle : Icons.error_outline_rounded,
                        color: apiStatus.isValid
                            ? Colors.green
                            : colorScheme.error,
                      ),
          ),
          onChanged: (value) => controller.debounceCheck(ref, value),
        ),
      ],
    );
  }

  Widget _buildProviderTile(
    BuildContext context,
    WidgetRef ref,
    dynamic provider,
    String selectedKey,
    Map<String, dynamic> status,
    ColorScheme colorScheme,
  ) {
    final isSelected = provider.providerName ==
        (ref.watch(temporarySelectionProvider) ?? selectedKey);
    final statusColor = _getStatusColor(status['status'], colorScheme);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: .3)),
      ),
      child: ListTile(
        onTap: () {
          ref.read(temporarySelectionProvider.notifier).state =
              provider.providerName;
          HapticFeedback.mediumImpact();
        },
        leading: CircleAvatar(
          backgroundColor:
              isSelected ? colorScheme.primary : colorScheme.surfaceContainer,
          child: Text(
            provider.providerName[0].toUpperCase(),
            style: TextStyle(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface),
          ),
        ),
        title: Text(provider.providerName.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status['message']),
        trailing: Icon(_getStatusIcon(status['status']), color: statusColor),
      ),
    );
  }

  Widget _buildBottomNav(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    AsyncValue<Map<String, Map<String, dynamic>>> serverStatusAsync,
    ApiUrlController apiController,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: .1),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: serverStatusAsync.when(
        loading: () => ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary.withValues(alpha: .6)),
          child: const Text('Loading...'),
        ),
        error: (_, __) => ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
          child: const Text('Go Back'),
        ),
        data: (_) => ElevatedButton(
          onPressed: () {
            final tempSelect = ref.read(temporarySelectionProvider);
            final apiStatus = ref.read(apiStatusProvider);
            final apiUrl = apiStatus.isValid && apiController.url.isNotEmpty
                ? ApiUrlController._cleanUrl(apiController.url)
                : null;
            if (tempSelect != null) {
              ref
                  .read(selectedProviderKeyProvider.notifier)
                  .updateSelectedProvider(tempSelect, apiUrl);
            }
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary),
          child: const Text('Apply & Save'),
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
        _ => colors.onSurface.withValues(alpha: .5),
      };
}
