import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/shared/providers/theme_prefs_provider.dart';

void showWallpaperCustomizationSheet(
  BuildContext context, {
  required String imagePath,
  required double initialBlur,
  required double initialOpacity,
  required double initialSaturation,
  required double initialBrightness,
  required bool isNewWallpaper,
}) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false, // Allows background to peek through during transition
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _WallpaperCustomizationOverlay(
            imagePath: imagePath,
            initialBlur: initialBlur,
            initialOpacity: initialOpacity,
            initialSaturation: initialSaturation,
            initialBrightness: initialBrightness,
            isNewWallpaper: isNewWallpaper,
          ),
        );
      },
    ),
  );
}

class _WallpaperCustomizationOverlay extends ConsumerStatefulWidget {
  const _WallpaperCustomizationOverlay({
    required this.imagePath,
    required this.initialBlur,
    required this.initialOpacity,
    required this.initialSaturation,
    required this.initialBrightness,
    required this.isNewWallpaper,
  });

  final String imagePath;
  final double initialBlur;
  final double initialOpacity;
  final double initialSaturation;
  final double initialBrightness;
  final bool isNewWallpaper;

  @override
  ConsumerState<_WallpaperCustomizationOverlay> createState() =>
      _WallpaperCustomizationOverlayState();
}

class _WallpaperCustomizationOverlayState
    extends ConsumerState<_WallpaperCustomizationOverlay> {
  late double _currentBlur;
  late double _currentOpacity;
  late double _currentSaturation;
  late double _currentBrightness;

  bool _isProcessing = false;
  bool _isInteracting = false;

  @override
  void initState() {
    super.initState();
    _currentBlur = widget.initialBlur;
    _currentOpacity = widget.initialOpacity;
    _currentSaturation = widget.initialSaturation;
    _currentBrightness = widget.initialBrightness;
  }

  Widget _buildUnboxedSlider({
    required IconData icon,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
    int? divisions,
  }) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: cs.onSurface.withValues(alpha: 0.8)),
          const SizedBox(width: 16),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3.0,
                thumbShape: const RoundSliderThumbShape(
                  enabledThumbRadius: 8.0,
                ),
                overlayShape: const RoundSliderOverlayShape(
                  overlayRadius: 16.0,
                ),
                activeTrackColor: cs.primary,
                inactiveTrackColor: cs.primary.withValues(alpha: 0.2),
                thumbColor: cs.primary,
                overlayColor: cs.primary.withValues(alpha: 0.1),
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                onChangeStart: (_) => setState(() => _isInteracting = true),
                onChangeEnd: (_) => setState(() => _isInteracting = false),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 40,
            child: Text(
              displayValue,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                fontFeatures: const [ui.FontFeature.tabularFigures()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(themePrefsProvider.notifier);
    final cs = Theme.of(context).colorScheme;

    final double r = 0.2126;
    final double g = 0.7152;
    final double b = 0.0722;
    final double invS = 1.0 - _currentSaturation;
    final double R = r * invS;
    final double G = g * invS;
    final double B = b * invS;

    final matrix = [
      (R + _currentSaturation) * _currentBrightness,
      G * _currentBrightness,
      B * _currentBrightness,
      0.0,
      0.0,
      R * _currentBrightness,
      (G + _currentSaturation) * _currentBrightness,
      B * _currentBrightness,
      0.0,
      0.0,
      R * _currentBrightness,
      G * _currentBrightness,
      (B + _currentSaturation) * _currentBrightness,
      0.0,
      0.0,
      0.0,
      0.0,
      0.0,
      1.0,
      0.0,
    ];

    return Scaffold(
      backgroundColor: cs.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: _currentOpacity,
            child: ImageFiltered(
              imageFilter: ui.ImageFilter.blur(
                sigmaX: _currentBlur,
                sigmaY: _currentBlur,
              ),
              child: ColorFiltered(
                colorFilter: ColorFilter.matrix(matrix),
                child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedOpacity(
              opacity: _isInteracting ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cs.surface.withValues(alpha: 0.0),
                      cs.surface.withValues(alpha: 0.6),
                      cs.surface.withValues(alpha: 0.95),
                      cs.surface,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 64,
                  bottom: MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildUnboxedSlider(
                      icon: Icons.blur_on_rounded,
                      value: _currentBlur,
                      min: 0.0,
                      max: 25.0,
                      divisions: 25,
                      displayValue: '${_currentBlur.toInt()}',
                      onChanged: (v) => setState(() => _currentBlur = v),
                    ),
                    _buildUnboxedSlider(
                      icon: Icons.contrast_rounded,
                      value: _currentOpacity,
                      min: 0.0,
                      max: 1.0,
                      displayValue: '${(_currentOpacity * 100).toInt()}%',
                      onChanged: (v) => setState(() => _currentOpacity = v),
                    ),
                    _buildUnboxedSlider(
                      icon: Icons.color_lens_rounded,
                      value: _currentSaturation,
                      min: 0.0,
                      max: 2.0,
                      displayValue: '${_currentSaturation.toStringAsFixed(1)}x',
                      onChanged: (v) => setState(() => _currentSaturation = v),
                    ),
                    _buildUnboxedSlider(
                      icon: Icons.light_mode_rounded,
                      value: _currentBrightness,
                      min: 0.5,
                      max: 1.5,
                      displayValue: '${_currentBrightness.toStringAsFixed(1)}x',
                      onChanged: (v) => setState(() => _currentBrightness = v),
                    ),
                    const SizedBox(height: 24),

                    // ACTIONS
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: _isProcessing
                              ? null
                              : () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: cs.onSurfaceVariant,
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () async {
                                  setState(() => _isProcessing = true);
                                  final result = await notifier
                                      .processBackgroundImage(
                                        widget.imagePath,
                                        _currentBlur,
                                        _currentSaturation,
                                        _currentBrightness,
                                      );
                                  notifier.updateTheme(
                                    (p) => p.copyWith(
                                      wallpaperSettings: WallpaperSettings(
                                        imagePath: widget.imagePath,
                                        processedPath:
                                            result?.processedPath ??
                                            widget.imagePath,
                                        blur: _currentBlur,
                                        opacity: _currentOpacity,
                                        saturation: _currentSaturation,
                                        brightness: _currentBrightness,
                                        imageColorSeed: result?.imageColorSeed,
                                      ),
                                      useGradients: widget.isNewWallpaper
                                          ? false
                                          : p.useGradients,
                                    ),
                                  );
                                  setState(() => _isProcessing = false);
                                  if (context.mounted) Navigator.pop(context);
                                },
                          style: FilledButton.styleFrom(
                            backgroundColor: cs.primary,
                            foregroundColor: cs.onPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: _isProcessing
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: cs.onPrimary,
                                  ),
                                )
                              : const Icon(Icons.check_rounded, size: 20),
                          label: const Text(
                            'Apply Wallpaper',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
