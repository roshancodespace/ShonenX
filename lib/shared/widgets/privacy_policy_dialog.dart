import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shonenx/features/onboarding/onboarding_provider.dart';
import 'package:shonenx/shared/widgets/app_button.dart';
import 'package:shonenx/shared/widgets/app_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

const String kPrivacyPolicyUrl =
    'https://github.com/roshancodespace/ShonenX/blob/main/docs/privacy-policy.md';

Future<void> launchPrivacyPolicyUrl() async {
  final uri = Uri.parse(kPrivacyPolicyUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

Future<void> showPrivacyPolicyDialog(BuildContext context, WidgetRef ref) async {
  final cs = Theme.of(context).colorScheme;
  await AppDialog.show<void>(
    context: context,
    title: 'Privacy Policy',
    icon: Icon(Icons.privacy_tip_rounded, color: cs.primary, size: 28),
    barrierDismissible: false,
    showCloseButton: false,
    maxWidth: 480,
    child: PopScope(
      canPop: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ShonenX is open-source, ad-free, and built with a local-first architecture:',
            style: TextStyle(
              fontSize: 13.5,
              color: cs.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          const _PolicyPoint(
            icon: Icons.block_rounded,
            text:
                'No ads, no behavioral tracking, and no developer telemetry servers.',
          ),
          const SizedBox(height: 8),
          const _PolicyPoint(
            icon: Icons.devices_rounded,
            text:
                'Library, watch/read history, preferences, and OAuth tokens stay locally on your device.',
          ),
          const SizedBox(height: 8),
          const _PolicyPoint(
            icon: Icons.sync_lock_rounded,
            text:
                'External requests go directly from your device only to trackers or extensions you choose to use.',
          ),
          const SizedBox(height: 14),
          AppButton(
            label: 'Read Full Privacy Policy',
            icon: Icons.open_in_new_rounded,
            variant: AppButtonVariant.text,
            size: AppButtonSize.small,
            onPressed: launchPrivacyPolicyUrl,
          ),
        ],
      ),
    ),
    actions: [
      AppButton(
        label: 'Accept & Continue',
        icon: Icons.check_rounded,
        variant: AppButtonVariant.primary,
        size: AppButtonSize.medium,
        isExpanded: true,
        onPressed: () async {
          await ref.read(privacyPolicyAcceptedProvider.notifier).accept();
          if (context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
    ],
  );
}

class _PolicyPoint extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PolicyPoint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: cs.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              color: cs.onSurface,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

