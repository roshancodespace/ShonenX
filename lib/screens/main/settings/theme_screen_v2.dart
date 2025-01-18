import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
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
  late double _cardRadius;
  late bool _trueBlack;
  late bool _swapColors;

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
      _trueBlack = theme.trueBlack;
      _swapColors = theme.swapColors;
      _cardRadius = theme.cardRadius;
    });
  }

  Future<void> _updateTheme() async {
    await _settingsBox.updateTheme(ThemeModel(
      themeMode: _themeMode,
      flexScheme: _flexScheme,
      trueBlack: _trueBlack,
      swapColors: _swapColors,
      cardRadius: _cardRadius,
    ));
  }

  Future<void> initializeBox() async {
    _settingsBox = SettingsBox();
    await _settingsBox.init();
  }

  void _showAdvancedSettingsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Advanced Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              _buildSwitchTile(
                'Pitch Black',
                'Optimized for AMOLED displays',
                _trueBlack,
                (value) async {
                  setState(() => _trueBlack = value);
                  this.setState(() {});
                  await _updateTheme();
                },
              ),
              _buildSwitchTile(
                'Swap Colors',
                'Invert primary and secondary colors',
                _swapColors,
                (value) async {
                  setState(() => _swapColors = value);
                  this.setState(() {});
                  await _updateTheme();
                },
              ),
              _buildRadiusSliderTile(),
            ],
          ),
        ),
      ),
    );
  }

  void _showColorSchemeModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Color Scheme',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                shrinkWrap: true,
                physics: ClampingScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: FlexScheme.values.length,
                itemBuilder: (context, index) {
                  final scheme = FlexScheme.values[index];
                  return _buildColorSchemeCard(scheme);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            size: 28,
          ),
        ),
        title: Hero(
          tag: ValueKey(widget.title),
          child: Text(
            'Theme',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _settingsBox.listenable(),
        builder: (context, value, child) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              _buildThemeModeContainer(),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Advanced Settings'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showAdvancedSettingsModal,
                    ),
                    Divider(height: 1),
                    ListTile(
                      title: Text('Color Scheme'),
                      trailing: Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showColorSchemeModal,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSwitchTile(
      String title, String subtitle, bool value, Function(bool) onChanged) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
    );
  }

  Widget _buildRadiusSliderTile() {
    return ListTile(
      title: Text('Cards Roundness'),
      subtitle: Slider(
        value: _cardRadius,
        min: 0,
        max: 40,
        divisions: 8,
        label: _cardRadius.round().toString(),
        onChanged: (value) async {
          setState(() => _cardRadius = value);
          await _updateTheme();
        },
      ),
    );
  }

  Widget _buildThemeModeContainer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appearance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildThemeModeTile(
                'System',
                Icons.brightness_auto,
                'system',
                'Follow system theme',
              ),
              Divider(height: 1),
              _buildThemeModeTile(
                'Light',
                Icons.light_mode,
                'light',
                'Always use light theme',
              ),
              Divider(height: 1),
              _buildThemeModeTile(
                'Dark',
                Icons.dark_mode,
                'dark',
                'Always use dark theme',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeModeTile(
      String title, IconData icon, String mode, String subtitle) {
    final isSelected = _themeMode == mode;
    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      selected: isSelected,
      onTap: () async {
        setState(() => _themeMode = mode);
        await _updateTheme();
      },
    );
  }

  Widget _buildColorSchemeCard(FlexScheme scheme) {
    final isSelected = _flexScheme == scheme;
    final schemeData = FlexThemeData.light(scheme: scheme).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () async {
          setState(() => _flexScheme = scheme);
          await _updateTheme();
          Navigator.pop(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    schemeData.primary,
                    schemeData.secondary,
                    schemeData.tertiary,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        scheme.name.splitMapJoin(RegExp(r'(?=[A-Z])'), onMatch: (m) => ' ${m.group(0)}').trim().split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' '),
                        style: Theme.of(context).textTheme.labelSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}