import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/core/remote_config/models/remote_config.dart';
import 'package:shonenx/core/remote_config/providers/remote_config_provider.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/providers/inbuilt_sources_provider.dart';

class RemoteConfigEditorScreen extends ConsumerStatefulWidget {
  const RemoteConfigEditorScreen({super.key});

  @override
  ConsumerState<RemoteConfigEditorScreen> createState() =>
      _RemoteConfigEditorScreenState();
}

class _RemoteConfigEditorScreenState
    extends ConsumerState<RemoteConfigEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Stable
  final _stableUpdateId = TextEditingController(text: '0');
  final _stableVersion = TextEditingController(text: '1.0.0');
  bool _stableForceUpdate = false;
  final _stableMessage = TextEditingController();
  final _stableApk = TextEditingController();

  // Test
  final _testUpdateId = TextEditingController(text: '0');
  final _testVersion = TextEditingController(text: '1.0.0-beta');
  bool _testForceUpdate = false;
  final _testMessage = TextEditingController();
  final _testApk = TextEditingController();

  // Announcement
  final _announcementId = TextEditingController();
  final _announcementMessage = TextEditingController();

  // Sources
  final Map<String, bool> _sourceDisabledMap = {};

  // Original Config reference for diffing
  RemoteConfig? _originalConfig;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentConfig();
    });
  }

  void _loadCurrentConfig() {
    final currentConfig = ref.read(remoteConfigProvider);
    _originalConfig = currentConfig;

    if (currentConfig != null) {
      if (currentConfig.stable != null) {
        _stableUpdateId.text = currentConfig.stable!.updateId.toString();
        _stableVersion.text = currentConfig.stable!.version;
        _stableForceUpdate = currentConfig.stable!.forceUpdate;
        _stableMessage.text = currentConfig.stable!.message;
        _stableApk.text = currentConfig.stable!.apk;
      }
      if (currentConfig.test != null) {
        _testUpdateId.text = currentConfig.test!.updateId.toString();
        _testVersion.text = currentConfig.test!.version;
        _testForceUpdate = currentConfig.test!.forceUpdate;
        _testMessage.text = currentConfig.test!.message;
        _testApk.text = currentConfig.test!.apk;
      }
      if (currentConfig.announcement != null) {
        _announcementId.text = currentConfig.announcement!.id;
        _announcementMessage.text = currentConfig.announcement!.message;
      } else {
        _announcementId.text = '';
        _announcementMessage.text = '';
      }
      _sourceDisabledMap.clear();
      for (final entry in currentConfig.sources.entries) {
        _sourceDisabledMap[entry.key] = entry.value.disabled;
      }
      setState(() {});
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _stableUpdateId.dispose();
    _stableVersion.dispose();
    _stableMessage.dispose();
    _stableApk.dispose();
    _testUpdateId.dispose();
    _testVersion.dispose();
    _testMessage.dispose();
    _testApk.dispose();
    _announcementId.dispose();
    _announcementMessage.dispose();
    super.dispose();
  }

  void _bumpVersion(TextEditingController controller, String type) {
    final text = controller.text;
    final regex = RegExp(r'^(\d+)\.(\d+)\.(\d+)(.*)$');
    final match = regex.firstMatch(text);
    if (match != null) {
      int major = int.parse(match.group(1)!);
      int minor = int.parse(match.group(2)!);
      int patch = int.parse(match.group(3)!);
      final suffix = match.group(4) ?? '';

      if (type == 'major') {
        major++;
        minor = 0;
        patch = 0;
      } else if (type == 'minor') {
        minor++;
        patch = 0;
      } else if (type == 'patch') {
        patch++;
      }
      controller.text = '$major.$minor.$patch$suffix';
    } else {
      // Fallback if not semver
      if (type == 'patch') {
        controller.text = '$text-patched';
      }
    }
  }

  void _generateAndShowJson() {
    final currentConfig = ref.read(remoteConfigProvider);

    final Map<String, SourceConfig> sources = {};
    _sourceDisabledMap.forEach((key, value) {
      if (value) {
        sources[key] = SourceConfig(
          disabled: true,
          message: 'Disabled by admin',
        );
      }
    });

    // Auto-manage announcement ID
    String? announcementId;
    final messageText = _announcementMessage.text.trim();
    if (messageText.isNotEmpty) {
      if (currentConfig?.announcement?.message == messageText) {
        // Unchanged, keep old ID
        announcementId =
            currentConfig?.announcement?.id ??
            'msg-${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Changed, generate new ID so users see it again
        announcementId = 'msg-${DateTime.now().millisecondsSinceEpoch}';
      }
    }

    final newConfig = RemoteConfig(
      stable: ChannelConfig(
        updateId: int.tryParse(_stableUpdateId.text) ?? 0,
        version: _stableVersion.text.trim(),
        forceUpdate: _stableForceUpdate,
        message: _stableMessage.text.trim(),
        apk: _stableApk.text.trim(),
      ),
      test: ChannelConfig(
        updateId: int.tryParse(_testUpdateId.text) ?? 0,
        version: _testVersion.text.trim(),
        forceUpdate: _testForceUpdate,
        message: _testMessage.text.trim(),
        apk: _testApk.text.trim(),
      ),
      announcement: announcementId != null
          ? Announcement(id: announcementId, message: messageText)
          : null,
      sources: sources,
    );

    final jsonString = const JsonEncoder.withIndent(
      '  ',
    ).convert(newConfig.toJson());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Generated Configuration'),
          content: SingleChildScrollView(child: SelectableText(jsonString)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: jsonString));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard')),
                  );
                }
              },
              icon: const Icon(Icons.copy),
              label: const Text('Copy'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Config Editor',
      actions: [
        IconButton(
          icon: const Icon(Icons.restore),
          tooltip: 'Reset to Live Config',
          onPressed: () {
            _loadCurrentConfig();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reset to live config')),
            );
          },
        ),
      ],
      barBottom: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: const [
          Tab(text: 'Updates'),
          Tab(text: 'Announcements'),
          Tab(text: 'Sources'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUpdatesTab(),
          _buildAnnouncementsTab(),
          _buildSourcesTab(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FilledButton.icon(
            onPressed: _generateAndShowJson,
            icon: const Icon(Icons.data_object),
            label: const Text('Generate JSON'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmBumpUpdateId(TextEditingController controller) async {
    final current = int.tryParse(controller.text) ?? 0;
    final next = current + 1;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Increment'),
        content: Text('Increment Update ID from $current to $next?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Increment'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      controller.text = next.toString();
    }
  }

  Future<void> _confirmBumpVersion(TextEditingController controller) async {
    final text = controller.text;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bump Version'),
        content: Text(
          'Current version: $text\nWhich component would you like to bump?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'patch'),
            child: const Text('Patch'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'minor'),
            child: const Text('Minor'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, 'major'),
            child: const Text('Major'),
          ),
        ],
      ),
    );

    if (result != null) {
      _bumpVersion(controller, result);
    }
  }

  Widget _buildUpdatesTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
        _buildSectionTitle('Stable Release'),
        _CleanTextField(
          label: 'Update ID',
          controller: _stableUpdateId,
          originalValue: _originalConfig?.stable?.updateId.toString() ?? '0',
          keyboardType: TextInputType.number,
          onBump: () => _confirmBumpUpdateId(_stableUpdateId),
        ),
        _CleanTextField(
          label: 'Version',
          controller: _stableVersion,
          originalValue: _originalConfig?.stable?.version ?? '1.0.0',
          onBump: () => _confirmBumpVersion(_stableVersion),
        ),
        _CleanTextField(
          label: 'APK URL',
          controller: _stableApk,
          originalValue: _originalConfig?.stable?.apk ?? '',
        ),
        _CleanTextField(
          label: 'Changelog',
          controller: _stableMessage,
          originalValue: _originalConfig?.stable?.message ?? '',
          maxLines: 4,
        ),
        _buildCleanSwitch(
          title: 'Force Update',
          value: _stableForceUpdate,
          originalValue: _originalConfig?.stable?.forceUpdate ?? false,
          onChanged: (v) => setState(() => _stableForceUpdate = v),
        ),

        const SizedBox(height: 32),
        _buildSectionTitle('Test / Beta Release'),
        _CleanTextField(
          label: 'Update ID',
          controller: _testUpdateId,
          originalValue: _originalConfig?.test?.updateId.toString() ?? '0',
          keyboardType: TextInputType.number,
          onBump: () => _confirmBumpUpdateId(_testUpdateId),
        ),
        _CleanTextField(
          label: 'Version',
          controller: _testVersion,
          originalValue: _originalConfig?.test?.version ?? '1.0.0-beta',
          onBump: () => _confirmBumpVersion(_testVersion),
        ),
        _CleanTextField(
          label: 'APK URL',
          controller: _testApk,
          originalValue: _originalConfig?.test?.apk ?? '',
        ),
        _CleanTextField(
          label: 'Changelog',
          controller: _testMessage,
          originalValue: _originalConfig?.test?.message ?? '',
          maxLines: 4,
        ),
        _buildCleanSwitch(
          title: 'Force Update',
          value: _testForceUpdate,
          originalValue: _originalConfig?.test?.forceUpdate ?? false,
          onChanged: (v) => setState(() => _testForceUpdate = v),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
        _buildSectionTitle('Global Announcement'),
        _CleanTextField(
          label: 'Message',
          controller: _announcementMessage,
          originalValue: _originalConfig?.announcement?.message ?? '',
          maxLines: 6,
        ),
      ],
    );
  }

  Widget _buildSourcesTab() {
    final availableSources = ref.watch(inbuiltAnimeSourcesProvider);
    final Set<String> allSourceIds = {
      ...availableSources.map((e) => e.sourceInfo.id),
      ..._sourceDisabledMap.keys,
    };

    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
        _buildSectionTitle('Sources Kill Switch'),
        ...allSourceIds.map((id) {
          final isDisabled = _sourceDisabledMap[id] ?? false;
          final original = _originalConfig?.sources[id]?.disabled ?? false;
          return _buildCleanSwitch(
            title: id,
            value: isDisabled,
            originalValue: original,
            isDestructive: true,
            onChanged: (v) => setState(() => _sourceDisabledMap[id] = v),
          );
        }),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildCleanSwitch({
    required String title,
    required bool value,
    required bool originalValue,
    required ValueChanged<bool> onChanged,
    bool isDestructive = false,
  }) {
    final isModified = value != originalValue;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: isModified ? FontWeight.bold : FontWeight.w500,
                color: isModified
                    ? theme.colorScheme.primary
                    : (isDestructive && value ? theme.colorScheme.error : null),
              ),
            ),
            if (isModified) ...[
              const SizedBox(width: 6),
              Icon(Icons.circle, size: 6, color: theme.colorScheme.primary),
            ],
          ],
        ),
        value: value,
        activeColor: isDestructive ? theme.colorScheme.error : null,
        onChanged: onChanged,
      ),
    );
  }
}

