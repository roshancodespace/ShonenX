import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final PreferredSizeWidget? barBottom;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool centerTitle;
  final bool showBackButton;

  const AppScaffold({
    super.key,
    this.title,
    this.subtitle,
    this.barBottom,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.centerTitle = false,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    final isDark = theme.brightness == Brightness.dark;
    final overlayStyle = isDark
        ? SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
          )
        : SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
          );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        appBar: title == null && actions == null
            ? null
            : AppBar(
                title: title == null
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title!,
                            style: textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle!,
                              style: textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                bottom: barBottom,
                centerTitle: centerTitle,
                elevation: 0,
                scrolledUnderElevation: 0,
                forceMaterialTransparency: true,
                leading: showBackButton && context.canPop()
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new),
                        onPressed: () => context.pop(),
                      )
                    : null,

                actions: actions,
              ),
        body: SafeArea(child: body),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
      ),
    );
  }
}
