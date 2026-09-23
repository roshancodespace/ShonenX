import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:shonenx/features/tracking/utils/tracker_bio_parser.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

class TrackerBioRenderer extends StatelessWidget {
  final String bio;

  const TrackerBioRenderer({super.key, required this.bio});

  @override
  Widget build(BuildContext context) {
    if (bio.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final parsedBio = TrackerBioParser.parse(bio);

    return MarkdownBody(
      data: parsedBio,
      selectable: true,
      onTapLink: (text, href, title) {
        if (href != null) {
          launchUrl(Uri.parse(href), mode: LaunchMode.externalApplication);
        }
      },
      imageBuilder: (uri, title, alt) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: uri.toString(),
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => const SizedBox.shrink(),
            ),
          ),
        );
      },
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          height: 1.5,
        ),
        strong: theme.textTheme.titleSmall?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w700,
          height: 1.5,
        ),
        em: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        blockquote: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        blockquoteDecoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withOpacity(0.5),
          border: Border(left: BorderSide(color: cs.primary, width: 4)),
          borderRadius: BorderRadius.circular(4),
        ),
        blockquotePadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              width: 2,
              color: cs.outlineVariant.withOpacity(0.3),
            ),
          ),
        ),
        a: theme.textTheme.bodyMedium?.copyWith(
          color: cs.primary,
          decoration: TextDecoration.underline,
          decorationColor: cs.primary.withOpacity(0.5),
          height: 1.5,
        ),
      ),
    );
  }
}
