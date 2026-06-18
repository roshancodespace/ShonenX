import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shonenx/features/settings/presentation/widgets/settings_ui_components.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/source_engine/models/source_info.dart';
import 'package:shonenx/source_engine/source_registry.dart';
import 'package:shonenx/source_engine/source_engine_provider.dart';
import 'package:shonenx/shared/models/unified_media.dart';
import 'package:shonenx/shared/models/unified_episode.dart';
import 'package:shonenx/shared/models/video_server.dart';

enum TestStatus { pending, running, passed, failed }

enum TestStepType { search, details, episodes, servers, streams }

class StepResult {
  final TestStepType type;
  final TestStatus status;
  final Duration? latency;
  final String? error;
  final String? detail;
  final String? rawResponse;

  const StepResult({
    required this.type,
    required this.status,
    this.latency,
    this.error,
    this.detail,
    this.rawResponse,
  });

  String get name {
    switch (type) {
      case TestStepType.search:
        return 'Catalog Search';
      case TestStepType.details:
        return 'Media Details';
      case TestStepType.episodes:
        return 'Episode List';
      case TestStepType.servers:
        return 'Video Servers';
      case TestStepType.streams:
        return 'Stream Links';
    }
  }
}

class SourceTestResult {
  final SourceInfo source;
  final TestStatus status;
  final List<StepResult> steps;

  const SourceTestResult({
    required this.source,
    required this.status,
    required this.steps,
  });

  Duration get totalLatency {
    int totalMs = 0;
    for (var step in steps) {
      if (step.latency != null) {
        totalMs += step.latency!.inMilliseconds;
      }
    }
    return Duration(milliseconds: totalMs);
  }
}

class ExtensionTesterScreen extends ConsumerStatefulWidget {
  const ExtensionTesterScreen({super.key});

  @override
  ConsumerState<ExtensionTesterScreen> createState() =>
      _ExtensionTesterScreenState();
}

class _ExtensionTesterScreenState extends ConsumerState<ExtensionTesterScreen> {
  final TextEditingController _queryController = TextEditingController(
    text: 'One Piece',
  );
  final Map<String, SourceTestResult> _results = {};
  final Set<String> _selectedSourceIds = {};
  bool _isTesting = false;
  bool _hasInitializedSelection = false;

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _updateStepStatus(
    String sourceId,
    TestStepType type,
    TestStatus status,
  ) {
    if (!mounted) return;
    setState(() {
      final current = _results[sourceId]!;
      final updatedSteps = current.steps.map((step) {
        if (step.type == type) {
          return StepResult(
            type: type,
            status: status,
            latency: step.latency,
            error: step.error,
            detail: step.detail,
          );
        }
        return step;
      }).toList();
      _results[sourceId] = SourceTestResult(
        source: current.source,
        status: current.status,
        steps: updatedSteps,
      );
    });
  }

  void _updateStepResult(
    String sourceId,
    TestStepType type,
    TestStatus status,
    Duration latency,
    String? error,
    String? detail,
  ) {
    if (!mounted) return;
    setState(() {
      final current = _results[sourceId]!;
      final updatedSteps = current.steps.map((step) {
        if (step.type == type) {
          return StepResult(
            type: type,
            status: status,
            latency: latency,
            error: error,
            detail: detail,
          );
        }
        return step;
      }).toList();
      _results[sourceId] = SourceTestResult(
        source: current.source,
        status: status == TestStatus.failed
            ? TestStatus.failed
            : current.status,
        steps: updatedSteps,
      );
    });
  }

  void _markRemainingStepsFailed(String sourceId, TestStepType startFrom) {
    if (!mounted) return;
    setState(() {
      final current = _results[sourceId]!;
      bool markFailed = false;
      final updatedSteps = current.steps.map((step) {
        if (step.type == startFrom) {
          markFailed = true;
        }
        if (markFailed) {
          return StepResult(
            type: step.type,
            status: TestStatus.failed,
            error: 'Skipped due to prior step failure',
          );
        }
        return step;
      }).toList();
      _results[sourceId] = SourceTestResult(
        source: current.source,
        status: TestStatus.failed,
        steps: updatedSteps,
      );
    });
  }

