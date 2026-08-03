import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/features/discord/models/discord_rpc_custom_settings.dart';
import 'package:shonenx/features/discord/models/discord_user.dart';

enum RpcPreviewTab { idle, watching, reading }

class DiscordRpcPreviewCard extends StatefulWidget {
  final DiscordUser? user;
  final DiscordRpcCustomSettings settings;

  const DiscordRpcPreviewCard({super.key, this.user, required this.settings});

  @override
  State<DiscordRpcPreviewCard> createState() => _DiscordRpcPreviewCardState();
}

class _DiscordRpcPreviewCardState extends State<DiscordRpcPreviewCard> {
  RpcPreviewTab _activeTab = RpcPreviewTab.idle;

  static const String _appIconNetworkUrl =
      'https://raw.githubusercontent.com/roshancodespace/ShonenX/refs/heads/main/assets/images/app_icon.png';
  static const String _onePiecePreviewImage =
      'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT8--VpUm_3ewaKmioaFpTjAUA4z46Qbb-4GQ&s';

  @override
  Widget build(BuildContext context) {
    String headerText = 'Playing';
    String mainTitle = 'ShonenX';
    String subTitle1 = widget.settings.idleActivity;
    String subTitle2 = widget.settings.idleDetails;
    String startTime = '12:00';
    String endTime = '20:00';
    double progressRatio = 0.6;
    String? coverUrl;
    bool isPlayingState = true;

    switch (_activeTab) {
      case RpcPreviewTab.idle:
        headerText = 'Playing';
        mainTitle = 'ShonenX';
        subTitle1 = widget.settings.idleActivity;
        subTitle2 = widget.settings.idleDetails;
        coverUrl = null;
        isPlayingState = true;
        break;

      case RpcPreviewTab.watching:
        headerText = 'Watching ShonenX';
        mainTitle = 'One Piece';
        subTitle1 = 'Episode 7 – Orewa Kaizoku Ou Ni Naru!';
        subTitle2 = 'ShonenX';
        startTime = '12:00';
        endTime = '20:00';
        progressRatio = 0.6;
        coverUrl = _onePiecePreviewImage;
        isPlayingState = false;
        break;

      case RpcPreviewTab.reading:
        headerText = 'Reading ShonenX';
        mainTitle = 'One Piece';
        subTitle1 = 'Chapter 236 • Page 14/20';
        subTitle2 = 'ShonenX Reader';
        startTime = '12:00';
        endTime = '--:--';
        progressRatio = 0.7;
        coverUrl = _onePiecePreviewImage;
        isPlayingState = false;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          child: Row(
            children: [
              const Text(
                'LIVE DISCORD PREVIEW',
                style: TextStyle(
                  color: Color(0xFF949BA4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              _buildSegmentButton(RpcPreviewTab.idle, 'Idle'),
              _buildSegmentButton(RpcPreviewTab.watching, 'Watching'),
              _buildSegmentButton(RpcPreviewTab.reading, 'Reading'),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F22),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    headerText,
                    style: const TextStyle(
                      color: Color(0xFF949BA4),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Icon(
                    Icons.more_horiz_rounded,
                    color: Color(0xFFB5BAC1),
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            isPlayingState ? 18 : 10,
                          ),
                          child: Container(
                            color: isPlayingState
                                ? Colors.black
                                : Colors.transparent,
                            child: CachedNetworkImage(
                              imageUrl: coverUrl ?? _appIconNetworkUrl,
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 72,
                                height: 72,
                                color: const Color(0xFF2B2D31),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 72,
                                height: 72,
                                color: const Color(
                                  0xFF5865F2,
                                ).withValues(alpha: 0.25),
                                child: const Center(
                                  child: Icon(
                                    Icons.discord,
                                    color: Color(0xFF5865F2),
                                    size: 34,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (coverUrl != null)
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E1F22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF1E1F22),
                                width: 3.5,
                              ),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: _appIconNetworkUrl,
                                width: 26,
                                height: 26,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mainTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$subTitle1\n',
                                style: const TextStyle(
                                  color: Color(0xFFDBDEE1),
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: subTitle2,
                                style: const TextStyle(
                                  color: Color(0xFF949BA4),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(height: 1.15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (isPlayingState) ...[
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(
                                Icons.sports_esports_rounded,
                                color: Color(0xFF23A55A),
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                '01:58',
                                style: TextStyle(
                                  color: Color(0xFF23A55A),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ] else if (_activeTab == RpcPreviewTab.watching) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                startTime,
                                style: const TextStyle(
                                  color: Color(0xFFDBDEE1),
                                  fontSize: 11,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      height: 3,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF4E5058),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progressRatio,
                                      child: Container(
                                        height: 3,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFDBDEE1),
                                          borderRadius: BorderRadius.circular(
                                            2,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                endTime,
                                style: const TextStyle(
                                  color: Color(0xFFDBDEE1),
                                  fontSize: 11,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentButton(RpcPreviewTab tab, String label) {
    final isSelected = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        margin: const EdgeInsets.only(left: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5865F2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF949BA4),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
