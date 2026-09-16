import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shonenx/core/utils/app_logger.dart';
import 'package:shonenx/shared/widgets/app_scaffold.dart';
import 'package:shonenx/shared/widgets/unified_search_bar.dart';

enum LogFilterLevel {
  all('All'),
  error('Errors'),
  warn('Warnings'),
  info('Info'),
  debug('Debug'),
  verbose('Verbose');

  final String label;
  const LogFilterLevel(this.label);
}

class LogItem {
  final int index;
  final String timestamp;
  final String? timeOnly;
  final String level;
  final String? context;
  final String message;
  final String? details;
  final String raw;

  const LogItem({
    required this.index,
    required this.timestamp,
    this.timeOnly,
    required this.level,
    this.context,
    required this.message,
    this.details,
    required this.raw,
  });

  bool get isSystem => level == 'SYSTEM';
  bool get hasDetails => details != null && details!.isNotEmpty;
}

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<LogItem> _allEntries = [];
  List<LogItem> _filteredEntries = [];
  final Set<int> _expandedEntries = {};

  bool _isLoading = true;
  bool _isNearBottom = true;
  bool _showScrollToBottom = false;
  bool _showFullTimestamp = false;

  LogFilterLevel _selectedLevel = LogFilterLevel.all;
  String _searchQuery = '';
  Timer? _debounceTimer;

  int _errorCount = 0;
  int _warnCount = 0;
  int _infoCount = 0;
  int _debugCount = 0;
  int _verboseCount = 0;

  static final RegExp _timestampRegex = RegExp(
    r'^(\d{4}-\d{2}-\d{2}[T ](\d{2}:\d{2}:\d{2}(?:\.\d+)?))\s+(.*)$',
  );
  static final RegExp _tagRegex = RegExp(
    r'^\[(ERROR|WARN|INFO|DEBUG|VERBOSE|SUCCESS|RAW)\]\s*(.*)$',
  );
  static final RegExp _contextRegex = RegExp(r'^\[(.*?)\]\s*(.*)$');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadLogs();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final nearBottom = (maxScroll - currentScroll) <= 80;

    if (_isNearBottom != nearBottom) {
      setState(() {
        _isNearBottom = nearBottom;
        _showScrollToBottom = !nearBottom && _filteredEntries.length > 20;
      });
    }
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    final rawLogs = await AppLogger.getLogContent();

    final parsed = _parseLogs(rawLogs);

    int errors = 0;
    int warns = 0;
    int infos = 0;
    int debugs = 0;
    int verboses = 0;

    for (final entry in parsed) {
      switch (entry.level) {
        case 'ERROR':
          errors++;
          break;
        case 'WARN':
          warns++;
          break;
        case 'INFO':
        case 'SUCCESS':
          infos++;
          break;
        case 'DEBUG':
          debugs++;
          break;
        case 'VERBOSE':
        case 'RAW':
          verboses++;
          break;
      }
    }

    if (mounted) {
      setState(() {
        _allEntries = parsed;
        _errorCount = errors;
        _warnCount = warns;
        _infoCount = infos;
        _debugCount = debugs;
        _verboseCount = verboses;
        _isLoading = false;
        _applyFilters();
      });

      if (_isNearBottom && _scrollController.hasClients) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }
    }
  }

  List<LogItem> _parseLogs(String rawContent) {
    if (rawContent.trim().isEmpty || rawContent == 'No logs available.') {
      return [];
    }

    final rawLines = rawContent.split('\n');
    final items = <LogItem>[];

    LogItem? currentItem;
    final detailsBuffer = StringBuffer();
    int indexCounter = 0;

    void flushCurrent() {
      if (currentItem != null) {
        final detailsStr = detailsBuffer.toString().trim();
        items.add(
          LogItem(
            index: currentItem!.index,
            timestamp: currentItem!.timestamp,
            timeOnly: currentItem!.timeOnly,
            level: currentItem!.level,
            context: currentItem!.context,
            message: currentItem!.message,
            details: detailsStr.isNotEmpty ? detailsStr : null,
            raw:
                currentItem!.raw +
                (detailsStr.isNotEmpty ? '\n$detailsStr' : ''),
          ),
        );
        detailsBuffer.clear();
        currentItem = null;
      }
    }

    for (final line in rawLines) {
      if (line.isEmpty) continue;

      final tsMatch = _timestampRegex.firstMatch(line);
      if (tsMatch != null) {
        flushCurrent();

        final fullTs = tsMatch.group(1)!;
        final timeOnly = tsMatch.group(2);
        final rest = tsMatch.group(3) ?? '';

        if (rest.startsWith('===') && rest.endsWith('===')) {
          currentItem = LogItem(
            index: indexCounter++,
            timestamp: fullTs,
            timeOnly: timeOnly,
            level: 'SYSTEM',
            context: null,
            message: rest,
            raw: line,
          );
          continue;
        }

        final tagMatch = _tagRegex.firstMatch(rest);
        if (tagMatch != null) {
          final level = tagMatch.group(1)!;
          final afterTag = tagMatch.group(2) ?? '';

          String? context;
          String message = afterTag;

          final ctxMatch = _contextRegex.firstMatch(afterTag);
          if (ctxMatch != null) {
            context = ctxMatch.group(1);
            message = ctxMatch.group(2) ?? '';
          } else {
            final spaceIdx = afterTag.indexOf(' ');
            if (spaceIdx > 0 && afterTag.substring(0, spaceIdx).contains('.')) {
              context = afterTag.substring(0, spaceIdx);
              message = afterTag.substring(spaceIdx + 1);
            }
          }

          currentItem = LogItem(
            index: indexCounter++,
            timestamp: fullTs,
            timeOnly: timeOnly,
            level: level,
            context: context,
            message: message,
            raw: line,
          );
        } else {
          currentItem = LogItem(
            index: indexCounter++,
            timestamp: fullTs,
            timeOnly: timeOnly,
            level: 'INFO',
            context: null,
            message: rest,
            raw: line,
          );
        }
      } else {
        if (currentItem != null) {
          if (detailsBuffer.isNotEmpty) detailsBuffer.writeln();
          detailsBuffer.write(line);
        } else {
          items.add(
            LogItem(
              index: indexCounter++,
              timestamp: '',
              timeOnly: null,
              level: 'INFO',
              context: null,
              message: line,
              raw: line,
            ),
          );
        }
      }
    }

    flushCurrent();
    return items;
  }

  void _onSearchChanged(String query) {
    if (mounted) setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      if (mounted) {
        setState(() {
          _searchQuery = query.trim().toLowerCase();
          _applyFilters();
        });
      }
    });
  }

  void _applyFilters() {
    final query = _searchQuery;
    final level = _selectedLevel;

    _filteredEntries = _allEntries.where((entry) {
      if (level != LogFilterLevel.all) {
        if (level == LogFilterLevel.error && entry.level != 'ERROR') {
          return false;
        }
        if (level == LogFilterLevel.warn && entry.level != 'WARN') {
          return false;
        }
        if (level == LogFilterLevel.info &&
            entry.level != 'INFO' &&
            entry.level != 'SUCCESS') {
          return false;
        }
        if (level == LogFilterLevel.debug && entry.level != 'DEBUG') {
          return false;
        }
        if (level == LogFilterLevel.verbose &&
            entry.level != 'VERBOSE' &&
            entry.level != 'RAW') {
          return false;
        }
      }

      if (query.isNotEmpty) {
        final matchesMessage = entry.message.toLowerCase().contains(query);
        final matchesContext =
            entry.context?.toLowerCase().contains(query) ?? false;
        final matchesDetails =
            entry.details?.toLowerCase().contains(query) ?? false;
        final matchesLevel = entry.level.toLowerCase().contains(query);

        if (!matchesMessage &&
            !matchesContext &&
            !matchesDetails &&
            !matchesLevel) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedLevel = LogFilterLevel.all;
      _applyFilters();
    });
  }

  void _toggleExpand(int index) {
    setState(() {
      if (_expandedEntries.contains(index)) {
        _expandedEntries.remove(index);
      } else {
        _expandedEntries.add(index);
      }
    });
  }

  Future<void> _copyEntry(LogItem entry) async {
    final buffer = StringBuffer(entry.timestamp)
      ..write(' [')
      ..write(entry.level)
      ..write('] ');
    if (entry.context != null) {
      buffer.write('[${entry.context}] ');
    }
    buffer.write(entry.message);
    if (entry.details != null && entry.details!.isNotEmpty) {
      buffer
        ..write('\n')
        ..write(entry.details);
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Log entry copied'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyLogs() async {
    final entriesToCopy = _filteredEntries.isNotEmpty
        ? _filteredEntries
        : _allEntries;
    if (entriesToCopy.isEmpty) return;

    final text = entriesToCopy.map((e) => e.raw).join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Copied ${entriesToCopy.length} entries to clipboard'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _exportLogs() async {
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save App Logs',
        fileName: 'shonenx_logs.txt',
        type: FileType.custom,
        allowedExtensions: ['txt'],
      );

      if (path != null) {
        final text = _allEntries.map((e) => e.raw).join('\n');
        final file = File(path);
        await file.writeAsString(text);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Logs exported to $path')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to export logs: $e')));
      }
    }
  }

  Future<void> _confirmClearLogs() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Logs'),
        content: const Text(
          'Are you sure you want to clear all stored app logs? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: cs.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AppLogger.clearLogs();
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Logs cleared')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDesktop = MediaQuery.sizeOf(context).width >= 700;

    final subtitleText = _allEntries.isEmpty
        ? null
        : (_filteredEntries.length == _allEntries.length
              ? '${_allEntries.length} entries'
              : '${_filteredEntries.length} of ${_allEntries.length} entries');

    return AppScaffold(
      title: 'Logs',
      subtitle: subtitleText,
      actions: [
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 20),
          tooltip: 'Copy all visible logs',
          onPressed: _filteredEntries.isEmpty ? null : _copyLogs,
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 20),
          tooltip: 'Refresh logs',
          onPressed: _loadLogs,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded, size: 20),
          tooltip: 'More options',
          onSelected: (action) {
            switch (action) {
              case 'toggle_time':
                setState(() => _showFullTimestamp = !_showFullTimestamp);
                break;
              case 'export':
                _exportLogs();
                break;
              case 'clear':
                _confirmClearLogs();
                break;
              case 'top':
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
                break;
              case 'bottom':
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut,
                  );
                }
                break;
            }
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              value: 'toggle_time',
              child: Row(
                children: [
                  Icon(
                    _showFullTimestamp
                        ? Icons.schedule_rounded
                        : Icons.calendar_today_rounded,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _showFullTimestamp
                        ? 'Show time only'
                        : 'Show full timestamp',
                  ),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Export to file'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'top',
              child: Row(
                children: [
                  Icon(Icons.arrow_upward_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Scroll to top'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'bottom',
              child: Row(
                children: [
                  Icon(Icons.arrow_downward_rounded, size: 18),
                  SizedBox(width: 10),
                  Text('Scroll to bottom'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_outline_rounded, size: 18, color: cs.error),
                  const SizedBox(width: 10),
                  Text('Clear all logs', style: TextStyle(color: cs.error)),
                ],
              ),
            ),
          ],
        ),
      ],
      floatingActionButton: _showScrollToBottom
          ? FloatingActionButton.small(
              backgroundColor: cs.surfaceContainerHighest,
              foregroundColor: cs.onSurface,
              tooltip: 'Scroll to bottom',
              onPressed: () {
                _scrollController.animateTo(
                  _scrollController.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOut,
                );
              },
              child: const Icon(Icons.arrow_downward_rounded, size: 18),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildControlBar(context),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredEntries.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 2, bottom: 28),
                    itemCount: _filteredEntries.length,
                    itemBuilder: (context, index) {
                      final item = _filteredEntries[index];
                      if (item.isSystem) {
                        return _buildSystemEventItem(context, item);
                      }
                      return _buildEntryItem(context, item, isDesktop);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static Color _getLevelColor(String level, bool isDark) {
    switch (level.toUpperCase()) {
      case 'ERROR':
        return isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);
      case 'WARN':
        return isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
      case 'SUCCESS':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case 'INFO':
        return isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7);
      case 'DEBUG':
        return isDark ? const Color(0xFFA78BFA) : const Color(0xFF7C3AED);
      case 'VERBOSE':
      case 'RAW':
      default:
        return isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    }
  }

  Widget _buildControlBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          UnifiedSearchBar(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: false,
            height: 44,
            margin: EdgeInsets.zero,
            leading: const Icon(Icons.search_rounded),
            hintText: 'Search logs, context, traces...',
            onBackPressed: () {},
            onClearPressed: () {
              _searchController.clear();
              _onSearchChanged('');
            },
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  context,
                  label: 'All',
                  count: _allEntries.length,
                  level: LogFilterLevel.all,
                ),
                _buildFilterChip(
                  context,
                  label: 'Errors',
                  count: _errorCount,
                  level: LogFilterLevel.error,
                  accentColor: _getLevelColor('ERROR', isDark),
                ),
                _buildFilterChip(
                  context,
                  label: 'Warnings',
                  count: _warnCount,
                  level: LogFilterLevel.warn,
                  accentColor: _getLevelColor('WARN', isDark),
                ),
                _buildFilterChip(
                  context,
                  label: 'Info',
                  count: _infoCount,
                  level: LogFilterLevel.info,
                  accentColor: _getLevelColor('INFO', isDark),
                ),
                _buildFilterChip(
                  context,
                  label: 'Debug',
                  count: _debugCount,
                  level: LogFilterLevel.debug,
                  accentColor: _getLevelColor('DEBUG', isDark),
                ),
                _buildFilterChip(
                  context,
                  label: 'Verbose',
                  count: _verboseCount,
                  level: LogFilterLevel.verbose,
                  accentColor: _getLevelColor('VERBOSE', isDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    BuildContext context, {
    required String label,
    required int count,
    required LogFilterLevel level,
    Color? accentColor,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isSelected = _selectedLevel == level;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () {
          if (_selectedLevel != level) {
            setState(() {
              _selectedLevel = level;
              _applyFilters();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? (accentColor != null
                      ? accentColor.withValues(alpha: 0.18)
                      : cs.secondaryContainer.withValues(alpha: 0.7))
                : cs.surfaceContainerHigh.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(6),
            border: isSelected && accentColor != null
                ? Border.all(
                    color: accentColor.withValues(alpha: 0.5),
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 11,
                  color: isSelected
                      ? (accentColor ?? cs.onSecondaryContainer)
                      : cs.onSurfaceVariant.withValues(alpha: 0.8),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '$count',
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? (accentColor ?? cs.onSecondaryContainer)
                        : (accentColor != null
                              ? accentColor.withValues(alpha: 0.8)
                              : cs.onSurfaceVariant.withValues(alpha: 0.5)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEntryItem(BuildContext context, LogItem item, bool isDesktop) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isExpanded = _expandedEntries.contains(item.index);

    final levelColor = _getLevelColor(item.level, isDark);
    String shortLevel;
    FontWeight levelWeight = FontWeight.w600;

    switch (item.level.toUpperCase()) {
      case 'ERROR':
        shortLevel = 'ERR';
        levelWeight = FontWeight.w700;
        break;
      case 'WARN':
        shortLevel = 'WARN';
        levelWeight = FontWeight.w700;
        break;
      case 'INFO':
        shortLevel = 'INFO';
        break;
      case 'SUCCESS':
        shortLevel = 'OK';
        levelWeight = FontWeight.w700;
        break;
      case 'DEBUG':
        shortLevel = 'DBG';
        levelWeight = FontWeight.w500;
        break;
      case 'VERBOSE':
      case 'RAW':
      default:
        shortLevel = 'VRB';
        levelWeight = FontWeight.w400;
        break;
    }

    return InkWell(
      onTap: item.hasDetails
          ? () => _toggleExpand(item.index)
          : () => _copyEntry(item),
      onLongPress: () => _copyEntry(item),
      hoverColor: cs.surfaceContainerHighest.withValues(alpha: 0.15),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 16 : 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: isExpanded
              ? cs.surfaceContainerLowest.withValues(alpha: 0.4)
              : (item.level == 'ERROR'
                    ? levelColor.withValues(alpha: 0.07)
                    : item.level == 'WARN'
                    ? levelColor.withValues(alpha: 0.05)
                    : null),
          border: Border(
            bottom: BorderSide(
              color: cs.outlineVariant.withValues(alpha: 0.1),
              width: 0.5,
            ),
            left:
                (item.level == 'ERROR' ||
                    item.level == 'WARN' ||
                    item.level == 'SUCCESS')
                ? BorderSide(color: levelColor, width: 2.5)
                : BorderSide.none,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDesktop)
              _buildDesktopRowContent(
                context,
                item,
                shortLevel,
                levelColor,
                levelWeight,
                isExpanded,
              )
            else
              _buildMobileRowContent(
                context,
                item,
                shortLevel,
                levelColor,
                levelWeight,
                isExpanded,
              ),
            if (isExpanded && item.hasDetails)
              _buildExpandedDetails(context, item),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopRowContent(
    BuildContext context,
    LogItem item,
    String shortLevel,
    Color levelColor,
    FontWeight levelWeight,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    final timeStr = _showFullTimestamp
        ? item.timestamp.replaceAll('T', ' ')
        : (item.timeOnly ?? item.timestamp);
    final tsWidth = _showFullTimestamp ? 200.0 : 130.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: () => setState(() => _showFullTimestamp = !_showFullTimestamp),
          child: Tooltip(
            message: _showFullTimestamp
                ? 'Click to show time only\n${item.timestamp}'
                : 'Click to show date & time\n${item.timestamp}',
            waitDuration: const Duration(milliseconds: 300),
            child: SizedBox(
              width: tsWidth,
              child: Text(
                timeStr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 44,
          child: Text(
            shortLevel,
            style: textTheme.labelSmall?.copyWith(
              color: levelColor,
              fontWeight: levelWeight,
              fontSize: 11,
              letterSpacing: 0.2,
            ),
          ),
        ),
        const SizedBox(width: 8),
        if (item.context != null) ...[
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              item.context!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.75),
                fontSize: 11,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '•',
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                fontSize: 11,
              ),
            ),
          ),
        ],
        Expanded(
          child: Text(
            item.message,
            style: textTheme.bodySmall?.copyWith(
              color: item.level == 'ERROR'
                  ? levelColor
                  : (item.level == 'SUCCESS' && item.message.startsWith('✓')
                        ? levelColor
                        : cs.onSurface),
              height: 1.35,
            ),
          ),
        ),
        if (item.hasDetails)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: cs.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }

  Widget _buildMobileRowContent(
    BuildContext context,
    LogItem item,
    String shortLevel,
    Color levelColor,
    FontWeight levelWeight,
    bool isExpanded,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    shortLevel,
                    style: textTheme.labelSmall?.copyWith(
                      color: levelColor,
                      fontWeight: levelWeight,
                      fontSize: 10,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (item.context != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      '•',
                      style: textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withValues(alpha: 0.3),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.context!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.75),
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () =>
                  setState(() => _showFullTimestamp = !_showFullTimestamp),
              child: Tooltip(
                message: _showFullTimestamp
                    ? 'Click to show time only\n${item.timestamp}'
                    : 'Click to show date & time\n${item.timestamp}',
                waitDuration: const Duration(milliseconds: 300),
                child: Text(
                  _showFullTimestamp
                      ? item.timestamp.replaceAll('T', ' ')
                      : (item.timeOnly ?? item.timestamp),
                  style: textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.55),
                    fontSize: 10,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            if (item.hasDetails) ...[
              const SizedBox(width: 4),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Text(
          item.message,
          style: textTheme.bodySmall?.copyWith(
            color: item.level == 'ERROR'
                ? levelColor
                : (item.level == 'SUCCESS' && item.message.startsWith('✓')
                      ? levelColor
                      : cs.onSurface),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedDetails(BuildContext context, LogItem item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                'DETAILS / TRACE',
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: item.details!));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Details copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 12, color: cs.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Copy',
                        style: textTheme.labelSmall?.copyWith(
                          color: cs.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SelectableText(
            item.details!,
            style: textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 11,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemEventItem(BuildContext context, LogItem item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    String text = item.message;
    if (text.startsWith('===') && text.endsWith('===')) {
      text = text.replaceAll('===', '').trim();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.2),
              height: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              text,
              style: textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
                fontSize: 10,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: cs.outlineVariant.withValues(alpha: 0.2),
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _allEntries.isEmpty
                  ? Icons.history_rounded
                  : Icons.filter_list_off_rounded,
              size: 40,
              color: cs.onSurfaceVariant.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _allEntries.isEmpty
                  ? 'No logs recorded yet'
                  : 'No log entries match your filter',
              style: textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurfaceVariant,
              ),
            ),
            if (_allEntries.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Try adjusting your search query or selecting "All" levels.',
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
