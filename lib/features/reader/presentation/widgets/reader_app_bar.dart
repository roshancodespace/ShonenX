import 'package:material_ui/material_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:shonenx/core/localization/l10n_extension.dart';
import 'package:shonenx/features/settings/presentation/reader_settings_screen.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';
import 'package:shonenx/shared/widgets/app_button_group.dart';
import 'package:shonenx/shared/widgets/app_chip.dart';

import 'reader_theme_info.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String mediaTitle;
  final num? episodeNumber;
  final String? chapterLabel;
  final ReaderThemeInfo themeInfo;
  final double uiRoundness;
  final VoidCallback? onDownloadTap;

  const ReaderAppBar({
    super.key,
    required this.mediaTitle,
    this.episodeNumber,
    this.chapterLabel,
    required this.themeInfo,
    required this.uiRoundness,
    this.onDownloadTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final String chipLabel;
    if (episodeNumber != null) {
      final displayChapter = episodeNumber.toString().contains('.0')
          ? episodeNumber!.toInt().toString()
          : episodeNumber.toString();
      chipLabel = 'Ch. $displayChapter';
    } else {
      chipLabel = chapterLabel ?? 'Offline';
    }

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Container(
                height: 44,
                padding: const EdgeInsets.only(left: 4, right: 6),
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
                        minimumSize: const Size(34, 34),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            (uiRoundness - 4).clamp(4.0, uiRoundness),
                          ),
                        ),
                      ),
                      onPressed: context.pop,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: themeInfo.textColor,
                        size: 17,
                      ),
                      tooltip: context.l10n.commonBack,
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        mediaTitle,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: themeInfo.textColor,
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                    AppChip(
                      label: chipLabel,
                      selected: true,
                      showCheckmark: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppActionButtonGroup(
              outlined: false,
              height: 44,
              backgroundColor: themeInfo.appBarBg,
              foregroundColor: themeInfo.textColor,
              items: [
                if (onDownloadTap != null)
                  AppActionItem(
                    icon: Icons.download_rounded,
                    tooltip: 'Download Chapter',
                    onTap: onDownloadTap!,
                  ),
                AppActionItem(
                  icon: Icons.tune_rounded,
                  tooltip: context.l10n.readerSettings,
                  onTap: () => AppBottomSheet.show(
                    context: context,
                    title: context.l10n.readerSettings,
                    child: const ReaderSettingsContent(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
