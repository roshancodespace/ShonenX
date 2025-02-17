import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/data/hive/boxes/settings_box.dart';
import 'package:shonenx/data/hive/models/settings_offline_model.dart';

class AppearanceSettingsScreen extends ConsumerStatefulWidget {
  const AppearanceSettingsScreen({super.key});

  @override
  ConsumerState<AppearanceSettingsScreen> createState() =>
      _AppearanceSettingsScreenState();
}

class _AppearanceSettingsScreenState
    extends ConsumerState<AppearanceSettingsScreen> {
  late SettingsBox? _settingsBox;
  bool _isDarkMode = false;
  bool _useAmoledBlack = false;
  FlexScheme _flexScheme = FlexScheme.deepPurple;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _settingsBox = SettingsBox();
    await _settingsBox?.init();
    final settings = _settingsBox?.getSettings()?.appearanceSettings;
    setState(() {
      _isDarkMode = settings?.themeMode != 'light';
      _useAmoledBlack = settings?.amoled ?? false;
      _flexScheme = settings?.colorScheme ?? FlexScheme.red;
    });
  }

  void _updateAppearanceSettings() {
    _settingsBox?.updateAppearanceSettings(
      AppearanceSettingsModel(
          themeMode: _isDarkMode ? 'dark' : 'light',
          amoled: _useAmoledBlack,
          colorScheme: _flexScheme),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Iconsax.arrow_left_1),
        ),
        title: const Text(
          'Appearance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThemeSection(),
                _buildSectionHeader('Color Schemes'),
                _buildColorSchemeGrid(constraints.maxWidth > 600),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildThemeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('Theme'),
        _SettingsSwitchTile(
          title: 'Dark Mode',
          subtitle: 'Use dark theme',
          icon: Iconsax.moon,
          value: _isDarkMode,
          onChanged: (value) {
            setState(() {
              _isDarkMode = value;
              _updateAppearanceSettings();
            });
          },
        ),
        if (_isDarkMode)
          _SettingsSwitchTile(
            title: 'AMOLED Dark',
            subtitle: 'Use pure black theme',
            icon: Iconsax.colorfilter,
            value: _useAmoledBlack,
            onChanged: (value) {
              setState(() {
                _useAmoledBlack = value;
                _updateAppearanceSettings();
              });
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildColorSchemeGrid(bool isWideScreen) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // final crossAxisCount = isWideScreen
          //     ? (constraints.maxWidth / 200).floor()
          //     : (constraints.maxWidth / 130).floor();

          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: isWideScreen ? 200 : 130,
              childAspectRatio: 1.2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: FlexScheme.values.length,
            itemBuilder: (context, index) => _ColorSchemeCard(
              scheme: FlexScheme.values[index],
              isSelected: _flexScheme == FlexScheme.values[index],
              onSelected: (scheme) {
                setState(() => _flexScheme = scheme);
                _updateAppearanceSettings();
              },
            ),
          );
        },
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: () => onChanged(!value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorSchemeCard extends StatefulWidget {
  final FlexScheme scheme;
  final bool isSelected;
  final ValueChanged<FlexScheme> onSelected;

  const _ColorSchemeCard({
    required this.scheme,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<_ColorSchemeCard> createState() => _ColorSchemeCardState();
}

class _ColorSchemeCardState extends State<_ColorSchemeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatSchemeName(String name) {
    return name
        .splitMapJoin(
          RegExp(r'(?=[A-Z])'),
          onMatch: (m) => ' ${m.group(0)}',
        )
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final schemeData = FlexThemeData.light(scheme: widget.scheme).colorScheme;
    final darkSchemeData =
        FlexThemeData.dark(scheme: widget.scheme).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentScheme = isDark ? darkSchemeData : schemeData;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) => Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: currentScheme.primary.withValues(alpha: 0.1),
                  blurRadius: _isHovered ? 16 : 8,
                  spreadRadius: _isHovered ? 2 : 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => widget.onSelected(widget.scheme),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: widget.isSelected
                          ? currentScheme.primary
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      children: [
                        // Background Pattern
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _SchemePatternPainter(
                              colors: [
                                currentScheme.primary,
                                currentScheme.secondary,
                                currentScheme.tertiary,
                              ],
                              isDark: isDark,
                            ),
                          ),
                        ),

                        // Content
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Color Preview Section
                            Expanded(
                              flex: 1,
                              child: _buildColorPreview(currentScheme),
                            ),

                            // Scheme Name Section
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.black : Colors.white)
                                    .withValues(alpha: 0.9),
                                borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(18),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatSchemeName(widget.scheme.name),
                                      style: TextStyle(
                                        color: currentScheme.onSurface,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (widget.isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      size: 18,
                                      color: currentScheme.primary,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColorPreview(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _ColorBubble(
          color: scheme.primary,
          label: 'P',
          isAnimated: _isHovered,
        ),
        _ColorBubble(
          color: scheme.secondary,
          label: 'S',
          isAnimated: _isHovered,
          delay: const Duration(milliseconds: 50),
        ),
        _ColorBubble(
          color: scheme.tertiary,
          label: 'T',
          isAnimated: _isHovered,
          delay: const Duration(milliseconds: 100),
        ),
      ],
    );
  }
}

class _ColorBubble extends StatelessWidget {
  final Color color;
  final String label;
  final bool isAnimated;
  final Duration delay;

  const _ColorBubble({
    required this.color,
    required this.label,
    required this.isAnimated,
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      height: isAnimated ? 32 : 28,
      width: isAnimated ? 32 : 29,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: isAnimated ? 12 : 6,
            spreadRadius: isAnimated ? 2 : 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _SchemePatternPainter extends CustomPainter {
  final List<Color> colors;
  final bool isDark;

  _SchemePatternPainter({
    required this.colors,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Create subtle pattern with theme colors
    for (int i = 0; i < colors.length; i++) {
      paint.color = colors[i].withValues(alpha: 0.1);

      // Draw diagonal lines
      for (double x = -size.width; x < size.width; x += 20) {
        canvas.drawLine(
          Offset(x + (i * 10), 0),
          Offset(x + size.width + (i * 10), size.height),
          paint,
        );
      }
    }

    // Add subtle gradient overlay
    final Rect rect = Offset.zero & size;
    final paint2 = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors[0].withValues(alpha: 0.1),
          colors[1].withValues(alpha: 0.05),
          colors[2].withValues(alpha: 0.1),
        ],
      ).createShader(rect);

    canvas.drawRect(rect, paint2);
  }

  @override
  bool shouldRepaint(_SchemePatternPainter oldDelegate) =>
      colors != oldDelegate.colors || isDark != oldDelegate.isDark;
}
