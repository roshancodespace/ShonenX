import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/boxes/settings_box.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';

class ThemeScreenV2 extends StatefulWidget {
  final String title;
  const ThemeScreenV2({super.key, required this.title});

  @override
  State<ThemeScreenV2> createState() => _ThemeScreenV2State();
}

class _ThemeScreenV2State extends State<ThemeScreenV2> {
  late SettingsBox _settingsBox;
  late String _themeMode;
  late FlexScheme _flexScheme;

  @override
  void initState() {
    super.initState();
    initializeBox();
    loadInitialTheme();
  }

  Future<void> loadInitialTheme() async {
    final theme = _settingsBox.getTheme()!;
    setState(() {
      _themeMode = theme.themeMode;
      _flexScheme = theme.flexScheme;
    });
  }

  Future<void> initializeBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox.init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            size: 35,
          ),
        ),
        title: Hero(
          tag: ValueKey(widget.title),
          child: Text(
            'Theme',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _settingsBox.listenable(),
        builder: (context, value, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Theme',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildThemeModeContainer(),
                  const SizedBox(height: 32),
                  Text(
                    'Color Schemes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildColorSchemeGrid(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeModeContainer() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          _buildThemeModeButton(
            'Dark',
            Icons.dark_mode_rounded,
            'dark',
            description: 'Dark theme for low-light environments',
          ),
          _buildThemeModeButton(
            'Light',
            Icons.light_mode_rounded,
            'light',
            description: 'Light theme for better readability',
          ),
          _buildThemeModeButton(
            'System',
            Icons.settings_system_daydream_rounded,
            'system',
            description: 'Follows your system theme',
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeButton(
    String label,
    IconData icon,
    String mode, {
    required String description,
  }) {
    final isSelected = _themeMode == mode;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      child: InkWell(
        onTap: () {
          setState(() {
            _themeMode = mode;
            _settingsBox.updateTheme(
                ThemeModel(themeMode: _themeMode, flexScheme: _flexScheme));
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primaryContainer.withOpacity(0.2)
                : colorScheme.surface.withOpacity(0.2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primaryContainer
                      : colorScheme.surface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedTick02,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorSchemeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.9,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: FlexScheme.values.length,
      itemBuilder: (context, index) {
        final scheme = FlexScheme.values[index];
        return _ColorSchemeCard(
          title: scheme.name,
          scheme: scheme,
          isSelected: _flexScheme == scheme,
          onTap: () {
            setState(() {
              _flexScheme = scheme;
              _settingsBox.updateTheme(
                ThemeModel(
                  themeMode: _themeMode,
                  flexScheme: _flexScheme,
                ),
              );
            });
          },
        );
      },
    );
  }
}

class _ColorSchemeCard extends StatelessWidget {
  final String title;
  final FlexScheme scheme;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSchemeCard({
    required this.title,
    required this.scheme,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final schemeData = FlexThemeData.light(scheme: scheme).colorScheme;

    return Card(
      margin: EdgeInsets.all(0),
      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(
              //   title,
              //   style: TextStyle(
              //     fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              //     color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              //   ),
              // ),
              const Spacer(),
              Row(
                children: [
                  _buildColorDot(schemeData.primary),
                  const SizedBox(width: 8),
                  _buildColorDot(schemeData.secondary),
                  const SizedBox(width: 8),
                  _buildColorDot(schemeData.tertiary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
