import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:shonenx/features/settings/presentation/reader_settings_screen.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

import 'reader_theme_info.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String mediaTitle;
  final num episodeNumber;
  final ReaderThemeInfo themeInfo;
  final double uiRoundness;

  const ReaderAppBar({
    super.key,
    required this.mediaTitle,
    required this.episodeNumber,
    required this.themeInfo,
    required this.uiRoundness,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final displayChapter = episodeNumber.toString().contains('.0')
        ? episodeNumber.toInt().toString()
        : episodeNumber.toString();

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Container(
                padding: const EdgeInsets.only(
                  left: 6,
                  right: 16,
                  top: 6,
                  bottom: 6,
                ),
                decoration: BoxDecoration(
                  color: themeInfo.appBarBg,
                  borderRadius: BorderRadius.circular(uiRoundness),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: themeInfo.textColor.withValues(
                          alpha: 0.08,
                        ),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(32, 32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            (uiRoundness - 4).clamp(0.0, uiRoundness),
                          ),
                        ),
                      ),
                      onPressed: context.pop,
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: themeInfo.textColor,
                        size: 18,
                      ),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        mediaTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: themeInfo.textColor,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(
                          (uiRoundness - 4).clamp(0.0, uiRoundness),
                        ),
                      ),
                      child: Text(
                        'Ch. $displayChapter',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                color: themeInfo.appBarBg,
                borderRadius: BorderRadius.circular(uiRoundness),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    style: IconButton.styleFrom(
                      minimumSize: const Size(42, 42),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(uiRoundness),
                      ),
                    ),
                    icon: Icon(
                      Icons.tune_rounded,
                      color: themeInfo.textColor,
                      size: 20,
                    ),
                    tooltip: 'Reader Settings',
                    onPressed: () => AppBottomSheet.show(
                      context: context,
                      title: 'Reader Settings',
                      child: const ReaderSettingsContent(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
