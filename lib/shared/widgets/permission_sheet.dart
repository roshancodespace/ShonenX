import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class PermissionSheet extends StatefulWidget {
  final Permission permission;
  final String title;
  final String description;
  final String rationale;

  const PermissionSheet({
    super.key,
    required this.permission,
    required this.title,
    required this.description,
    required this.rationale,
  });

  static Future<bool> show(
    BuildContext context, {
    required Permission permission,
    required String title,
    required String description,
    required String rationale,
  }) async {
    final result = await AppBottomSheet.show<bool>(
      context: context,
      title: title,
      child: PermissionSheet(
        permission: permission,
        title: title,
        description: description,
        rationale: rationale,
      ),
    );
    return result ?? false;
  }

  @override
  State<PermissionSheet> createState() => _PermissionSheetState();
}

class _PermissionSheetState extends State<PermissionSheet>
    with WidgetsBindingObserver {
  PermissionStatus? _status;
  bool _hasPopped = false;

  bool get _isMobile => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkStatus(autoPop: true);
  }

  void _popWithResult(bool result) {
    if (!mounted || _hasPopped) return;
    _hasPopped = true;
    Navigator.of(context).pop(result);
  }

  Future<void> _checkStatus({bool autoPop = false}) async {
    if (!_isMobile) {
      setState(() => _status = PermissionStatus.denied);
      return;
    }
    final status = await widget.permission.status;
    if (mounted) {
      setState(() => _status = status);
      if (autoPop && status.isGranted) _popWithResult(true);
    }
  }

  Future<void> _requestPermission() async {
    if (!_isMobile) {
      _popWithResult(true);
      return;
    }
    if (_status?.isPermanentlyDenied == true) {
      await openAppSettings();
      return;
    }
    final status = await widget.permission.request();
    if (mounted) {
      setState(() => _status = status);
      if (status.isGranted) _popWithResult(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_status == null) {
      return const SizedBox(
        height: 250,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.secondaryContainer,
            child: Icon(
              Icons.shield_outlined,
              size: 30,
              color: cs.onSecondaryContainer,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Why we need this',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.rationale,
                  style: TextStyle(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: _requestPermission,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: const StadiumBorder(),
            ),
            child: Text(
              _status!.isPermanentlyDenied ? 'Open Settings' : 'Allow Access',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: () => _popWithResult(false),
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Not now',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
