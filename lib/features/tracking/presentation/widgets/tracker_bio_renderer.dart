import 'package:material_ui/material_ui.dart';
import 'package:flutter_md/flutter_md.dart';
import 'package:shonenx/features/tracking/utils/tracker_bio_parser.dart';
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

    return MarkdownWidget(
      markdown: Markdown.fromString(parsedBio),
      theme: MarkdownThemeData(
        textStyle:
            theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ) ??
            TextStyle(color: cs.onSurfaceVariant, height: 1.5),
        quoteStyle: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
          fontStyle: FontStyle.italic,
          height: 1.5,
        ),
        surfaceColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
        dividerColor: cs.outlineVariant.withValues(alpha: 0.3),
        linkColor: cs.primary,
        linkStyle: theme.textTheme.bodyMedium?.copyWith(
          color: cs.primary,
          decoration: TextDecoration.underline,
        ),
        onLinkTap: (title, url) {
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        },
        imageResolver: const MarkdownProviderImageResolver().call,
      ),
    );
  }
}
