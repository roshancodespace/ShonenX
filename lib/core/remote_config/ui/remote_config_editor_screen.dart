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

  // App Config
  bool _downloadsEnabled = true;
  bool _applicationEnabled = true;
  final _minimumVersion = TextEditingController(text: 'v2.0.0');

  // Announcements (App)
  final _appAnnId = TextEditingController(text: '1');
  bool _appAnnEnabled = true;
  final _appAnnTitle = TextEditingController(text: 'Test Announcement');
  final _appAnnMessage = TextEditingController();
  final _appAnnType = TextEditingController(text: 'info');

  // Announcements (Website)
  final _webAnnId = TextEditingController(text: '1');
  bool _webAnnEnabled = true;
  final _webAnnTitle = TextEditingController(text: 'Website Announcement');
  final _webAnnMessage = TextEditingController();
  final _webAnnType = TextEditingController(text: 'warning');

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
      _downloadsEnabled = currentConfig.downloadsEnabled;
      _applicationEnabled = currentConfig.applicationEnabled;
      _minimumVersion.text = currentConfig.minimumVersion;

      if (currentConfig.announcements.app.isNotEmpty) {
        final ann = currentConfig.announcements.app.first;
        _appAnnId.text = ann.id.toString();
        _appAnnEnabled = ann.enabled;
        _appAnnTitle.text = ann.title;
        _appAnnMessage.text = ann.message;
        _appAnnType.text = ann.type;
      }

      if (currentConfig.announcements.website.isNotEmpty) {
        final ann = currentConfig.announcements.website.first;
        _webAnnId.text = ann.id.toString();
        _webAnnEnabled = ann.enabled;
        _webAnnTitle.text = ann.title;
        _webAnnMessage.text = ann.message;
        _webAnnType.text = ann.type;
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
    _minimumVersion.dispose();
    _appAnnId.dispose();
    _appAnnTitle.dispose();
    _appAnnMessage.dispose();
    _appAnnType.dispose();
    _webAnnId.dispose();
    _webAnnTitle.dispose();
    _webAnnMessage.dispose();
    _webAnnType.dispose();
    super.dispose();
  }

  void _bumpVersion(TextEditingController controller, String type) {
    final text = controller.text;
    final regex = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(.*)$');
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
      controller.text = 'v$major.$minor.$patch$suffix';
    } else {
      // Fallback if not semver
      if (type == 'patch') {
        controller.text = '$text-patched';
      }
    }
  }

  void _generateAndShowJson() {
    final Map<String, SourceConfig> sources = {};
    _sourceDisabledMap.forEach((key, value) {
      if (value) {
        sources[key] = SourceConfig(
          disabled: true,
          message: 'Disabled by admin',
        );
      }
    });

    final newConfig = RemoteConfig(
      downloadsEnabled: _downloadsEnabled,
      applicationEnabled: _applicationEnabled,
      minimumVersion: _minimumVersion.text.trim(),
      announcements: AnnouncementsConfig(
        app: [
          Announcement(
            id: int.tryParse(_appAnnId.text) ?? 1,
            enabled: _appAnnEnabled,
            title: _appAnnTitle.text.trim(),
            message: _appAnnMessage.text.trim(),
            type: _appAnnType.text.trim(),
          ),
        ],
        website: [
          Announcement(
            id: int.tryParse(_webAnnId.text) ?? 1,
            enabled: _webAnnEnabled,
            title: _webAnnTitle.text.trim(),
            message: _webAnnMessage.text.trim(),
            type: _webAnnType.text.trim(),
          ),
        ],
      ),
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
          Tab(text: 'App Config'),
          Tab(text: 'Announcements'),
          Tab(text: 'Sources'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAppConfigTab(),
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

  Widget _buildAppConfigTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
        _buildSectionTitle('Global Flags'),
        _buildCleanSwitch(
          title: 'Application Enabled',
          value: _applicationEnabled,
          originalValue: _originalConfig?.applicationEnabled ?? true,
          onChanged: (v) => setState(() => _applicationEnabled = v),
          isDestructive: true,
        ),
        _buildCleanSwitch(
          title: 'Downloads Enabled',
          value: _downloadsEnabled,
          originalValue: _originalConfig?.downloadsEnabled ?? true,
          onChanged: (v) => setState(() => _downloadsEnabled = v),
        ),
        const SizedBox(height: 32),
        _buildSectionTitle('Force Update Policy'),
        _CleanTextField(
          label: 'Minimum Version',
          controller: _minimumVersion,
          originalValue: _originalConfig?.minimumVersion ?? 'v2.0.0',
          onBump: () => _confirmBumpVersion(_minimumVersion),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 100, top: 16),
      children: [
        _buildSectionTitle('App Announcement'),
        _buildCleanSwitch(
          title: 'Enabled',
          value: _appAnnEnabled,
          originalValue:
              _originalConfig?.announcements.app.firstOrNull?.enabled ?? true,
          onChanged: (v) => setState(() => _appAnnEnabled = v),
        ),
        _CleanTextField(
          label: 'ID',
          controller: _appAnnId,
          originalValue:
              _originalConfig?.announcements.app.firstOrNull?.id.toString() ??
              '1',
          keyboardType: TextInputType.number,
        ),
        _CleanTextField(
          label: 'Title',
          controller: _appAnnTitle,
          originalValue:
              _originalConfig?.announcements.app.firstOrNull?.title ?? '',
        ),
        _CleanTextField(
          label: 'Type (info, warning)',
          controller: _appAnnType,
          originalValue:
              _originalConfig?.announcements.app.firstOrNull?.type ?? 'info',
        ),
        _CleanTextField(
          label: 'Message',
          controller: _appAnnMessage,
          originalValue:
              _originalConfig?.announcements.app.firstOrNull?.message ?? '',
          maxLines: 4,
        ),

        const SizedBox(height: 32),
        _buildSectionTitle('Website Announcement'),
        _buildCleanSwitch(
          title: 'Enabled',
          value: _webAnnEnabled,
          originalValue:
              _originalConfig?.announcements.website.firstOrNull?.enabled ??
              true,
          onChanged: (v) => setState(() => _webAnnEnabled = v),
        ),
        _CleanTextField(
          label: 'ID',
          controller: _webAnnId,
          originalValue:
              _originalConfig?.announcements.website.firstOrNull?.id
                  .toString() ??
              '1',
          keyboardType: TextInputType.number,
        ),
        _CleanTextField(
          label: 'Title',
          controller: _webAnnTitle,
          originalValue:
              _originalConfig?.announcements.website.firstOrNull?.title ?? '',
        ),
        _CleanTextField(
          label: 'Type (info, warning)',
          controller: _webAnnType,
          originalValue:
              _originalConfig?.announcements.website.firstOrNull?.type ??
              'warning',
        ),
        _CleanTextField(
          label: 'Message',
          controller: _webAnnMessage,
          originalValue:
              _originalConfig?.announcements.website.firstOrNull?.message ?? '',
          maxLines: 4,
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
                    : (isDestructive && !value
                          ? theme.colorScheme.error
                          : null),
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
