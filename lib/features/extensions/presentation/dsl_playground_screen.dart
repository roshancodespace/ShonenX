import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/extensions/data/dsa_templates.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_provider_service.dart';
import 'package:shonenx/source_engine/dsl_engine/step_registry.dart';

enum ConsoleTab { output, profiler, context }

enum DslMode { anime, manga, tracker }

class JSONHighlightingController extends TextEditingController {
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final spans = <TextSpan>[];
    final text = this.text;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pattern = RegExp(
      r'("[^"]*"\s*:)|("[^"]*")|\b(true|false|null)\b|\b([0-9\.]+)\b|([\{\}\[\]:,])',
      multiLine: true,
    );

    int lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      final matchedText = match.group(0)!;
      Color? color;
      FontWeight? weight;

      if (match.group(1) != null) {
        color = isDark ? Colors.tealAccent.shade200 : Colors.teal.shade700;
        weight = FontWeight.w600;
      } else if (match.group(2) != null) {
        color = isDark
            ? Colors.orangeAccent.shade200
            : Colors.deepOrange.shade700;
      } else if (match.group(3) != null) {
        color = isDark ? Colors.purpleAccent.shade200 : Colors.purple.shade700;
        weight = FontWeight.w600;
      } else if (match.group(4) != null) {
        color = isDark ? Colors.blueAccent.shade200 : Colors.blue.shade700;
      } else if (match.group(5) != null) {
        color = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
      }

      spans.add(
        TextSpan(
          text: matchedText,
          style: TextStyle(color: color, fontWeight: weight),
        ),
      );
      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }
    return TextSpan(style: style, children: spans);
  }
}

class DSLPlaygroundScreen extends ConsumerStatefulWidget {
  const DSLPlaygroundScreen({super.key});

  @override
  ConsumerState<DSLPlaygroundScreen> createState() =>
      _DSLPlaygroundScreenState();
}

class _DSLPlaygroundScreenState extends ConsumerState<DSLPlaygroundScreen> {
  final JSONHighlightingController _editorController =
      JSONHighlightingController();

  // Cache variable values so they don't reset when switching methods
  final Map<String, String> _variableCache = {
    'query': 'One Piece',
    'page': '1',
    'id': '/anime/one-piece',
    'animeId': '/anime/one-piece',
    'mangaId': '/manga/one-piece',
    'episodeId': '1000',
    'chapterId': '1000',
    'serverId': 'server_1',
    'accessToken': 'YOUR_TOKEN',
  };

  // Only the controllers currently needed by the selected method
  final Map<String, TextEditingController> _activeVariablesControllers = {};

  DslMode _activeMode = DslMode.anime;
  String _selectedMethod = 'search';
  bool _isRunning = false;
  String? _validationError;
  String? _executionTime;

  dynamic _finalResult;
  List<StepExecutionDetail> _executionSteps = [];
  ExecutionContext? _finalContext;
  StepExecutionDetail? _selectedStepDetail;

  ConsoleTab _activeTab = ConsoleTab.output;

  List<String> get _currentMethods {
    switch (_activeMode) {
      case DslMode.anime:
        return [
          'search',
          'trending',
          'details',
          'episodes',
          'servers',
          'sources',
        ];
      case DslMode.manga:
        return ['search', 'trending', 'details', 'chapters', 'pages'];
      case DslMode.tracker:
        return ['fetchProfile', 'searchMedia'];
    }
  }

  @override
  void initState() {
    super.initState();
    _setMode(DslMode.anime);
  }

  @override
  void dispose() {
    _editorController.dispose();
    _disposeActiveVariables();
    super.dispose();
  }

  void _disposeActiveVariables() {
    for (var c in _activeVariablesControllers.values) {
      c.dispose();
    }
    _activeVariablesControllers.clear();
  }

  void _setMode(DslMode mode) {
    setState(() {
      _activeMode = mode;

      switch (mode) {
        case DslMode.anime:
          _editorController.text = DslTemplates.anime;
          break;
        case DslMode.manga:
          _editorController.text = DslTemplates.manga;
          break;
        case DslMode.tracker:
          _editorController.text = DslTemplates.tracker;
          break;
      }

      if (!_currentMethods.contains(_selectedMethod)) {
        _selectedMethod = _currentMethods.first;
      }

      _validateJson(_editorController.text);
    });
  }

