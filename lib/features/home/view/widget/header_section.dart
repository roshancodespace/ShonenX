// lib/features/home/widget/header_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/services/auth_provider_enum.dart';
import 'package:shonenx/features/auth/view_model/auth_notifier.dart';
import 'package:shonenx/features/home/view/widget/action_panel.dart';
import 'package:shonenx/features/home/view/widget/discover_card.dart';
import 'package:shonenx/features/home/view/widget/user_profile_card.dart';

class HeaderSection extends ConsumerWidget {
  final bool isDesktop;
  const HeaderSection({super.key, required this.isDesktop});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).padding.top),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
                child: UserProfileCard(
                    user: authState.activePlatform == AuthPlatform.anilist
                        ? authState.anilistUser
                        : authState.malUser)),
            const SizedBox(width: 10),
            ActionPanel(isDesktop: isDesktop),
          ],
        ),
        const SizedBox(height: 10),
        DiscoverCard(),
        const SizedBox(height: 10),
      ],
    );
  }
}
