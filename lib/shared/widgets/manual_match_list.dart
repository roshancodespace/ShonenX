import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/shared/models/unified_media.dart';

class ManualMatchList extends StatelessWidget {
  final List<UnifiedMedia>? results;
  final bool isLoading;
  final void Function(UnifiedMedia result) onMatchSelected;

  const ManualMatchList({
    super.key,
    required this.results,
    required this.isLoading,
    required this.onMatchSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (results != null && results!.isEmpty && !isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('No matches found')),
      );
    }

    if (results != null && results!.isNotEmpty) {
      return ListView.separated(
        shrinkWrap: true,
        itemCount: results!.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final result = results![index];

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: result.cover != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: result.cover!,
                      width: 40,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  )
                : const SizedBox(
                    width: 40,
                    height: 60,
                    child: Icon(Icons.movie_creation_outlined),
                  ),
            title: Text(
              result.title.availableTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: FilledButton.tonal(
              onPressed: () => onMatchSelected(result),
              child: const Text('Match'),
            ),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }
}