  Future<void> _runTestForSource(SourceInfo source, String query) async {
    if (!mounted) return;
    setState(() {
      _results[source.id] = SourceTestResult(
        source: source,
        status: TestStatus.running,
        steps: const [
          StepResult(type: TestStepType.search, status: TestStatus.running),
          StepResult(type: TestStepType.details, status: TestStatus.pending),
          StepResult(type: TestStepType.episodes, status: TestStatus.pending),
          StepResult(type: TestStepType.servers, status: TestStatus.pending),
          StepResult(type: TestStepType.streams, status: TestStatus.pending),
        ],
      );
    });

    final animeSource = ref.read(animeSourceProvider(source));

    // Step 1: Search
    final searchStopwatch = Stopwatch()..start();
    List<UnifiedMedia> searchResults = [];
    try {
      searchResults = await animeSource
          .search(query, MediaType.ANIME)
          .timeout(const Duration(seconds: 15));
      searchStopwatch.stop();
      if (searchResults.isEmpty) {
        throw Exception('No results returned for search query "$query"');
      }
      final firstTitle = searchResults.first.title.availableTitle;
      _updateStepResult(
        source.id,
        TestStepType.search,
        TestStatus.passed,
        searchStopwatch.elapsed,
        null,
        'Found ${searchResults.length} matches (first: "$firstTitle")',
      );
    } catch (e) {
      searchStopwatch.stop();
      _updateStepResult(
        source.id,
        TestStepType.search,
        TestStatus.failed,
        searchStopwatch.elapsed,
        e.toString(),
        null,
      );
      _markRemainingStepsFailed(source.id, TestStepType.details);
      return;
    }

    // Step 2: Details
    final detailsStopwatch = Stopwatch()..start();
    UnifiedMedia? detailedMedia;
    try {
      final firstMedia = searchResults.first;
      _updateStepStatus(source.id, TestStepType.details, TestStatus.running);
      detailedMedia = await animeSource
          .getDetails(firstMedia.providerId ?? firstMedia.id, MediaType.ANIME)
          .timeout(const Duration(seconds: 15));
      detailsStopwatch.stop();
      _updateStepResult(
        source.id,
        TestStepType.details,
        TestStatus.passed,
        detailsStopwatch.elapsed,
        null,
        'Format: ${detailedMedia.format ?? "Unknown"} • Status: ${detailedMedia.status ?? "Unknown"} • Episodes: ${detailedMedia.episodes ?? "Unknown"}',
      );
    } catch (e) {
      detailsStopwatch.stop();
      _updateStepResult(
        source.id,
        TestStepType.details,
        TestStatus.failed,
        detailsStopwatch.elapsed,
        e.toString(),
        null,
      );
      _markRemainingStepsFailed(source.id, TestStepType.episodes);
      return;
    }

    // Step 3: Episodes
    final episodesStopwatch = Stopwatch()..start();
    List<UnifiedEpisode> episodes = [];
    try {
      final targetId = detailedMedia.providerId ?? detailedMedia.id;
      _updateStepStatus(source.id, TestStepType.episodes, TestStatus.running);
      episodes = await animeSource
          .getEpisodes(targetId)
          .timeout(const Duration(seconds: 15));
      episodesStopwatch.stop();
      if (episodes.isEmpty) {
        throw Exception('No episodes returned for media ID: $targetId');
      }
      final firstEpName =
          episodes.first.title ?? 'Episode ${episodes.first.number}';
      _updateStepResult(
        source.id,
        TestStepType.episodes,
        TestStatus.passed,
        episodesStopwatch.elapsed,
        null,
        'Parsed ${episodes.length} episodes (first: "$firstEpName")',
      );
    } catch (e) {
      episodesStopwatch.stop();
      _updateStepResult(
        source.id,
        TestStepType.episodes,
        TestStatus.failed,
        episodesStopwatch.elapsed,
        e.toString(),
        null,
      );
      _markRemainingStepsFailed(source.id, TestStepType.servers);
      return;
    }

    // Step 4: Servers
    final serversStopwatch = Stopwatch()..start();
    List<VideoServer> servers = [];
    try {
      final firstEpisode = episodes.first;
      _updateStepStatus(source.id, TestStepType.servers, TestStatus.running);
      servers = await animeSource
          .getServers(firstEpisode.id)
          .timeout(const Duration(seconds: 15));
      serversStopwatch.stop();
      if (servers.isEmpty) {
        throw Exception(
          'No video servers found for episode ID: ${firstEpisode.id}',
        );
      }
      final serverNames = servers.map((s) => s.name).join(', ');
      _updateStepResult(
        source.id,
        TestStepType.servers,
        TestStatus.passed,
        serversStopwatch.elapsed,
        null,
        'Found ${servers.length} server(s): $serverNames',
      );
    } catch (e) {
      serversStopwatch.stop();
      _updateStepResult(
        source.id,
        TestStepType.servers,
        TestStatus.failed,
        serversStopwatch.elapsed,
        e.toString(),
        null,
      );
      _markRemainingStepsFailed(source.id, TestStepType.streams);
      return;
    }

    // Step 5: Streams
    final streamsStopwatch = Stopwatch()..start();
    try {
      final firstEpisode = episodes.first;
      final firstServer = servers.first;
      _updateStepStatus(source.id, TestStepType.streams, TestStatus.running);
      final streams = await animeSource
          .getSources(firstEpisode.id, firstServer)
          .timeout(const Duration(seconds: 15));
      streamsStopwatch.stop();
      if (streams.isEmpty) {
        throw Exception(
          'No video streams/links returned by server: ${firstServer.name}',
        );
      }
      _updateStepResult(
        source.id,
        TestStepType.streams,
        TestStatus.passed,
        streamsStopwatch.elapsed,
        null,
        'Resolved ${streams.length} stream link(s)',
      );

      if (mounted) {
        setState(() {
          final current = _results[source.id]!;
          _results[source.id] = SourceTestResult(
            source: current.source,
            status: TestStatus.passed,
            steps: current.steps,
          );
        });
      }
    } catch (e) {
      streamsStopwatch.stop();
      _updateStepResult(
        source.id,
        TestStepType.streams,
        TestStatus.failed,
        streamsStopwatch.elapsed,
        e.toString(),
        null,
      );
      if (mounted) {
        setState(() {
          final current = _results[source.id]!;
          _results[source.id] = SourceTestResult(
            source: current.source,
            status: TestStatus.failed,
            steps: current.steps,
          );
        });
      }
    }
  }

