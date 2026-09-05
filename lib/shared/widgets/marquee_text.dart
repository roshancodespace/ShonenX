import 'package:flutter/material.dart';

class MarqueeText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double velocity;
  final Duration pauseDuration;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 30.0,
    this.pauseDuration = const Duration(milliseconds: 1400),
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.hasBoundedWidth) {
          return Text(text, style: style, maxLines: 1);
        }

        // Measure rendered text width
        final textPainter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.maybeOf(context) ?? TextDirection.ltr,
        )..layout();

        // If text fits in available width, render static text with 0 overhead
        if (textPainter.width <= constraints.maxWidth) {
          return Text(text, style: style, maxLines: 1);
        }

        // Only mount animated scroller when text actually overflows
        return _MarqueeScroller(
          key: ValueKey(text),
          text: text,
          style: style,
          velocity: velocity > 0 ? velocity : 30.0,
          pauseDuration: pauseDuration,
        );
      },
    );
  }
}

class _MarqueeScroller extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity;
  final Duration pauseDuration;

  const _MarqueeScroller({
    super.key,
    required this.text,
    required this.style,
    required this.velocity,
    required this.pauseDuration,
  });

  @override
  State<_MarqueeScroller> createState() => _MarqueeScrollerState();
}

class _MarqueeScrollerState extends State<_MarqueeScroller> {
  late final ScrollController _scrollController;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scheduleLoop();
  }

  @override
  void didUpdateWidget(covariant _MarqueeScroller oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _scheduleLoop();
    }
  }

  void _scheduleLoop() {
    final currentGen = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || currentGen != _generation) return;
      _startLoop(currentGen);
    });
  }

  Future<void> _startLoop(int generation) async {
    // Wait for initial layout to settle
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted ||
        generation != _generation ||
        !_scrollController.hasClients) {
      return;
    }

    while (mounted &&
        generation == _generation &&
        _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) break;

      // Pause at start
      await Future.delayed(widget.pauseDuration);
      if (!mounted ||
          generation != _generation ||
          !_scrollController.hasClients) {
        break;
      }

      final currentMax = _scrollController.position.maxScrollExtent;
      if (currentMax <= 0) break;

      // Scroll smoothly to the end
      final duration = Duration(
        milliseconds: ((currentMax / widget.velocity) * 1000).round().clamp(
          400,
          40000,
        ),
      );

      try {
        await _scrollController.animateTo(
          currentMax,
          duration: duration,
          curve: Curves.linear,
        );
      } catch (_) {
        break;
      }

      if (!mounted ||
          generation != _generation ||
          !_scrollController.hasClients) {
        break;
      }

      // Pause at end
      await Future.delayed(widget.pauseDuration);
      if (!mounted ||
          generation != _generation ||
          !_scrollController.hasClients) {
        break;
      }

      // Smoothly return to start
      try {
        await _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      } catch (_) {
        break;
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(
        widget.text,
        style: widget.style,
        maxLines: 1,
        softWrap: false,
      ),
    );
  }
}
