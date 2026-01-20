import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/models/universal/universal_news.dart';
import 'package:shonenx/features/news/view_model/news_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NewsDetailScreen extends ConsumerStatefulWidget {
  final UniversalNews news;

  const NewsDetailScreen({super.key, required this.news});

  @override
  ConsumerState<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends ConsumerState<NewsDetailScreen> {
  late Future<String?> _detailFuture;

  @override
  void initState() {
    super.initState();
    _detailFuture = ref
        .read(animeNewsNetworkServiceProvider)
        .getDetailedNews(widget.news)
        .then((news) => news?.body);
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not launch $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 400,
            pinned: true,
            stretch: true,
            leading: IconButton.filledTonal(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Iconsax.arrow_left_2),
              style: IconButton.styleFrom(
                backgroundColor: scheme.surface.withOpacity(0.5),
                foregroundColor: scheme.onSurface,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (widget.news.imageUrl != null)
                    CachedNetworkImage(
                      imageUrl: widget.news.imageUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(
                          Iconsax.image,
                          size: 50,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Container(color: scheme.surfaceContainerHighest),

                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          scheme.surface.withOpacity(0.8),
                          scheme.surface,
                        ],
                        stops: const [0, 0.4, 0.8, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Date Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.calendar_1,
                          size: 16,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.news.date ?? 'Unknown Date',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Title
                  Text(
                    widget.news.title ?? 'No Title',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Content
                  FutureBuilder<String?>(
                    future: _detailFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: scheme.primary,
                          ),
                        );
                      }

                      final content = snapshot.data ?? widget.news.body;

                      if (content == null || content.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest.withOpacity(
                              0.5,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Iconsax.info_circle,
                                color: scheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'No content available.',
                                style: TextStyle(color: scheme.secondary),
                              ),
                            ],
                          ),
                        );
                      }

                      return Text(
                        content,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 16,
                          height: 1.6,
                          color: scheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  // Action Button
                  if (widget.news.url != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton.tonalIcon(
                          onPressed: () => _launchUrl(widget.news.url!),
                          icon: const Icon(Iconsax.global),
                          label: const Text('Read Full Article on ANN'),
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