  Future<void> _startTests(List<SourceInfo> sources) async {
    if (_isTesting) return;

    final targetSources = sources
        .where((s) => _selectedSourceIds.contains(s.id))
        .toList();
    if (targetSources.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one source/extension to test.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isTesting = true;
    });

    try {
      final testQuery = _queryController.text.trim();
      final query = testQuery.isEmpty ? 'One Piece' : testQuery;

      // Launch tests concurrently (parallel execution)
      await Future.wait(
        targetSources.map((source) => _runTestForSource(source, query)),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTesting = false;
        });
      }
    }
  }

  Widget _buildStatusIcon(TestStatus status, ColorScheme colorScheme) {
    switch (status) {
      case TestStatus.pending:
        return Icon(
          Icons.radio_button_unchecked,
          size: 16,
          color: colorScheme.outlineVariant,
        );
      case TestStatus.running:
        return SizedBox(
          width: 16,
          height: 16,
          child: Padding(
            padding: const EdgeInsets.all(1.0),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
        );
      case TestStatus.passed:
        return const Icon(Icons.check_circle, size: 16, color: Colors.green);
      case TestStatus.failed:
        return const Icon(Icons.cancel, size: 16, color: Colors.red);
    }
  }

  Color _getStatusColor(TestStatus status, ColorScheme colorScheme) {
    switch (status) {
      case TestStatus.pending:
        return colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
      case TestStatus.running:
        return colorScheme.primary;
      case TestStatus.passed:
        return Colors.green;
      case TestStatus.failed:
        return Colors.red;
    }
  }

  Widget _buildTimelineStep({
    required String title,
    required TestStatus status,
    required TestStatus? previousStatus,
    required Duration? latency,
    required String? error,
    required String? detail,
    required bool isFirst,
    required bool isLast,
    required ThemeData theme,
    required ColorScheme colorScheme,
  }) {
    final Color topLineColor = isFirst
        ? Colors.transparent
        : (previousStatus == TestStatus.passed
              ? Colors.green
              : colorScheme.outlineVariant);

    final Color bottomLineColor = isLast
        ? Colors.transparent
        : (status == TestStatus.passed
              ? Colors.green
              : colorScheme.outlineVariant);

    final lineIndicator = SizedBox(
      width: 24,
      child: Column(
        children: [
          Container(width: 2, height: 10, color: topLineColor),
          _buildStatusIcon(status, colorScheme),
          Expanded(child: Container(width: 2, color: bottomLineColor)),
        ],
      ),
    );

    final Color textColor;
    final FontWeight fontWeight;
    switch (status) {
      case TestStatus.pending:
        textColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.5);
        fontWeight = FontWeight.normal;
        break;
      case TestStatus.running:
        textColor = colorScheme.primary;
        fontWeight = FontWeight.w600;
        break;
      case TestStatus.passed:
        textColor = colorScheme.onSurface;
        fontWeight = FontWeight.w600;
        break;
      case TestStatus.failed:
        textColor = colorScheme.error;
        fontWeight = FontWeight.w600;
        break;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          lineIndicator,
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textColor,
                            fontWeight: fontWeight,
                          ),
                        ),
                      ),
                      if (latency != null)
                        Text(
                          '${latency.inMilliseconds}ms',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: status == TestStatus.passed
                                ? Colors.green
                                : colorScheme.onSurfaceVariant,
                            fontFamily: 'monospace',
                            fontWeight: status == TestStatus.passed
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                  if (detail != null && status == TestStatus.passed) ...[
                    const SizedBox(height: 2),
                    Text(
                      detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.8,
                        ),
                        fontSize: 12,
                      ),
                    ),
                  ],
                  if (error != null) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: double.maxFinite,
                      padding: const EdgeInsets.only(
                        left: 8.0,
                        top: 4.0,
                        bottom: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: colorScheme.error.withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                      ),
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.error,
                          fontFamily: 'monospace',
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sourcesAsync = ref.watch(availableAnimeSourcesProvider);

    return AppScaffold(
      title: 'Extension Speed Tester',
      body: sourcesAsync.when(
        data: (sources) {
          if (sources.isEmpty) {
            return const Center(
              child: Text('No extensions/sources installed to test.'),
            );
          }

          // Automatically select all sources on first load
          if (!_hasInitializedSelection) {
            _hasInitializedSelection = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _selectedSourceIds.addAll(sources.map((s) => s.id));
                });
              }
            });
          }
          // Statistics calculations
          int totalSelected = _selectedSourceIds.length;
          int passedCount = 0;
          int failedCount = 0;
          int completedCount = 0;
          Duration totalLatencySum = Duration.zero;
          SourceInfo? fastestSource;
          SourceInfo? slowestSource;
          Duration minLatency = const Duration(days: 1);
          Duration maxLatency = Duration.zero;

          _results.forEach((id, result) {
            if (_selectedSourceIds.contains(id)) {
              if (result.status == TestStatus.passed) {
                passedCount++;
                completedCount++;
                final lat = result.totalLatency;
                totalLatencySum += lat;
                if (lat < minLatency) {
                  minLatency = lat;
                  fastestSource = result.source;
                }
                if (lat > maxLatency) {
                  maxLatency = lat;
                  slowestSource = result.source;
                }
              } else if (result.status == TestStatus.failed) {
                failedCount++;
                completedCount++;
              }
            }
          });

          final avgLatency = passedCount > 0
              ? Duration(
                  milliseconds: totalLatencySum.inMilliseconds ~/ passedCount,
                )
              : Duration.zero;

          // Circular progress value
          final double progressValue = totalSelected > 0
              ? (_isTesting
                    ? (completedCount / totalSelected)
                    : (passedCount / totalSelected))
              : 0.0;

          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 8.0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween<double>(
                              begin: 0.0,
                              end: progressValue,
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return SizedBox(
                                height: 70,
                                width: 70,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 5,
                                  backgroundColor:
                                      colorScheme.surfaceContainerHighest,
                                  valueColor: AlwaysStoppedAnimation(
                                    _isTesting
                                        ? colorScheme.primary
                                        : (passedCount == 0
                                              ? colorScheme.error
                                              : (passedCount == totalSelected
                                                    ? Colors.green
                                                    : colorScheme.secondary)),
                                  ),
                                ),
                              );
                            },
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isTesting
                                    ? '$completedCount/$totalSelected'
                                    : (passedCount > 0
                                          ? '${avgLatency.inMilliseconds}ms'
                                          : 'N/A'),
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: _isTesting ? 11 : 12,
                                ),
                              ),
                              Text(
                                _isTesting ? 'done' : 'avg speed',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontSize: 8,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isTesting
                                ? 'Testing Extensions...'
                                : 'Diagnostic Run Overview',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isTesting
                                ? 'Executing concurrent network calls in background...'
                                : '$passedCount passed, $failedCount failed out of $totalSelected selected',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (passedCount > 0) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                if (fastestSource != null)
                                  Expanded(
                                    child: Text(
                                      'Fastest: ${minLatency.inMilliseconds}ms (${fastestSource!.name})',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.green,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                if (slowestSource != null &&
                                    slowestSource != fastestSource) ...[
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Slowest: ${maxLatency.inMilliseconds}ms (${slowestSource!.name})',
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 32),
              SettingsSection(
                title: 'Test Configuration',
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    child: TextField(
                      controller: _queryController,
                      enabled: !_isTesting,
                      decoration: const InputDecoration(
                        labelText: 'Search Query to Test',
                        prefixIcon: Icon(Icons.science_outlined),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: _isTesting
                              ? null
                              : () {
                                  setState(() {
                                    if (_selectedSourceIds.length ==
                                        sources.length) {
                                      _selectedSourceIds.clear();
                                    } else {
                                      _selectedSourceIds.clear();
                                      _selectedSourceIds.addAll(
                                        sources.map((s) => s.id),
                                      );
                                    }
                                  });
                                },
                          icon: Icon(
                            _selectedSourceIds.length == sources.length
                                ? Icons.deselect_outlined
                                : Icons.select_all_outlined,
                          ),
                          label: Text(
                            _selectedSourceIds.length == sources.length
                                ? 'Deselect All'
                                : 'Select All',
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: _isTesting
                              ? null
                              : () => _startTests(sources),
                          icon: _isTesting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            _isTesting ? 'Testing...' : 'Run Parallel Tests',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SettingsSection(
                title: 'Installed Extensions',
                children: sources.map((source) {
                  final result = _results[source.id];
                  final isSelected = _selectedSourceIds.contains(source.id);

                  return Theme(
                    data: theme.copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 10.0),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: _isTesting
                                ? null
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedSourceIds.add(source.id);
                                      } else {
                                        _selectedSourceIds.remove(source.id);
                                      }
                                    });
                                  },
                          ),
                          const SizedBox(width: 8),
                          CachedNetworkImage(
                            imageUrl: source.iconUrl ?? '',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) =>
                                const Icon(Icons.extension, size: 36),
                          ),
                        ],
                      ),
                      title: Text(
                        source.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Row(
                        children: [
                          Text(source.id, style: theme.textTheme.bodySmall),
                          if (result != null) ...[
                            Text(' • ', style: theme.textTheme.bodySmall),
                            Text(
                              result.status == TestStatus.passed
                                  ? 'Passed (${result.totalLatency.inMilliseconds}ms)'
                                  : (result.status == TestStatus.running
                                        ? 'Running...'
                                        : (result.status == TestStatus.failed
                                              ? 'Failed'
                                              : 'Pending')),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getStatusColor(
                                  result.status,
                                  colorScheme,
                                ),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 58.0,
                            right: 16.0,
                            bottom: 16.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (result == null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Text('No test run yet.'),
                                )
                              else ...[
                                const SizedBox(height: 4),
                                ...List.generate(result.steps.length, (index) {
                                  final step = result.steps[index];
                                  final previousStep = index > 0
                                      ? result.steps[index - 1]
                                      : null;
                                  return _buildTimelineStep(
                                    title: step.name,
                                    status: step.status,
                                    previousStatus: previousStep?.status,
                                    latency: step.latency,
                                    error: step.error,
                                    detail: step.detail,
                                    isFirst: index == 0,
                                    isLast: index == result.steps.length - 1,
                                    theme: theme,
                                    colorScheme: colorScheme,
                                  );
                                }),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Error loading sources: $err')),
      ),
    );
  }
}
