import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:shonenx/features/discovery/presentation/widgets/cards/media_card.dart';
import 'package:shonenx/shared/models/component_layout.dart';
import 'package:shonenx/shared/providers/ui_prefs_provider.dart';

class ExperimentalLiquidCard extends StatefulWidget {
  final MediaCard widget;
  final ThemeData theme;
  final bool isActive;
  final ComponentLayout layout;
  final Map<String, dynamic>? config;

  const ExperimentalLiquidCard({
    super.key,
    required this.widget,
    required this.theme,
    required this.isActive,
    required this.layout,
    this.config,
  });

  @override
  State<ExperimentalLiquidCard> createState() => _ExperimentalLiquidCardState();
}

class _ExperimentalLiquidCardState extends State<ExperimentalLiquidCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _pointer = const Offset(0.5, 0.4);
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePointer(Offset local) {
    if (widget.layout.width == 0 || widget.layout.height == 0) return;
    setState(() {
      _pointer = Offset(
        (local.dx / widget.layout.width).clamp(0.0, 1.0),
        (local.dy / widget.layout.height).clamp(0.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.layout.width;
    final h = widget.layout.height;
    final active = _isHovered || _isPressed || widget.isActive;
    final configMap = widget.config ?? UiPrefState.defaultExperimentalConfig;
    final enableMetaball = configMap['enableMetaball'] != false;
    final interactiveOrb = configMap['interactiveOrb'] != false;
    final enable3dTilt = configMap['enable3dTilt'] != false;
    final smoothness = (configMap['smoothness'] as num?)?.toDouble() ?? 46.0;
    final distortion = (configMap['distortion'] as num?)?.toDouble() ?? 0.15;
    final magnification =
        (configMap['magnification'] as num?)?.toDouble() ?? 1.06;
    final chromaticAberration =
        (configMap['chromaticAberration'] as num?)?.toDouble() ?? 0.006;
    final borderSaturation =
        (configMap['borderSaturation'] as num?)?.toDouble() ?? 1.6;
    final enableLuminousBorder = configMap['enableLuminousBorder'] != false;
    final borderGlowIntensity =
        (configMap['borderGlowIntensity'] as num?)?.toDouble() ?? 0.65;
    final borderWidth = (configMap['borderWidth'] as num?)?.toDouble() ?? 2.0;
    final cardTintOpacity =
        (configMap['cardTintOpacity'] as num?)?.toDouble() ?? 0.10;
    final lensAppearanceTint =
        (configMap['lensAppearanceTint'] as num?)?.toDouble() ?? 0.13;
    final enableBadgeLens = configMap['enableBadgeLens'] != false;
    final enableCardShadow = configMap['enableCardShadow'] == true;

    final cardRoundness = GlobalUI.uiRoundness;
    final badgeRoundness = cardRoundness == 0
        ? 0.0
        : (cardRoundness * 0.55).clamp(4.0, 16.0);
    final titleRoundness = cardRoundness == 0
        ? 0.0
        : (cardRoundness * 0.75).clamp(4.0, 20.0);
    final orbRoundness = cardRoundness == 0
        ? 0.0
        : (cardRoundness * 0.9).clamp(4.0, 22.0);

    final matrix = Matrix4.identity();
    if (active && enable3dTilt) {
      matrix.setEntry(3, 2, 0.001);
      final rotateY = (_pointer.dx - 0.5) * 0.16;
      final rotateX = (0.5 - _pointer.dy) * 0.16;
      matrix.rotateY(rotateY);
      matrix.rotateX(rotateX);
    }

    return MouseRegion(
      onHover: (e) {
        if (!_isHovered) setState(() => _isHovered = true);
        _updatePointer(e.localPosition);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onPanUpdate: (d) => _updatePointer(d.localPosition),
        onTapDown: (d) {
          setState(() => _isPressed = true);
          _updatePointer(d.localPosition);
        },
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.widget.onTap,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (active ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: RepaintBoundary(
            child: Transform(
              transform: matrix,
              alignment: Alignment.center,
              child: Container(
                width: w,
                height: h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(cardRoundness),
                  boxShadow: enableCardShadow
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: active ? 0.35 : 0.2,
                            ),
                            blurRadius: active ? 16 : 10,
                            offset: Offset(0, active ? 6 : 4),
                          ),
                        ]
                      : const [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(cardRoundness),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      LiquidGlassView(
                        backgroundWidget: Stack(
                          fit: StackFit.expand,
                          children: [
                            RepaintBoundary(
                              child: buildCardImage(
                                widget.widget,
                                widget.theme,
                                width: w,
                                height: h,
                                radius: 0,
                              ),
                            ),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  stops: const [0.0, 0.55, 1.0],
                                  colors: [
                                    Colors.black.withValues(alpha: 0.15),
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.55),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        child: LiquidGlassBlender(
                          smoothness: smoothness,
                          style: LiquidGlassStyle(
                            shape: LiquidGlassShape.squircle(
                              cornerRadius: cardRoundness,
                              borderType: OpticalBorder(
                                borderSaturation: borderSaturation,
                                ambientIntensity: 1.2,
                                borderSolidity: 0.1,
                              ),
                            ),
                            appearance: LiquidGlassAppearance(
                              color: Colors.white.withValues(
                                alpha: cardTintOpacity,
                              ),
                              saturation: 1.15,
                            ),
                            refraction: LiquidGlassRefraction(
                              distortion: distortion,
                              distortionWidth: 24,
                              magnification: magnification,
                              chromaticAberration: chromaticAberration,
                            ),
                          ),
                          child: IgnorePointer(
                            child: Stack(
                              children: [
                                if (widget.widget.format != null)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: enableBadgeLens
                                        ? LiquidGlassLens(
                                            style: LiquidGlassStyle(
                                              shape: LiquidGlassShape.squircle(
                                                cornerRadius: badgeRoundness,
                                              ),
                                              appearance: LiquidGlassAppearance(
                                                color: Colors.black.withValues(
                                                  alpha: lensAppearanceTint,
                                                ),
                                              ),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 5,
                                                  ),
                                              child: Text(
                                                widget.widget.format!,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 10,
                                                  letterSpacing: 0.4,
                                                ),
                                              ),
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.65,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    badgeRoundness,
                                                  ),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.18,
                                                ),
                                                width: 0.6,
                                              ),
                                            ),
                                            child: Text(
                                              widget.widget.format!,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 10,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ),
                                  ),

                                if (widget.widget.badge != null)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: enableBadgeLens
                                        ? LiquidGlassLens(
                                            style: LiquidGlassStyle(
                                              shape: LiquidGlassShape.squircle(
                                                cornerRadius: badgeRoundness,
                                              ),
                                              appearance: LiquidGlassAppearance(
                                                color: Colors.black.withValues(
                                                  alpha: lensAppearanceTint,
                                                ),
                                              ),
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: widget.widget.badge!,
                                            ),
                                          )
                                        : Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.6,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    badgeRoundness,
                                                  ),
                                              border: Border.all(
                                                color: Colors.white.withValues(
                                                  alpha: 0.18,
                                                ),
                                                width: 0.6,
                                              ),
                                            ),
                                            child: widget.widget.badge!,
                                          ),
                                  ),

                                if (enableMetaball && active)
                                  AnimatedBuilder(
                                    animation: _controller,
                                    builder: (context, _) {
                                      final targetX = interactiveOrb
                                          ? _pointer.dx * w
                                          : w * 0.55;
                                      final targetY = interactiveOrb
                                          ? _pointer.dy * h
                                          : h * 0.45;

                                      final leftPos = (targetX - 22).clamp(
                                        6.0,
                                        w - 50.0,
                                      );
                                      final topPos = (targetY - 22).clamp(
                                        6.0,
                                        h - 50.0,
                                      );

                                      return Positioned(
                                        left: leftPos,
                                        top: topPos,
                                        child: RepaintBoundary(
                                          child: SizedBox(
                                            width: 44,
                                            height: 44,
                                            child: LiquidGlassLens(
                                              style: LiquidGlassStyle(
                                                shape:
                                                    LiquidGlassShape.squircle(
                                                      cornerRadius:
                                                          orbRoundness,
                                                    ),
                                                appearance: LiquidGlassAppearance(
                                                  color: Colors.white.withValues(
                                                    alpha:
                                                        (lensAppearanceTint *
                                                                0.7)
                                                            .clamp(0.0, 0.35),
                                                  ),
                                                ),
                                                refraction:
                                                    LiquidGlassRefraction(
                                                      distortion:
                                                          distortion * 1.5,
                                                      distortionWidth: 18,
                                                      magnification:
                                                          magnification + 0.1,
                                                      chromaticAberration:
                                                          chromaticAberration *
                                                          1.3,
                                                    ),
                                              ),
                                              child: Center(
                                                child: AnimatedRotation(
                                                  turns: active
                                                      ? 0.0
                                                      : _controller.value,
                                                  duration: const Duration(
                                                    milliseconds: 200,
                                                  ),
                                                  child: Icon(
                                                    active
                                                        ? Icons
                                                              .play_arrow_rounded
                                                        : Icons
                                                              .auto_awesome_rounded,
                                                    color: Colors.white
                                                        .withValues(alpha: 0.9),
                                                    size: 22,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                // 4. Bottom Title Bar Lens
                                Positioned(
                                  left: 10,
                                  right: 10,
                                  bottom: 10,
                                  child: LiquidGlassLens(
                                    style: LiquidGlassStyle(
                                      shape: LiquidGlassShape.squircle(
                                        cornerRadius: titleRoundness,
                                      ),
                                      appearance: LiquidGlassAppearance(
                                        color: Colors.black.withValues(
                                          alpha: lensAppearanceTint,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        widget.widget.title,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          height: 1.25,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Active state luminous border overlay
                      if (enableLuminousBorder)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  cardRoundness,
                                ),
                                border: Border.all(
                                  color: active
                                      ? Colors.white.withValues(
                                          alpha: borderGlowIntensity,
                                        )
                                      : Colors.white.withValues(alpha: 0.12),
                                  width: active
                                      ? borderWidth
                                      : (borderWidth * 0.4).clamp(0.6, 1.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