class _CleanTextField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String originalValue;
  final int maxLines;
  final TextInputType? keyboardType;
  final VoidCallback? onBump;

  const _CleanTextField({
    required this.label,
    required this.controller,
    required this.originalValue,
    this.maxLines = 1,
    this.keyboardType,
    this.onBump,
  });

  @override
  State<_CleanTextField> createState() => _CleanTextFieldState();
}

class _CleanTextFieldState extends State<_CleanTextField> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isModified =
            widget.controller.text.trim() != widget.originalValue.trim();

        final labelWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: isModified ? FontWeight.bold : FontWeight.w500,
                color: isModified ? theme.colorScheme.primary : null,
              ),
            ),
            if (isModified) ...[
              const SizedBox(width: 6),
              Icon(Icons.circle, size: 6, color: theme.colorScheme.primary),
            ],
          ],
        );

        return Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.maxLines > 1 ? 12 : 4,
          ),
          child: widget.maxLines > 1
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    labelWidget,
                    const SizedBox(height: 8),
                    TextField(
                      controller: widget.controller,
                      maxLines: widget.maxLines,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(flex: 2, child: labelWidget),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: widget.controller,
                        keyboardType: widget.keyboardType,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (widget.onBump != null)
                      IconButton(
                        icon: const Icon(Icons.unfold_more),
                        visualDensity: VisualDensity.compact,
                        onPressed: widget.onBump,
                        tooltip: 'Bump / Increment',
                      ),
                  ],
                ),
        );
      },
    );
  }
}
