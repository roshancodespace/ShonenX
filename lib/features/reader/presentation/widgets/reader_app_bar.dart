import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/settings/presentation/reader_settings_screen.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

import 'reader_theme_info.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String mediaTitle;
  final num episodeNumber;
  final ReaderThemeInfo themeInfo;

  const ReaderAppBar({
    super.key,
    required this.mediaTitle,
    required this.episodeNumber,
    required this.themeInfo,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayChapter = episodeNumber.toString().contains('.0')
        ? episodeNumber.toInt().toString()
        : episodeNumber.toString();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            color: themeInfo.appBarBg.withValues(alpha: 0.75),
          ),
          child: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mediaTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: themeInfo.textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Chapter $displayChapter',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: themeInfo.textColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: false,
            iconTheme: IconThemeData(color: themeInfo.textColor),
            leading: IconButton(
              onPressed: context.pop,
              icon: const Icon(Icons.arrow_back_ios_new_outlined),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                onPressed: () => AppBottomSheet.show(
                  context: context,
                  title: 'Reader Settings',
                  child: const ReaderSettingsContent(),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}
