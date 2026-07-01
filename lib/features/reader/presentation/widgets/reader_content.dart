import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shonenx/core/utils/responsive.dart';
import 'package:shonenx/features/reader/providers/reader_prefs_provider.dart';
import 'package:shonenx/features/reader/providers/reader_provider.dart';
import 'package:shonenx/source_engine/models/chapter_page.dart';

import 'reader_image.dart';

class ReaderContent extends ConsumerWidget {
  final AsyncValue<ReaderState> stateAsync;
  final ReaderPrefState prefs;
  final Color textColor;
  final int initialPage;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final PageController pageController;
  final TransformationController transformationController;
  final void Function(int) onTotalPagesUpdated;
  final void Function(int) onPageChanged;
  final void Function(double, Offset) onZoomOnScroll;
  final void Function(TapDownDetails) onToggleZoom;
  final VoidCallback onRetry;

  const ReaderContent({
    super.key,
    required this.stateAsync,
    required this.prefs,
    required this.textColor,
    required this.initialPage,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.pageController,
    required this.transformationController,
    required this.onTotalPagesUpdated,
    required this.onPageChanged,
    required this.onZoomOnScroll,
    required this.onToggleZoom,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return stateAsync.when(
      data: (state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.error != null) {
          return _buildErrorState(state.error!);
        }
        if (state.pages.isEmpty) {
          return Center(
            child: Text('No pages found.', style: TextStyle(color: textColor)),
          );
        }

        onTotalPagesUpdated(state.pages.length);

        final isWebtoon = prefs.direction == ReaderDirection.webtoon;
        Widget content = GestureDetector(
          onDoubleTapDown: onToggleZoom,
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  HardwareKeyboard.instance.logicalKeysPressed.contains(
                    LogicalKeyboardKey.controlLeft,
                  )) {
                onZoomOnScroll(event.scrollDelta.dy, event.localPosition);
              }
            },
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: 1.0,
              maxScale: 4.0,
              scaleEnabled: Platform.isAndroid || Platform.isIOS,
              trackpadScrollCausesScale: false,
              child: isWebtoon
                  ? _buildWebtoonList(state.pages)
                  : _buildPageView(state.pages),
            ),
          ),
        );

        if (isWebtoon &&
            (ResponsiveData.from(context).isDesktop ||
                ResponsiveData.from(context).isTablet)) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: content,
            ),
          );
        }

        return content;
      },
      error: (err, _) => Center(
        child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(
            'Failed to load pages:\n$error',
            textAlign: TextAlign.center,
            style: TextStyle(color: textColor),
          ),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildWebtoonList(List<ChapterPage> pages) {
    return ScrollablePositionedList.builder(
      itemCount: pages.length,
      initialScrollIndex: initialPage.clamp(
        0,
        pages.isEmpty ? 0 : pages.length - 1,
      ),
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      itemBuilder: (context, index) {
        final page = pages[index];
        return Listener(
          onPointerSignal: (event) {
            if (event is PointerScrollEvent &&
                HardwareKeyboard.instance.logicalKeysPressed.contains(
                  LogicalKeyboardKey.controlLeft,
                )) {
              GestureBinding.instance.pointerSignalResolver.register(
                event,
                (e) {},
              );
            }
          },
          child: ReaderImage(
            url: page.url,
            headers: page.headers ?? const {},
            index: index,
            scaleType: prefs.scaleType,
            textColor: textColor,
          ),
        );
      },
    );
  }

  Widget _buildPageView(List<ChapterPage> pages) {
    return PageView.builder(
      controller: pageController,
      reverse: prefs.direction == ReaderDirection.rtl,
      itemCount: pages.length,
      onPageChanged: onPageChanged,
      itemBuilder: (context, index) {
        final page = pages[index];
        return Center(
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent &&
                  HardwareKeyboard.instance.logicalKeysPressed.contains(
                    LogicalKeyboardKey.controlLeft,
                  )) {
                GestureBinding.instance.pointerSignalResolver.register(
                  event,
                  (e) {},
                );
              }
            },
            child: ReaderImage(
              url: page.url,
              headers: page.headers ?? const {},
              index: index,
              scaleType: prefs.scaleType,
              textColor: textColor,
            ),
          ),
        );
      },
    );
  }
}
