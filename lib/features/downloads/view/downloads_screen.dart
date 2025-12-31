import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';

import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/features/downloads/model/download_status.dart';
import 'package:shonenx/features/downloads/model/download_item.dart';

import 'package:shonenx/features/downloads/view/widgets/download_card.dart';
import 'package:shonenx/features/downloads/view_model/downloads_notifier.dart';
import 'package:shonenx/storage_provider.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsProvider.select((d) => d.downloads));
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Downloads'),
          bottom: TabBar(
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Downloading'),
              Tab(text: 'Completed'),
            ],
            indicatorColor: theme.colorScheme.primary,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        body: TabBarView(
          children: [
            _buildDownloadList(context, downloads),
            _buildDownloadList(
              context,
              downloads
                  .where((d) =>
                      d.state == DownloadStatus.downloading ||
                      d.state == DownloadStatus.paused ||
                      d.state == DownloadStatus.queued)
                  .toList(),
            ),
            _buildDownloadList(
              context,
              downloads
                  .where((d) => d.state == DownloadStatus.downloaded)
                  .toList(),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final path = (await StorageProvider().getDefaultDirectory())!.path;
            AppLogger.d(
                "$path/Offline/One piece/1 - I am gonna be king of the pirates/Auto");

            ref.read(downloadsProvider.notifier).addDownload(DownloadItem(
                  animeTitle: 'One piece',
                  episodeTitle: '1 - I am gonna be king of the pirates',
                  episodeNumber: 1,
                  thumbnail:
                      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSbUFgoWQMHU93hyXCzppyDfhPEcAf76WscJg&s',
                  state: DownloadStatus.downloading,
                  downloadUrl:
                      'https://proxy.animetsu.cc/oppai/pahe/Fw8cARFZQkZuChkMER0eWl4OHkYeEQYWFC1KX1BdSUdbSQNbWA8GEktNIVdXW0EaEUAfB1hQVQQWQEAiBw8HFEpHTElUCghYAEMRRnNVDFBLHUFMT1FbDQxTTBBCcwBbV10MBwEEDF0cVQ',
                  quality: 'Auto',
                  progress: 0,
                  filePath: '$path/Anime Title/1 - Episode Title/Auto',
                  headers: {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                    // 'Referer':
                    //     'https://megacloud.blog/embed-2/v3/e-1/j7cbMWEbkUys?k=1',
                    // 'Origin': 'https://megacloud.blog',
                  },
                ));
          },
          child: const Icon(Iconsax.add),
        ),
      ),
    );
  }

  Widget _buildDownloadList(BuildContext context, List<DownloadItem> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.receive_square,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Downloads',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.5),
                  ),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return DownloadCard(item: items[index]);
      },
    );
  }
}
