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
                      'https://df.netmagcdn.com:2228/hls-playback/619f0387b8b950fc3328082648ad396513324777461e825607c87e90b410cd33289b1f7222d3e5be1feedcd609864be98315b6a58082d74e07062a178073734430761d9207fe7c5e091d6a4e79d125501501f6515396d7141ca1ee9f052fbdc55410739582a4c28c49407a1653feac93b7b681911964cb5a19c408bdf7c3cd81ba23cf4ea4084d419383b509506f006f/index-f3-v1-a1.m3u8',
                  quality: 'Auto',
                  progress: 0,
                  filePath: '$path/Anime Title/1 - Episode Title/Auto',
                  headers: {
                    'User-Agent':
                        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
                    'Referer': 'https://df.netmagcdn.com/',
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