  void _validateJson(String text) {
    if (text.trim().isEmpty) {
      setState(() => _validationError = 'JSON cannot be empty');
      return;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        setState(() => _validationError = 'Root must be a JSON object');
        return;
      }
      if (decoded['id'] == null || decoded['id'].toString().isEmpty) {
        setState(() => _validationError = 'Missing "id" field');
        return;
      }
      setState(() {
        _validationError = null;
        _extractRequiredVariables(decoded);
      });
    } catch (e) {
      setState(() => _validationError = e.toString());
    }
  }

  // Magic function that extracts exactly what variables the current method demands
  void _extractRequiredVariables(Map<dynamic, dynamic> decodedJson) {
    try {
      final methods = decodedJson['methods'];
      if (methods == null || methods[_selectedMethod] == null) return;

      final steps = methods[_selectedMethod]['steps'] as List?;
      if (steps == null) return;

      Set<String> requiredVars = {};
      Set<String> stepOutputs = {'item', 'lastOutput', 'baseUrl'}; // Built-ins

      for (var step in steps) {
        if (step is Map) {
          if (step['output'] != null) {
            stepOutputs.add(step['output'].toString());
          }
          if (step['itemVar'] != null) {
            stepOutputs.add(step['itemVar'].toString());
          }

          final stepStr = jsonEncode(step);
          // Regex finds {{varName}} but ignores functions like {{attr(...)}}
          final matches = RegExp(
            r'\{\{\s*([a-zA-Z0-9_]+)(?!\s*\()',
          ).allMatches(stepStr);
          for (final m in matches) {
            final varName = m.group(1);
            if (varName != null) requiredVars.add(varName);
          }
        }
      }

      requiredVars.removeAll(stepOutputs);

      // Save old values to cache before rebuilding
      _activeVariablesControllers.forEach((key, controller) {
        _variableCache[key] = controller.text;
      });

      _disposeActiveVariables();

      for (var v in requiredVars) {
        _activeVariablesControllers[v] = TextEditingController(
          text: _variableCache[v] ?? '',
        );
        // Listener to keep cache updated while typing
        _activeVariablesControllers[v]!.addListener(() {
          _variableCache[v] = _activeVariablesControllers[v]!.text;
        });
      }
    } catch (_) {}
  }

  void _formatJson() {
    try {
      final decoded = jsonDecode(_editorController.text);
      final formatted = const JsonEncoder.withIndent('  ').convert(decoded);
      _editorController.text = formatted;
      _validateJson(formatted);
    } catch (_) {}
  }

  Future<void> _saveProvider() async {
    _formatJson();
    if (_validationError != null) return;
    try {
      final decoded = Map<String, dynamic>.from(
        jsonDecode(_editorController.text),
      );
      final id = decoded['id'].toString();
      await ref.read(dslProvidersProvider.notifier).saveProvider(id, decoded);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Saved successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
      }
    }
  }

  Future<void> _runMethod() async {
    if (_validationError != null) return;
    setState(() {
      _isRunning = true;
      _finalResult = null;
      _executionSteps = [];
      _finalContext = null;
      _selectedStepDetail = null;
      _executionTime = null;
      _activeTab = ConsoleTab.output;
    });

    final stopwatch = Stopwatch()..start();
    try {
      final runtime = ref.read(dslRuntimeProvider);
      final providerDef = Map<String, dynamic>.from(
        jsonDecode(_editorController.text),
      );

      final args = <String, dynamic>{};
      for (final entry in _activeVariablesControllers.entries) {
        args[entry.key] = entry.value.text;
      }

      final initialVariables = Map<String, dynamic>.from(args);
      initialVariables['baseUrl'] = providerDef['baseUrl'];

      final context = ExecutionContext(initialVariables: initialVariables);
      final methods = providerDef['methods'];
      if (methods is! Map || methods[_selectedMethod] == null) {
        throw Exception('Method "$_selectedMethod" is not defined.');
      }

      final stepsRaw = methods[_selectedMethod]['steps'];
      final steps = (stepsRaw as List)
          .map((s) => Map<String, dynamic>.from(s as Map))
          .toList();

      dynamic result;
      try {
        await runtime.executePipeline(steps, context);
        result = context.lastOutput;
      } on DSLReturnSignal catch (e) {
        result = e.value;
      }

      stopwatch.stop();
      setState(() {
        _finalResult = result;
        _executionSteps = context.executionLog;
        _finalContext = context;
        _executionTime = '${stopwatch.elapsedMilliseconds}ms';
        if (context.executionLog.any((s) => s.error != null)) {
          _activeTab = ConsoleTab.profiler;
        }
      });
    } catch (e) {
      stopwatch.stop();
      setState(() {
        _finalResult = 'Error: $e';
        _executionTime = '${stopwatch.elapsedMilliseconds}ms';
      });
    } finally {
      setState(() => _isRunning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppScaffold(
      title: 'DSL Playground',
      actions: [
        IconButton(
          icon: const Icon(Icons.format_align_left, size: 20),
          onPressed: _formatJson,
        ),
        IconButton(
          icon: const Icon(Icons.save, size: 20),
          onPressed: _saveProvider,
        ),
      ],
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 5, child: _buildEditorPane(cs, textTheme)),
                VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withOpacity(0.3),
                ),
                Expanded(flex: 5, child: _buildRunnerPane(cs, textTheme)),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(flex: 1, child: _buildEditorPane(cs, textTheme)),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.outlineVariant.withOpacity(0.3),
                ),
                Expanded(flex: 1, child: _buildRunnerPane(cs, textTheme)),
              ],
            );
          }
        },
      ),
    );
  }

  // LEFT: EDITOR PANE
  Widget _buildEditorPane(ColorScheme cs, TextTheme textTheme) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SegmentedButton<DslMode>(
                  segments: const [
                    ButtonSegment(value: DslMode.anime, label: Text('Anime')),
                    ButtonSegment(value: DslMode.manga, label: Text('Manga')),
                    ButtonSegment(
                      value: DslMode.tracker,
                      label: Text('Tracker'),
                    ),
                  ],
                  selected: {_activeMode},
                  onSelectionChanged: (set) => _setMode(set.first),
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    textStyle: textTheme.labelMedium,
                    backgroundColor: Colors.transparent,
                  ),
                ),
                const Spacer(),
                if (_validationError != null)
                  const Icon(Icons.error, color: Colors.red, size: 18),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),
          Expanded(
            child: TextField(
              controller: _editorController,
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                height: 1.4,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(16),
              ),
              onChanged: _validateJson,
            ),
          ),
        ],
      ),
    );
  }

  // RIGHT: RUNNER PANE
  Widget _buildRunnerPane(ColorScheme cs, TextTheme textTheme) {
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Method:',
                      style: textTheme.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMethod,
                        isDense: true,
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                        dropdownColor: cs.surface,
                        items: _currentMethods
                            .map(
                              (m) => DropdownMenuItem(value: m, child: Text(m)),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedMethod = val;
                              _validateJson(
                                _editorController.text,
                              ); // Trigger variable re-calc
                            });
                          }
                        },
                      ),
                    ),
                    const Spacer(),
                    if (_executionTime != null)
                      Text(
                        _executionTime!,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.green,
                        ),
                      ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 28,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          side: BorderSide(color: cs.primary.withOpacity(0.5)),
                        ),
                        onPressed: _isRunning || _validationError != null
                            ? null
                            : _runMethod,
                        icon: _isRunning
                            ? SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.primary,
                                ),
                              )
                            : Icon(
                                Icons.play_arrow,
                                size: 16,
                                color: cs.primary,
                              ),
                        label: Text('Run', style: TextStyle(color: cs.primary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // DYNAMIC VARIABLES
                if (_activeVariablesControllers.isEmpty)
                  Text(
                    'No input variables required for this method.',
                    style: textTheme.bodySmall?.copyWith(color: cs.outline),
                  )
                else
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    children: _activeVariablesControllers.entries.map((entry) {
                      return Row(
                        children: [
                          Text(
                            '${entry.key}: ',
                            style: textTheme.labelMedium?.copyWith(
                              color: cs.primary,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: entry.value,
                              style: textTheme.bodyMedium?.copyWith(
                                fontFamily: 'monospace',
                              ),
                              decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                border: UnderlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),

          Row(
            children: [
              _buildTab(ConsoleTab.output, 'Output', cs, textTheme),
              _buildTab(ConsoleTab.profiler, 'Profiler', cs, textTheme),
              _buildTab(ConsoleTab.context, 'Context', cs, textTheme),
            ],
          ),

          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.3)),

          Expanded(child: _buildActiveTabContent(cs, textTheme)),
        ],
      ),
    );
  }

  Widget _buildTab(
    ConsoleTab tab,
    String label,
    ColorScheme cs,
    TextTheme textTheme,
  ) {
    final isActive = _activeTab == tab;
    return InkWell(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? cs.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: textTheme.labelMedium?.copyWith(
            color: isActive ? cs.primary : cs.onSurfaceVariant,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(ColorScheme cs, TextTheme textTheme) {
    if (_finalContext == null && !_isRunning) {
      return Center(
        child: Text(
          "Ready.",
          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
      );
    }
    if (_isRunning) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_activeTab) {
      case ConsoleTab.output:
        return _buildCodeViewer(_finalResult, cs, textTheme);
      case ConsoleTab.profiler:
        return _buildProfilerTab(cs, textTheme);
      case ConsoleTab.context:
        return _buildContextTab(cs, textTheme);
    }
  }

  Widget _buildProfilerTab(ColorScheme cs, TextTheme textTheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: ListView.builder(
            itemCount: _executionSteps.length,
            itemBuilder: (context, index) {
              final detail = _executionSteps[index];
              final isSelected = _selectedStepDetail == detail;
              final isError = detail.error != null;

              return InkWell(
                onTap: () => setState(() => _selectedStepDetail = detail),
                child: Container(
                  color: isSelected
                      ? cs.primary.withOpacity(0.1)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isError ? Icons.close : Icons.check,
                        color: isError ? Colors.red : Colors.green,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${index + 1}. ${detail.stepType}',
                          style: textTheme.bodySmall?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Text(
                        '${detail.duration.inMilliseconds}ms',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        VerticalDivider(width: 1, color: cs.outlineVariant.withOpacity(0.3)),
        Expanded(
          flex: 3,
          child: _selectedStepDetail == null
              ? const SizedBox()
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    Text(
                      'Input',
                      style: textTheme.labelSmall?.copyWith(color: cs.primary),
                    ),
                    _buildCodeViewer(
                      _selectedStepDetail!.input,
                      cs,
                      textTheme,
                      maxHeight: 150,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Output',
                      style: textTheme.labelSmall?.copyWith(color: cs.primary),
                    ),
                    _buildCodeViewer(
                      _selectedStepDetail!.output,
                      cs,
                      textTheme,
                      maxHeight: 200,
                    ),
                    if (_selectedStepDetail!.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Error',
                        style: textTheme.labelSmall?.copyWith(
                          color: Colors.red,
                        ),
                      ),
                      Text(
                        _selectedStepDetail!.error!,
                        style: textTheme.bodySmall?.copyWith(color: Colors.red),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildContextTab(ColorScheme cs, TextTheme textTheme) {
    if (_finalContext == null) return const SizedBox();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'Variables',
          style: textTheme.labelSmall?.copyWith(color: cs.primary),
        ),
        _buildCodeViewer(_finalContext!.variables, cs, textTheme),
        if (_finalContext!.lastResponse != null) ...[
          const SizedBox(height: 16),
          Text(
            'Last Response (${_finalContext!.lastResponse!.statusCode})',
            style: textTheme.labelSmall?.copyWith(color: cs.primary),
          ),
          _buildCodeViewer(
            _finalContext!.lastResponse!.body.length > 2000
                ? '${_finalContext!.lastResponse!.body.substring(0, 2000)}...\n[Truncated]'
                : _finalContext!.lastResponse!.body,
            cs,
            textTheme,
          ),
        ],
      ],
    );
  }

  Widget _buildCodeViewer(
    dynamic data,
    ColorScheme cs,
    TextTheme textTheme, {
    double? maxHeight,
  }) {
    String text = '';
    try {
      text = data is String
          ? data
          : const JsonEncoder.withIndent('  ').convert(data);
    } catch (_) {
      text = data.toString();
    }

    return Container(
      constraints: maxHeight != null
          ? BoxConstraints(maxHeight: maxHeight)
          : null,
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      child: SelectableText(
        text,
        style: textTheme.bodySmall?.copyWith(
          fontFamily: 'monospace',
          color: cs.onSurface,
        ),
      ),
    );
  }
}
