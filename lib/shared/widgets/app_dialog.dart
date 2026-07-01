import 'package:flutter/material.dart';

class AppDialog extends StatelessWidget {
  final String? title;
  final Widget? icon;
  final Widget child;
  final List<Widget>? actions;
  final double maxWidth;
  final EdgeInsetsGeometry contentPadding;
  final bool showCloseButton;
  final bool wrapScrollable;

  const AppDialog({
    super.key,
    this.title,
    this.icon,
    required this.child,
    this.actions,
    this.maxWidth = 600,
    this.contentPadding = const EdgeInsets.all(24),
    this.showCloseButton = true,
    this.wrapScrollable = true,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    Widget? icon,
    required Widget child,
    List<Widget>? actions,
    double maxWidth = 600,
    EdgeInsetsGeometry contentPadding = const EdgeInsets.all(24),
    bool showCloseButton = true,
    bool barrierDismissible = true,
    bool wrapScrollable = true,
    Color? barrierColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: barrierColor ?? Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (context, animation, secondaryAnimation) {
        return AppDialog(
          title: title,
          icon: icon,
          actions: actions,
          maxWidth: maxWidth,
          contentPadding: contentPadding,
          showCloseButton: showCloseButton,
          wrapScrollable: wrapScrollable,
          child: child,
        );
      },
      transitionBuilder: (context, anim, secondaryAnim, child) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        final slideTween = Tween<Offset>(
          begin: const Offset(0.0, 0.18),
          end: Offset.zero,
        );

        final scaleTween = Tween<double>(begin: 0.9, end: 1.0);

        final rotationTween = Tween<double>(begin: 0.2, end: 0.0);

        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: slideTween.animate(curved),
            child: ScaleTransition(
              scale: scaleTween.animate(curved),
              child: AnimatedBuilder(
                animation: curved,
                builder: (context, child) {
                  final tilt = rotationTween.evaluate(curved);
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0018) // Strong 3D perspective depth
                      ..rotateX(tilt),
                    child: child,
                  );
                },
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: maxWidth,
            maxHeight: size.height * 0.88,
          ),
          margin: EdgeInsets.symmetric(
            horizontal: size.width < 500 ? 16 : 40,
            vertical: size.height < 500 ? 16 : 32,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null || icon != null || showCloseButton) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (icon != null) ...[
                              icon!,
                              const SizedBox(width: 12),
                            ],
                            if (title != null)
                              Expanded(
                                child: Text(
                                  title!,
                                  style: TextStyle(
                                    fontSize: size.width < 500 ? 18 : 20,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.3,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (showCloseButton)
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                    ],
                  ),
                ),
              ],
              Flexible(
                child: wrapScrollable
                    ? SingleChildScrollView(
                        padding: contentPadding,
                        child: child,
                      )
                    : Padding(padding: contentPadding, child: child),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: actions!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
