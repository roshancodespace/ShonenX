import 'package:anymex_extension_runtime_bridge/anymex_extension_runtime_bridge.dart' as bridge;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shonenx/shared/widgets/app_bottom_sheet.dart';

class AddRepoSheet extends StatefulWidget {
  final bridge.Extension manager;
  final Future<void> Function(String url) onAdd;

  const AddRepoSheet({super.key, required this.manager, required this.onAdd});

  @override
  State<AddRepoSheet> createState() => _AddRepoSheetState();
}

class _AddRepoSheetState extends State<AddRepoSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;
  String? _clipboardText;

  @override
  void initState() {
    super.initState();
    _checkClipboard();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _checkClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final text = data?.text?.trim();
      if (text != null && (text.startsWith('http://') || text.startsWith('https://'))) {
        if (mounted) setState(() => _clipboardText = text);
      }
    } catch (_) {}
  }

  void _submit() async {
    final url = _controller.text.trim();
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      await widget.onAdd(url);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMangayomi = widget.manager.id == 'mangayomi';

    return AppBottomSheet(
      title: isMangayomi ? 'Add Mangayomi Repo' : 'Add Tachiyomi Repo',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Direct JSON Link Required',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isMangayomi
                            ? 'Please provide a direct URL pointing to the index.min.json file.'
                            : 'Please provide a direct URL to the repository index.json file.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Repository URL',
              prefixIcon: const Icon(Icons.link_rounded),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _controller,
                builder: (context, value, _) {
                  return value.text.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear_rounded), onPressed: _controller.clear)
                      : const SizedBox.shrink();
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              helperText: isMangayomi ? 'Format: https://.../index.min.json' : 'Format: https://.../index.json',
            ),
            enabled: !_isLoading,
            autofocus: true,
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 12),
          if (_clipboardText != null && !_isLoading) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  _controller.text = _clipboardText!;
                  _controller.selection = TextSelection.fromPosition(TextPosition(offset: _clipboardText!.length));
                },
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.secondary,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.content_paste_rounded, size: 16),
                label: Text(
                  'Paste copied link: $_clipboardText',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_download_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Add Repository',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
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
