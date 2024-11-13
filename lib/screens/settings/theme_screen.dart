import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:nekoflow/data/models/settings/settings_model.dart';
import 'package:nekoflow/data/theme/theme_manager.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  ThemeType _selectedTheme = ThemeType.dark;
  late Box<SettingsModel> _settingsBox;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box<SettingsModel>('user_settings');
    _loadInitialTheme();
  }

  void _loadInitialTheme() {
    final themeName = _settingsBox.get('theme')?.theme ?? ThemeType.dark.name;
    setState(() {
      _selectedTheme = ThemeManager.getThemeType(themeName) ?? ThemeType.dark;
    });
  }

  Future<void> _updateTheme(ThemeType theme) async {
    setState(() {
      _selectedTheme = theme;
    });
    await _settingsBox.put(
      'theme',
      SettingsModel(theme: theme.name),
    );
  }

  Widget _buildThemeCard(ThemeType themeType) {
    final theme = ThemeManager.getTheme(themeType);
    final isSelected = themeType == _selectedTheme;
    final textColor = _getTextColor(theme.scaffoldBackgroundColor);

    return GestureDetector(
      onTap: () => _updateTheme(themeType),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Theme Preview Elements
            _buildColorStrip(theme.colorScheme.primary),
            const SizedBox(height: 8),
            _buildColorStrip(theme.colorScheme.secondary),
            const SizedBox(height: 12),
            Text(
              _formatThemeName(themeType.name),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorStrip(Color color) {
    return Container(
      height: 8,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  String _formatThemeName(String name) {
    return name.replaceAllMapped(RegExp(r'([A-Z])'), (match) {
      return ' ${match.group(1)}';
    }).capitalize();
  }

  Color _getTextColor(Color backgroundColor) {
    return ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
        ? Colors.black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeManager.getTheme(_selectedTheme);

    return Theme(
      data: themeData,
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.navigate_before,
              size: 35,
              color: themeData.appBarTheme.foregroundColor,
            ),
          ),
          title: Text(
            "Theme",
            style: themeData.textTheme.headlineLarge?.copyWith(
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          forceMaterialTransparency: true,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GridView.builder(
                  itemCount: ThemeType.values.length,
                  padding: const EdgeInsets.only(bottom: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    return _buildThemeCard(ThemeType.values[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() => this.isNotEmpty ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}' : '';
}
