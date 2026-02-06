import 'dart:convert';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/themes/dracula.dart';
import 'package:flutter_highlight/themes/github.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/dart.dart';
import 'package:highlight/languages/json.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shonenx/core/anilist/services/anilist_service_provider.dart';
import 'package:shonenx/core_mangayomi/models/source.dart';
import 'package:shonenx/core_mangayomi/models/manga.dart';
import 'package:shonenx/features/settings/services/playground_service.dart';
import 'package:shonenx/main.dart';

enum ConsolePlacement { bottom, right }

class ExtensionPlaygroundScreen extends ConsumerStatefulWidget {
  final Source? source;
  const ExtensionPlaygroundScreen({super.key, this.source});

  @override
  ConsumerState<ExtensionPlaygroundScreen> createState() =>
      _ExtensionPlaygroundScreenState();
}

class _ExtensionPlaygroundScreenState
    extends ConsumerState<ExtensionPlaygroundScreen> {
  // Code Editor
  late final CodeController _codeController;

  // Console Output
  late final CodeController _consoleController;

  // Metadata Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _baseUrlController;
  late final TextEditingController _langController;
  late final TextEditingController _apiUrlController;
  late final TextEditingController _iconUrlController;
  late final TextEditingController _versionController;

  // Reactive State
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<bool> _isConsoleExpandedNotifier = ValueNotifier(true);
  final ValueNotifier<double> _consoleHeightNotifier = ValueNotifier(200);
  final ValueNotifier<double> _consoleWidthNotifier = ValueNotifier(300);

  // Normal State
  bool _isForShonenx = true;
  int _selectedActivity = 0; // 0: Configuration, 1: Run
  PlaygroundService? _playgroundService;
  String? _lastSourceCode;

  final double _fontSize = 13.0;
  String _selectedThemeKey = 'Monokai Sublime';
  final String _selectedConsoleThemeKey = 'Dracula';
  ConsolePlacement _consolePlacement = ConsolePlacement.bottom;
  SourceCodeLanguage _selectedLanguage = SourceCodeLanguage.javascript;

  static const double _minConsoleHeight = 38;
  static const double _maxConsoleHeight = 500;
  static const double _minConsoleWidth = 200;
  static const double _maxConsoleWidth = 600;

  static final Map<String, Map<String, TextStyle>> _themes = {
    'Monokai Sublime': monokaiSublimeTheme,
    'VS 2015': vs2015Theme,
    'Dracula': draculaTheme,
    'GitHub (Light)': githubTheme,
  };

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _selectedLanguage =
        widget.source?.sourceCodeLanguage ?? SourceCodeLanguage.javascript;
    final defaultCode = _selectedLanguage == SourceCodeLanguage.javascript
        ? _defaultCode
        : _defaultDartCode;

    _codeController = CodeController(
      text: widget.source?.sourceCode ?? defaultCode,
      language: _selectedLanguage == SourceCodeLanguage.javascript
          ? javascript
          : dart,
    );

    _consoleController = CodeController(
      text: 'Console output will appear here...',
      language: json,
    );

    _nameController = TextEditingController(
      text: widget.source?.name ?? 'My Extension',
    );
    _baseUrlController = TextEditingController(
      text: widget.source?.baseUrl ?? 'https://example.com',
    );
    _langController = TextEditingController(text: widget.source?.lang ?? 'en');
    _apiUrlController = TextEditingController(
      text: widget.source?.apiUrl ?? '',
    );
    _iconUrlController = TextEditingController(
      text: widget.source?.iconUrl ?? '',
    );
    _versionController = TextEditingController(
      text: widget.source?.version ?? '0.0.1',
    );
    _isForShonenx = widget.source?.isForShonenx ?? _isForShonenx;
  }

  @override
  void dispose() {
    _codeController.dispose();
    _consoleController.dispose();
    _nameController.dispose();
    _baseUrlController.dispose();
    _langController.dispose();
    _apiUrlController.dispose();
    _iconUrlController.dispose();
    _versionController.dispose();
    _isLoadingNotifier.dispose();
    _isConsoleExpandedNotifier.dispose();
    _consoleHeightNotifier.dispose();
    _consoleWidthNotifier.dispose();
    _playgroundService?.dispose();
    super.dispose();
  }

  void _initServiceIfNeeded() {
    final currentCode = _codeController.text;

    if (_playgroundService != null && _lastSourceCode == currentCode) {
      return;
    }

    _playgroundService?.dispose();
    final source = Source(
      id: widget.source?.id,
      name: _nameController.text,
      baseUrl: _baseUrlController.text,
      lang: _langController.text,
      sourceCode: currentCode,
      apiUrl: _apiUrlController.text,
      iconUrl: _iconUrlController.text,
      isForShonenx: _isForShonenx,
    )..sourceCodeLanguage = _selectedLanguage;
    final anilistService = ref.read(anilistServiceProvider);
    _playgroundService = PlaygroundService(
      source,
      anilistService: anilistService,
    );
    _lastSourceCode = currentCode;
  }

  void _logToConsole(String message, {bool isError = false}) {
    _consoleController.text = message;
    if (!_isConsoleExpandedNotifier.value) {
      _isConsoleExpandedNotifier.value = true;
    }
  }

  Future<void> _runFunction(String functionName, [List<dynamic>? args]) async {
    _isLoadingNotifier.value = true;
    _logToConsole('Running $functionName...');

    try {
      _initServiceIfNeeded();

      dynamic result;
      if (functionName == 'search') {
        if (mounted) {
          final query = await _showInputDialog(
            'Enter Search Query',
            'Search...',
          );
          if (query == null) throw 'Cancelled';
          result = await _playgroundService!.runFunction(functionName, [
            query,
            1,
            [],
          ]);
        }
      } else if (functionName == 'getPopular' ||
          functionName == 'getLatestUpdates') {
        result = await _playgroundService!.runFunction(functionName, [1]);
      } else if ([
        'getDetail',
        'getPageList',
        'getVideoList',
      ].contains(functionName)) {
        if (mounted) {
          final url = await _showInputDialog('Enter URL', 'https://...');
          if (url == null) throw 'Cancelled';
          result = await _playgroundService!.runFunction(functionName, [url]);
        }
      } else if (functionName == 'getSupportedServers') {
        if (mounted) {
          final id = await _showInputDialog('Enter Anime ID', 'ID...');
          if (id != null) {
            final epId = await _showInputDialog('Enter Ep ID', 'ID...');
            if (epId != null) {
              final epNum = await _showInputDialog('Enter Ep Num', 'Num...');
              if (epNum != null) {
                result = await _playgroundService!.runFunction(functionName, [
                  id,
                  epId,
                  epNum,
                ]);
              }
            }
          }
        }
      } else if (functionName == 'getVideos') {
        if (mounted) {
          final id = await _showInputDialog('Enter Anime ID', 'ID...');
          if (id != null) {
            final epId = await _showInputDialog('Enter Ep ID', 'ID...');
            if (epId != null) {
              final srv = await _showInputDialog('Enter Server', 'ID...');
              if (srv != null) {
                final cat = await _showInputDialog('Category', 'Cat...');
                result = await _playgroundService!.runFunction(functionName, [
                  id,
                  epId,
                  srv,
                  cat,
                ]);
              }
            }
          }
        }
      } else {
        result = await _playgroundService!.runFunction(functionName, args);
      }

      if (result is Map || result is List || result is Set) {
        _logToConsole(const JsonEncoder.withIndent('  ').convert(result));
      } else {
        _logToConsole(result.toString());
      }
    } catch (e) {
      if (e == 'Cancelled') {
        _logToConsole('Action Cancelled');
      } else if (mounted) {
        _logToConsole('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        _isLoadingNotifier.value = false;
      }
    }
  }

  Future<String?> _showInputDialog(String title, String hint) async {
    String? value;
    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hint,
            ),
            onSubmitted: (val) {
              value = val;
              Navigator.pop(context);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                value = controller.text;
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    return value;
  }

  Future<void> _saveExtension() async {
    if (_nameController.text.isEmpty || _codeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Code are required')),
      );
      return;
    }

    try {
      final source = Source(
        id: widget.source?.id ?? _nameController.text.hashCode,
        name: _nameController.text,
        baseUrl: _baseUrlController.text,
        lang: _langController.text,
        sourceCode: _codeController.text,
        apiUrl: _apiUrlController.text,
        iconUrl: _iconUrlController.text,
        version: _versionController.text,
        isAdded: true,
        isLocal: true,
        isActive: true,
        itemType: widget.source?.itemType ?? ItemType.anime,
        lastUsed: true,
        isForShonenx: _isForShonenx,
      )..sourceCodeLanguage = _selectedLanguage;

      await isar.writeTxn(() async {
        await isar.sources.put(source);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Extension saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving: $e')));
      }
    }
  }

  void _toggleConsole() {
    _isConsoleExpandedNotifier.value = !_isConsoleExpandedNotifier.value;
    if (_isConsoleExpandedNotifier.value) {
      if (_consolePlacement == ConsolePlacement.bottom &&
          _consoleHeightNotifier.value < _minConsoleHeight) {
        _consoleHeightNotifier.value = 200;
      } else if (_consolePlacement == ConsolePlacement.right &&
          _consoleWidthNotifier.value < _minConsoleWidth) {
        _consoleWidthNotifier.value = 300;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 600;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true):
            _saveExtension,
        const SingleActivator(LogicalKeyboardKey.keyJ, control: true):
            _toggleConsole,
        const SingleActivator(LogicalKeyboardKey.backquote, control: true):
            _toggleConsole,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop) _buildActivityBar(),
                    if (isDesktop)
                      Container(
                        width: 250,
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                        child: _buildSidePanelContent(),
                      ),

                    // Main Layout Logic
                    Expanded(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _isConsoleExpandedNotifier,
                        builder: (context, isExpanded, child) {
                          return _consolePlacement == ConsolePlacement.bottom
                              ? Column(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildEditor(context),
                                    ),
                                    if (isExpanded)
                                      ValueListenableBuilder<double>(
                                        valueListenable: _consoleHeightNotifier,
                                        builder: (context, height, _) =>
                                            SizedBox(
                                              height: height,
                                              child: _buildConsole(context),
                                            ),
                                      ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    Expanded(child: _buildEditor(context)),
                                    if (isExpanded)
                                      ValueListenableBuilder<double>(
                                        valueListenable: _consoleWidthNotifier,
                                        builder: (context, width, _) =>
                                            SizedBox(
                                              width: width,
                                              child: _buildConsole(context),
                                            ),
                                      ),
                                  ],
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusBar(),
            ],
          ),
          bottomNavigationBar: !isDesktop
              ? NavigationBar(
                  selectedIndex: _selectedActivity,
                  onDestinationSelected: (idx) {
                    setState(() => _selectedActivity = idx);
                    showModalBottomSheet(
                      context: context,
                      builder: (ctx) => _buildSidePanelContent(),
                    );
                  },
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.folder_open_rounded),
                      label: 'Configuration',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.play_arrow_rounded),
                      label: 'Run',
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Iconsax.arrow_left_2),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.source != null ? 'Edit Extension' : 'New Extension'),
      actions: [
        IconButton(
          onPressed: _saveExtension,
          icon: const Icon(Icons.save_rounded),
          tooltip: 'Save (Ctrl+S)',
        ),
        ValueListenableBuilder<bool>(
          valueListenable: _isConsoleExpandedNotifier,
          builder: (context, isExpanded, _) {
            return IconButton(
              onPressed: _toggleConsole,
              icon: Icon(isExpanded ? Icons.terminal : Icons.terminal_outlined),
              tooltip: 'Toggle Console (Ctrl+J)',
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusBar() {
    return Container(
      height: 24,
      color: Theme.of(context).colorScheme.primary,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(
            Icons.code_rounded,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          const SizedBox(width: 8),
          Text(
            _selectedLanguage == SourceCodeLanguage.javascript
                ? 'JavaScript'
                : 'Dart',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimary,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
          const Spacer(),
          InkWell(
            onTap: _toggleConsole,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ValueListenableBuilder<bool>(
                valueListenable: _isConsoleExpandedNotifier,
                builder: (context, isExpanded, _) {
                  return Row(
                    children: [
                      Icon(
                        isExpanded
                            ? Icons.splitscreen_rounded
                            : Icons.call_to_action_rounded,
                        size: 12,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Console',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar() {
    return Container(
      width: 50,
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildActivityIcon(Icons.folder_open_rounded, 0, 'Configuration'),
          const SizedBox(height: 10),
          _buildActivityIcon(Icons.play_arrow_rounded, 1, 'Run & Debug'),
          const Spacer(),
          IconButton(
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActivityIcon(IconData icon, int index, String tooltip) {
    final isSelected = _selectedActivity == index;
    return IconButton(
      onPressed: () => setState(() => _selectedActivity = index),
      icon: Icon(
        icon,
        color: isSelected ? Theme.of(context).colorScheme.primary : null,
      ),
      tooltip: tooltip,
    );
  }

  Widget _buildSidePanelContent() {
    if (_selectedActivity == 0) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('METADATA', style: Theme.of(context).textTheme.labelSmall),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('ShonenX Only', style: TextStyle(fontSize: 14)),
            subtitle: const Text(
              'Only available in ShonenX',
              style: TextStyle(fontSize: 12),
            ),
            value: _isForShonenx,
            onChanged: (value) {
              setState(() {
                _isForShonenx = value!;
              });
            },
          ),
          const SizedBox(height: 10),
          _buildSideInput(_nameController, "Name"),
          const SizedBox(height: 8),
          _buildSideInput(_versionController, "Version"),
          const SizedBox(height: 8),
          _buildSideInput(_langController, "Language"),
          const SizedBox(height: 16),
          Text('CONFIGURATION', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          _buildSideInput(_baseUrlController, "Base URL"),
          const SizedBox(height: 8),
          _buildSideInput(_apiUrlController, "API URL"),
          const SizedBox(height: 8),
          _buildSideInput(_iconUrlController, "Icon URL"),
        ],
      );
    } else {
      return ValueListenableBuilder<bool>(
        valueListenable: _isLoadingNotifier,
        builder: (context, isLoading, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('METHODS', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              _buildRunButton(isLoading, 'getPopular', 'Popular'),
              _buildRunButton(isLoading, 'getLatestUpdates', 'Latest'),
              _buildRunButton(isLoading, 'search', 'Search'),
              _buildRunButton(isLoading, 'getDetail', 'Details'),
              _buildRunButton(isLoading, 'getPageList', 'Pages'),
              _buildRunButton(isLoading, 'getVideoList', 'Videos'),
              _buildRunButton(isLoading, 'getSourcePreferences', 'Preferences'),
              const SizedBox(height: 10),
              Text('SHONENX', style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 10),
              _buildRunButton(isLoading, 'getSupportedServers', 'Servers'),
              _buildRunButton(isLoading, 'getVideos', 'Videos'),
            ],
          );
        },
      );
    }
  }

  Widget _buildSideInput(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _buildRunButton(bool isLoading, String funcName, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : () => _runFunction(funcName),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        icon: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.play_arrow_rounded, size: 16),
        label: Text(label),
      ),
    );
  }

  Widget _buildEditor(BuildContext context) {
    return RepaintBoundary(
      child: SafeArea(
        child: CodeTheme(
          data: CodeThemeData(styles: _themes[_selectedThemeKey]!),
          child: SingleChildScrollView(
            child: CodeField(
              controller: _codeController,
              textStyle: TextStyle(
                fontFamily: 'monospace',
                fontSize: _fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleHeader(BuildContext context) {
    return MouseRegion(
      cursor: _consolePlacement == ConsolePlacement.bottom
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _consolePlacement == ConsolePlacement.bottom
            ? (details) {
                double newHeight =
                    _consoleHeightNotifier.value - details.delta.dy;
                _consoleHeightNotifier.value = newHeight.clamp(
                  _minConsoleHeight,
                  _maxConsoleHeight,
                );
              }
            : null,
        onHorizontalDragUpdate: _consolePlacement == ConsolePlacement.right
            ? (details) {
                double newWidth =
                    _consoleWidthNotifier.value - details.delta.dx;
                _consoleWidthNotifier.value = newWidth.clamp(
                  _minConsoleWidth,
                  _maxConsoleWidth,
                );
              }
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 30,
          color: Colors.black26,
          child: Row(
            children: [
              const Text(
                'DEBUG CONSOLE',
                style: TextStyle(color: Colors.white70, fontSize: 11),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.minimize_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                onPressed: () {
                  if (_consolePlacement == ConsolePlacement.bottom) {
                    _consoleHeightNotifier.value = _minConsoleHeight;
                  }
                },
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                onPressed: () => _isConsoleExpandedNotifier.value = false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsole(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: _consolePlacement == ConsolePlacement.bottom
            ? Border(top: BorderSide(color: Theme.of(context).dividerColor))
            : Border(left: BorderSide(color: Theme.of(context).dividerColor)),
        color: const Color(0xFF1E1E1E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConsoleHeader(context),
          Expanded(
            child: RepaintBoundary(
              child: CodeTheme(
                data: CodeThemeData(styles: _themes[_selectedConsoleThemeKey]!),
                child: SingleChildScrollView(
                  child: CodeField(
                    controller: _consoleController,
                    readOnly: true,
                    textStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: _fontSize - 1,
                    ),
                    background: Colors.transparent,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateInternal) {
            return AlertDialog(
              title: const Text('Editor Settings'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Theme'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedThemeKey,
                    isExpanded: true,
                    items: _themes.keys.map((key) {
                      return DropdownMenuItem(value: key, child: Text(key));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateInternal(() => _selectedThemeKey = value);
                        setState(() => _selectedThemeKey = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Console Placement'),
                  const SizedBox(height: 8),
                  DropdownButton<ConsolePlacement>(
                    value: _consolePlacement,
                    isExpanded: true,
                    items: ConsolePlacement.values.map((val) {
                      return DropdownMenuItem(
                        value: val,
                        child: Text(
                          val == ConsolePlacement.bottom ? 'Bottom' : 'Right',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateInternal(() => _consolePlacement = value);
                        setState(() => _consolePlacement = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Language'),
                  const SizedBox(height: 8),
                  DropdownButton<SourceCodeLanguage>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    items: SourceCodeLanguage.values.map((val) {
                      return DropdownMenuItem(
                        value: val,
                        child: Text(val.name.toUpperCase()),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateInternal(() => _selectedLanguage = value);
                        setState(() {
                          _selectedLanguage = value;
                          _codeController.language =
                              value == SourceCodeLanguage.javascript
                              ? javascript
                              : dart;
                          if (_codeController.text == _defaultCode ||
                              _codeController.text == _defaultDartCode) {
                            _codeController.text =
                                value == SourceCodeLanguage.javascript
                                ? _defaultCode
                                : _defaultDartCode;
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  final String _defaultCode = r'''class DefaultExtension extends MProvider {
    constructor() {
      super();
      this.client = new Client();
    }

    // -------------------------
    // ShonenX Specific Methods
    // -------------------------

    // Get supported servers for an episode
    // Returns: List of ServerData objects
    getSupportedServers(animeId, episodeId, episodeNumber) {
        // Example: Fetch servers from source
        return [{
            id: "server-1",
            name: "Server 1",
            isDub: false
        }];
    }

    // Get videos for a server
    // Returns: List of Video objects
    getVideos(animeId, episodeId, serverId, category) {
        // Example: Fetch video URL
        return [{
            url: "https://example.com/video.mp4",
            quality: "1080p",
            originalUrl: "https://example.com/video.mp4",
            headers: {}
        }];
    }

    // -------------------------
    // Core Functions
    // -------------------------

    // Fetch popular anime
    async getPopular(page) {
        return {
            list: [{
                name: "Example Title " + page,
                link: "/anime/" + page,
                imageUrl: "https://via.placeholder.com/150"
            }],
            hasNextPage: true
        };
    }
    
    // Fetch latest updates
    async getLatestUpdates(page) {
         return this.getPopular(page);
    }

    // Search for content
    async search(query, page, filters) {
        return {
            list: [{
                name: "Result for " + query,
                link: "/search/" + query,
                imageUrl: "https://via.placeholder.com/150"
            }],
            hasNextPage: false
        };
    }

    // Get anime details
    async getDetail(url) {
         return {
            name: "Title Details",
            status: 1, // 0: ongoing, 1: complete, 5: unknown
            author: "Author",
            description: "Description from " + url,
            genre: ["Action", "Fantasy"],
            episodes: [{
                name: "Episode 1",
                url: "/episode/1",
                dateUpload: new Date().getTime().toString() // milliseconds
            }]
        };
    }
}
''';

  final String _defaultDartCode = r'''
import 'package:mangayomi/bridge_lib.dart';
import 'dart:convert';

class DefaultExtension extends MProvider {
  DefaultExtension();

  // -------------------------
  // ShonenX Specific Methods
  // -------------------------

  @override
  Future<List<MServer>> getSupportedServers(
      String animeId, String episodeId, String episodeNumber) async {
    // Example: Fetch servers from source
    return [
      MServer(id: "server-1", name: "Server 1", isDub: false),
    ];
  }

  @override
  Future<List<MVideo>> getVideos(
      String animeId, String episodeId, String server, String? category) async {
    // Example: Fetch video URL
    return [
      MVideo(
        "https://example.com/video.mp4",
        "1080p",
        "https://example.com/video.mp4",
      ),
    ];
  }

  // -------------------------
  // Core Functions
  // -------------------------

  @override
  bool get supportsLatest => true;

  @override
  Future<MPages> getPopular(int page) async {
    return MPages([
      MManga(
        name: "Example Title $page",
        link: "/anime/$page",
        imageUrl: "https://via.placeholder.com/150",
      ),
    ], true);
  }

  @override
  Future<MPages> getLatestUpdates(int page) async {
    return getPopular(page);
  }

  @override
  Future<MPages> search(String query, int page, List<dynamic> filters) async {
    return MPages([
      MManga(
        name: "Result for $query",
        link: "/search/$query",
        imageUrl: "https://via.placeholder.com/150",
      ),
    ], false);
  }

  @override
  Future<MManga> getDetail(String url) async {
    return MManga(
      name: "Title Details",
      status: MStatus.ongoing,
      author: "Author",
      description: "Description from $url",
      genre: ["Action", "Fantasy"],
      chapters: [
        MChapter(
          name: "Episode 1",
          url: "/episode/1",
          dateUpload: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ],
    );
  }
}
''';
}
