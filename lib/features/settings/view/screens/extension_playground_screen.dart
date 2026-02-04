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
import 'package:highlight/languages/json.dart';
import 'package:iconsax/iconsax.dart';
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
  late CodeController _codeController;

  // Console Output
  late CodeController _consoleController;

  // Metadata Controllers
  late TextEditingController _nameController;
  late TextEditingController _baseUrlController;
  late TextEditingController _langController;
  late TextEditingController _apiUrlController;
  late TextEditingController _iconUrlController;
  late TextEditingController _versionController;

  // State
  bool _isLoading = false;
  bool _isConsoleExpanded = true;
  int _selectedActivity = 0; // 0: Configuration, 1: Run
  PlaygroundService? _playgroundService;
  String? _lastSourceCode;

  double _consoleHeight = 200;
  double _consoleWidth = 300;
  double _fontSize = 13.0;
  String _selectedThemeKey = 'Monokai Sublime';
  String _selectedConsoleThemeKey = 'Dracula';
  ConsolePlacement _consolePlacement = ConsolePlacement.bottom;

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
    // Initialize Code Editor
    _codeController = CodeController(
      text: widget.source?.sourceCode ?? _defaultCode,
      language: javascript,
    );

    // Initialize Console
    _consoleController = CodeController(
      text: 'Console output will appear here...',
      language: json,
    );

    // Initialize Metadata
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
    )..sourceCodeLanguage = SourceCodeLanguage.javascript;
    _playgroundService = PlaygroundService(source);
    _lastSourceCode = currentCode;
  }

  void _logToConsole(String message, {bool isError = false}) {
    setState(() {
      _consoleController.text = message;
      _isConsoleExpanded = true;
    });
  }

  void _runFunction(String functionName, [List<dynamic>? args]) async {
    setState(() {
      _isLoading = true;
      _logToConsole('Running $functionName...');
    });

    try {
      _initServiceIfNeeded();

      dynamic result;
      if (functionName == 'search') {
        if (mounted) {
          final query = await _showInputDialog(
            'Enter Search Query',
            'Search...',
          );
          if (query != null) {
            result = await _playgroundService!.runFunction(functionName, [
              query,
              1,
              [],
            ]);
          } else {
            setState(() => _isLoading = false);
            _logToConsole('Action Cancelled');
            return;
          }
        }
      } else if (functionName == 'getPopular' ||
          functionName == 'getLatestUpdates') {
        result = await _playgroundService!.runFunction(functionName, [1]);
      } else if (functionName == 'getDetail' ||
          functionName == 'getPageList' ||
          functionName == 'getVideoList') {
        if (mounted) {
          final url = await _showInputDialog('Enter URL', 'https://...');
          if (url != null) {
            result = await _playgroundService!.runFunction(functionName, [url]);
          } else {
            setState(() => _isLoading = false);
            _logToConsole('Action Cancelled');
            return;
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
      if (mounted) {
        _logToConsole('Error: $e', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
      )..sourceCodeLanguage = SourceCodeLanguage.javascript;

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
    setState(() {
      _isConsoleExpanded = !_isConsoleExpanded;
      if (_isConsoleExpanded) {
        if (_consolePlacement == ConsolePlacement.bottom &&
            _consoleHeight < _minConsoleHeight) {
          _consoleHeight = 200;
        } else if (_consolePlacement == ConsolePlacement.right &&
            _consoleWidth < _minConsoleWidth) {
          _consoleWidth = 300;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Responsive Layout
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
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Iconsax.arrow_left_2),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              widget.source != null ? 'Edit Extension' : 'New Extension',
            ),
            actions: [
              IconButton(
                onPressed: _saveExtension,
                icon: const Icon(Icons.save_rounded),
                tooltip: 'Save (Ctrl+S)',
              ),
              IconButton(
                onPressed: _toggleConsole,
                icon: Icon(
                  _isConsoleExpanded ? Icons.terminal : Icons.terminal_outlined,
                ),
                tooltip: 'Toggle Console (Ctrl+J)',
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: Row(
                  children: [
                    // Activity Bar (Desktop Only)
                    if (isDesktop) _buildActivityBar(),

                    // Sidebar Panel (Desktop Only)
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

                    // Main Content Area
                    Expanded(
                      child: _consolePlacement == ConsolePlacement.bottom
                          ? Column(
                              children: [
                                Expanded(flex: 3, child: _buildEditor()),
                                // Console
                                if (_isConsoleExpanded) _buildConsole(),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(child: _buildEditor()),
                                // Console
                                if (_isConsoleExpanded) _buildConsole(),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
              _buildStatusBar(),
            ],
          ),
          // Mobile Bottom Bar
          bottomNavigationBar: !isDesktop
              ? NavigationBar(
                  selectedIndex: _selectedActivity,
                  onDestinationSelected: (idx) {
                    setState(() => _selectedActivity = idx);
                    // Show bottom sheet for panel content on mobile
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
            'JavaScript',
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
              child: Row(
                children: [
                  Icon(
                    _isConsoleExpanded
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
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('METHODS', style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          _buildRunButton('getPopular', 'Popular'),
          _buildRunButton('getLatestUpdates', 'Latest'),
          _buildRunButton('search', 'Search'),
          _buildRunButton('getDetail', 'Details'),
          _buildRunButton('getPageList', 'Pages'),
          _buildRunButton('getVideoList', 'Videos'),
          _buildRunButton('getSourcePreferences', 'Preferences'),
        ],
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

  Widget _buildRunButton(String funcName, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : () => _runFunction(funcName),
        style: ElevatedButton.styleFrom(
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        icon: const Icon(Icons.play_arrow_rounded, size: 16),
        label: Text(label),
      ),
    );
  }

  Widget _buildEditor() {
    return SafeArea(
      child: SingleChildScrollView(
        child: CodeTheme(
          data: CodeThemeData(styles: _themes[_selectedThemeKey]!),
          child: CodeField(
            controller: _codeController,
            textStyle: TextStyle(fontFamily: 'monospace', fontSize: _fontSize),
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleHeader() {
    return MouseRegion(
      cursor: _consolePlacement == ConsolePlacement.bottom
          ? SystemMouseCursors.resizeUpDown
          : SystemMouseCursors.resizeLeftRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: _consolePlacement == ConsolePlacement.bottom
            ? (details) {
                setState(() {
                  _consoleHeight -= details.delta.dy;
                  _consoleHeight = _consoleHeight.clamp(
                    _minConsoleHeight,
                    _maxConsoleHeight,
                  );
                });
              }
            : null,
        onHorizontalDragUpdate: _consolePlacement == ConsolePlacement.right
            ? (details) {
                setState(() {
                  _consoleWidth -= details.delta.dx;
                  _consoleWidth = _consoleWidth.clamp(
                    _minConsoleWidth,
                    _maxConsoleWidth,
                  );
                });
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
                icon: Icon(
                  _consoleHeight == _minConsoleHeight
                      ? Icons.maximize_rounded
                      : Icons.minimize_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() {
                  if (_consolePlacement == ConsolePlacement.bottom) {
                    _consoleHeight = _consoleHeight == _minConsoleHeight
                        ? _maxConsoleHeight * 0.6
                        : _minConsoleHeight;
                  }
                }),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white70,
                ),
                onPressed: () => setState(() {
                  if (_consolePlacement == ConsolePlacement.bottom) {
                    _isConsoleExpanded = false;
                  }
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsoleBody() {
    return CodeTheme(
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
    );
  }

  Widget _buildConsole() {
    return Container(
      height: _consolePlacement == ConsolePlacement.bottom
          ? _consoleHeight
          : null,
      width: _consolePlacement == ConsolePlacement.right ? _consoleWidth : null,
      decoration: BoxDecoration(
        border: _consolePlacement == ConsolePlacement.bottom
            ? Border(top: BorderSide(color: Theme.of(context).dividerColor))
            : Border(left: BorderSide(color: Theme.of(context).dividerColor)),
        color: const Color(0xFF1E1E1E),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildConsoleHeader(),
          Expanded(child: _buildConsoleBody()),
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
                  const Text('Console Theme'),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedConsoleThemeKey,
                    isExpanded: true,
                    items: _themes.keys.map((key) {
                      return DropdownMenuItem(value: key, child: Text(key));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateInternal(
                          () => _selectedConsoleThemeKey = value,
                        );
                        setState(() => _selectedConsoleThemeKey = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Font Size'),
                  Slider(
                    value: _fontSize,
                    min: 10,
                    max: 30,
                    divisions: 20,
                    label: _fontSize.round().toString(),
                    onChanged: (value) {
                      setStateInternal(() => _fontSize = value);
                      setState(() => _fontSize = value);
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

  // Clean Template Code
  final String _defaultCode = r'''class DefaultExtension extends MProvider {
    /* 
     * Core Functions
     * Modify these to parse your desired website.
     */

    // Fetch popular manga/anime
    getPopular(page) {
        return {
            list: [{
                name: "Example Title " + page,
                link: "/manga/" + page,
                imageUrl: "https://via.placeholder.com/150"
            }],
            hasNextPage: true
        };
    }
    
    // Fetch latest updates
    getLatestUpdates(page) {
         return this.getPopular(page);
    }

    // Search for content
    async search(query, page, filters) {
        // Example: const res = await this.client.get(this.source.baseUrl + "/search?q=" + query);
        return {
            list: [{
                name: "Result for " + query,
                link: "/search/" + query,
                imageUrl: "https://via.placeholder.com/150"
            }],
            hasNextPage: false
        };
    }

    // Get content details (chapters/episodes)
    async getDetail(url) {
         return {
            name: "Title Details",
            status: 1, // 0: ongoing, 1: complete, 5: unknown
            author: "Author",
            description: "Description from " + url,
            genre: ["Action", "Fantasy"],
            chapters: [{
                name: "Chapter 1",
                url: url + "/1",
                dateUpload: new Date().getTime().toString(),
                scanlator: "Group"
            }]
        };
    }

    // Get pages (for Manga)
    getPageList(url) {
        return [
            { url: "https://via.placeholder.com/800x1200" },
        ];
    }
    
    // Get video links (for Anime)
    getVideoList(url) {
        return [{
            url: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            originalUrl: "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4",
            quality: "720p"
        }];
    }
}
''';
}
