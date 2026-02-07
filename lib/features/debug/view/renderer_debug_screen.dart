import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shonenx/core/utils/app_logger.dart';

class RendererDebugScreen extends StatefulWidget {
  const RendererDebugScreen({super.key});

  @override
  State<RendererDebugScreen> createState() => _RendererDebugScreenState();
}

class _RendererDebugScreenState extends State<RendererDebugScreen> {
  Map<String, dynamic> debugInfo = {};
  bool isTesting = false;
  List<String> testLog = [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && !Platform.isIOS && !Platform.isMacOS) {
      _collectDebugInfo();
    }
  }

  Future<void> _collectDebugInfo() async {
    final info = <String, dynamic>{};

    info['platform'] = Platform.operatingSystem;
    info['version'] = Platform.version;
    info['isWeb'] = kIsWeb;
    info['dartVersion'] = Platform.version;

    final env = Platform.environment;
    info['impellerEnv'] = env['FLUTTER_ENGINE_IMPELER_ENABLE'] ?? 'not set';
    info['disableImpeller'] = env['DISABLE_IMPELER'] ?? 'not set';

    try {
      final renderer = ui.PlatformDispatcher.instance;
      info['viewCount'] = renderer.views.length;
      info['pixelRatio'] = renderer.views.firstOrNull?.devicePixelRatio ?? 1.0;
    } catch (e) {
      info['rendererError'] = e.toString();
    }

    if (Platform.isLinux) {
      info['gdkBackend'] = env['GDK_BACKEND'] ?? 'auto';
      info['display'] = env['DISPLAY'] ?? 'not set';
      info['waylandDisplay'] = env['WAYLAND_DISPLAY'] ?? 'not set';
      info['sessionType'] = env['XDG_SESSION_TYPE'] ?? 'not set';
      info['desktop'] = env['XDG_CURRENT_DESKTOP'] ?? 'not set';
      info['mesaGL'] = env['MESA_GL_VERSION_OVERRIDE'] ?? 'not set';
      info['libglSoftware'] = env['LIBGL_ALWAYS_SOFTWARE'] ?? 'not set';

      try {
        final glx = await Process.run('glxinfo', ['-B']);
        if (glx.exitCode == 0) {
          final output = glx.stdout.toString();
          info['glxInfo'] = output.split('\n').take(8).join('\n');

          final vendorMatch = RegExp(r'Vendor:\s+(.+)').firstMatch(output);
          final deviceMatch = RegExp(r'Device:\s+(.+)').firstMatch(output);
          final versionMatch = RegExp(r'Version:\s+(.+)').firstMatch(output);
          final directMatch = RegExp(
            r'direct rendering:\s+(.+)',
          ).firstMatch(output);

          info['gpuVendor'] = vendorMatch?.group(1)?.trim() ?? 'unknown';
          info['gpuDevice'] = deviceMatch?.group(1)?.trim() ?? 'unknown';
          info['glVersion'] = versionMatch?.group(1)?.trim() ?? 'unknown';
          info['directRendering'] = directMatch?.group(1)?.trim() ?? 'unknown';
        }
      } catch (_) {}

      try {
        final vulkan = await Process.run('vulkaninfo', ['--summary']);
        if (vulkan.exitCode == 0) {
          final output = vulkan.stdout.toString();
          final devices = output.split('GPU').length - 1;
          info['vulkanDevices'] = devices;
          info['vulkanAvailable'] = devices > 0;
        }
      } catch (_) {
        info['vulkanAvailable'] = false;
      }
    }

    try {
      final flutter = await Process.run('flutter', ['--version']);
      if (flutter.exitCode == 0) {
        final lines = flutter.stdout.toString().split('\n');
        info['flutterVersion'] = lines.firstWhere(
          (line) => line.contains('Flutter'),
          orElse: () => 'unknown',
        );
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        debugInfo = info;
      });
    }
  }

  Future<void> _runComprehensiveTests() async {
    setState(() {
      isTesting = true;
      testLog.clear();
    });

    final tests = [
      if (Platform.isLinux) ...[
        _testOpenGL(),
        _testVulkan(),
        _testDisplayServer(),
        _testWindowManager(),
      ],
      _testFlutterEngine(),
      _testPerformance(),
    ];

    for (final test in tests) {
      try {
        await test;
      } catch (e) {
        testLog.add('❌ Test failed: $e');
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    if (mounted) {
      setState(() {
        isTesting = false;
      });
    }
  }

  Future<void> _testOpenGL() async {
    testLog.add('🧪 Testing OpenGL...');

    try {
      final glxgears = Process.start('glxgears', []);
      await Future.delayed(const Duration(seconds: 2));
      (await glxgears).kill();
      testLog.add('✅ OpenGL: glxgears ran successfully');
    } catch (e) {
      testLog.add('❌ OpenGL: $e');
    }

    try {
      final glxinfo = await Process.run('glxinfo', ['-t']);
      if (glxinfo.exitCode == 0) {
        final extCount = glxinfo.stdout
            .toString()
            .split('\n')
            .where((line) => line.contains('GL_'))
            .length;
        testLog.add('📊 OpenGL extensions: $extCount');
      }
    } catch (_) {}
  }

  Future<void> _testVulkan() async {
    testLog.add('🧪 Testing Vulkan...');

    try {
      final vulkan = await Process.run('vulkaninfo', ['--summary']);
      if (vulkan.exitCode == 0) {
        final output = vulkan.stdout.toString();
        final hasVulkan = output.contains('GPU');
        testLog.add(
          hasVulkan ? '✅ Vulkan: Available' : '⚠️ Vulkan: No GPUs found',
        );

        if (hasVulkan) {
          final gpus = RegExp(r'GPU\d+').allMatches(output).length;
          testLog.add('📊 Vulkan GPUs: $gpus');
        }
      }
    } catch (e) {
      testLog.add('❌ Vulkan: $e');
    }
  }

  Future<void> _testDisplayServer() async {
    testLog.add('🧪 Testing Display Server...');

    final env = Platform.environment;
    final display = env['DISPLAY'];
    final wayland = env['WAYLAND_DISPLAY'];
    final session = env['XDG_SESSION_TYPE'];

    testLog.add('📊 DISPLAY: $display');
    testLog.add('📊 WAYLAND_DISPLAY: $wayland');
    testLog.add('📊 XDG_SESSION_TYPE: $session');

    if (wayland != null && wayland.isNotEmpty) {
      testLog.add('✅ Display: Wayland detected');
    } else if (display != null && display.isNotEmpty) {
      testLog.add('✅ Display: X11 detected');
    } else {
      testLog.add('⚠️ Display: No display server detected');
    }
  }

  Future<void> _testWindowManager() async {
    testLog.add('🧪 Testing Window Manager...');

    try {
      final wm = await Process.run('wmctrl', ['-m']);
      if (wm.exitCode == 0) {
        final lines = wm.stdout.toString().split('\n');
        final nameLine = lines.firstWhere(
          (line) => line.startsWith('Name:'),
          orElse: () => 'Name: unknown',
        );
        testLog.add('📊 WM: ${nameLine.replaceFirst('Name:', '').trim()}');
      }
    } catch (_) {
      testLog.add('⚠️ WM: wmctrl not available');
    }

    final desktop = Platform.environment['XDG_CURRENT_DESKTOP'];
    if (desktop != null && desktop.isNotEmpty) {
      testLog.add('📊 Desktop: $desktop');
    }
  }

  Future<void> _testFlutterEngine() async {
    testLog.add('🧪 Testing Flutter Engine...');

    final impeller = Platform.environment['FLUTTER_ENGINE_IMPELER_ENABLE'];
    testLog.add(
      impeller == 'false'
          ? '✅ Impeller: Disabled (via env var)'
          : '⚠️ Impeller: May be enabled',
    );

    try {
      final renderer = ui.PlatformDispatcher.instance;
      testLog.add('📊 Views: ${renderer.views.length}');
      testLog.add(
        '📊 Pixel Ratio: ${renderer.views.firstOrNull?.devicePixelRatio ?? 1.0}',
      );
    } catch (e) {
      testLog.add('❌ Engine: $e');
    }
  }

  Future<void> _testPerformance() async {
    testLog.add('🧪 Testing Performance...');

    final stopwatch = Stopwatch()..start();

    final frames = <int>[];
    void addFrame() {
      frames.add(stopwatch.elapsedMilliseconds);
      if (frames.length < 60) {
        WidgetsBinding.instance.addPostFrameCallback((_) => addFrame());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => addFrame());

    await Future.delayed(const Duration(seconds: 2));

    if (frames.length > 10) {
      final deltas = <int>[];
      for (var i = 1; i < frames.length; i++) {
        deltas.add(frames[i] - frames[i - 1]);
      }

      final avg = deltas.reduce((a, b) => a + b) ~/ deltas.length;
      final min = deltas.reduce((a, b) => a < b ? a : b);
      final max = deltas.reduce((a, b) => a > b ? a : b);

      testLog.add('📊 FPS: ${1000 ~/ avg} (avg)');
      testLog.add('📊 Frame time: ${avg}ms (min: ${min}ms, max: ${max}ms)');
      testLog.add(
        frames.length >= 58
            ? '✅ Performance: Good'
            : '⚠️ Performance: Dropped frames',
      );
    }
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {bool isError = false}) {
    if (value == null || value == 'not set' || value == 'unknown') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: SelectableText(
              value.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isError
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurface,
                fontFamily: Platform.isLinux ? 'Monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || Platform.isIOS || Platform.isMacOS) {
      return Scaffold(
        appBar: AppBar(title: const Text('Renderer Debug')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.block,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'Not supported on this platform',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Renderer'),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _collectDebugInfo,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: Icon(
              isTesting ? Icons.hourglass_top : Icons.play_arrow_rounded,
            ),
            onPressed: isTesting ? null : _runComprehensiveTests,
            tooltip: 'Run Tests',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _buildHeader('SYSTEM'),
          _buildInfoRow('Operating System', debugInfo['platform']),
          _buildInfoRow('Flutter Version', debugInfo['flutterVersion']),
          _buildInfoRow('Dart Version', debugInfo['dartVersion']),
          if (Platform.isLinux) ...[
            _buildInfoRow('Display Server', debugInfo['sessionType']),
            _buildInfoRow('Desktop Env', debugInfo['desktop']),
            _buildInfoRow('GDK Backend', debugInfo['gdkBackend']),
          ],

          const Divider(height: 48, indent: 16, endIndent: 16),

          _buildHeader('GRAPHICS'),
          _buildInfoRow(
            'Impeller Enabled',
            debugInfo['impellerEnv'],
            isError: debugInfo['impellerEnv'] != 'false',
          ),
          if (Platform.isLinux) ...[
            _buildInfoRow('GPU Vendor', debugInfo['gpuVendor']),
            _buildInfoRow('GPU Device', debugInfo['gpuDevice']),
            _buildInfoRow('OpenGL', debugInfo['glVersion']),
            _buildInfoRow('Direct Rendering', debugInfo['directRendering']),
            _buildInfoRow(
              'Vulkan Status',
              debugInfo['vulkanAvailable'] == true
                  ? 'Available'
                  : 'Unavailable',
            ),
          ],

          const Divider(height: 48, indent: 16, endIndent: 16),

          _buildHeader('ENGINE DIAGNOSTICS'),
          _buildInfoRow('Active Views', debugInfo['viewCount']),
          _buildInfoRow('Pixel Ratio', debugInfo['pixelRatio']),
          _buildInfoRow(
            'Renderer Error',
            debugInfo['rendererError'],
            isError: true,
          ),

          if (isTesting || testLog.isNotEmpty) ...[
            const Divider(height: 48, indent: 16, endIndent: 16),
            _buildHeader('TEST LOGS'),
            if (isTesting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LinearProgressIndicator(),
              ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: testLog
                    .map(
                      (log) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'Monospace',
                            fontSize: 12,
                            color: log.startsWith('✅')
                                ? Colors.green[700]
                                : log.startsWith('❌')
                                ? Theme.of(context).colorScheme.error
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],

          const SizedBox(height: 32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Export Log'),
                    onPressed: _exportDebugLog,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: IconButton.filledTonal(
                    icon: const Icon(Icons.terminal_rounded, size: 18),
                    onPressed: _showEnvVars,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportDebugLog() {
    final buffer = StringBuffer();
    buffer.writeln('=== SHONENX RENDERER LOG ===');
    buffer.writeln('Date: ${DateTime.now()}');
    buffer.writeln('System: ${debugInfo['platform']}');

    if (testLog.isNotEmpty) {
      buffer.writeln('\n[TEST RESULTS]');
      for (final log in testLog) {
        buffer.writeln(log);
      }
    }

    AppLogger.w(buffer.toString());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Log exported to console'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showEnvVars() {
    final env = Platform.environment;
    final relevantKeys = [
      'FLUTTER',
      'GDK',
      'DISPLAY',
      'WAYLAND',
      'GL',
      'VULKAN',
    ];
    final vars = env.entries
        .where((e) => relevantKeys.any((k) => e.key.contains(k)))
        .map((e) => '${e.key}=${e.value}')
        .join('\n');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Environment'),
        content: SingleChildScrollView(
          child: SelectableText(
            vars.isEmpty ? 'No relevant variables' : vars,
            style: const TextStyle(fontFamily: 'Monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

void checkRendererOnStart() {
  if (kIsWeb || Platform.isIOS || Platform.isMacOS) return;

  final env = Platform.environment;
  final impeller = env['FLUTTER_ENGINE_IMPELER_ENABLE'];

  if (impeller != 'false') {
    AppLogger.w('⚠️ Impeller check: Enabled (default or explicit)');
  }
}
