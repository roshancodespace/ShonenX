import 'package:flutter/material.dart';

class MarqueeText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final double velocity;

  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.velocity = 30.0,
  });

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText> {
  late ScrollController _scrollController;
  bool _isOverflowing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _checkOverflowAndStart(),
    );
  }

  @override
  void didUpdateWidget(MarqueeText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _checkOverflowAndStart(),
      );
    }
  }

  void _checkOverflowAndStart() async {
    if (!mounted || !_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll > 0) {
      if (!_isOverflowing) {
        setState(() => _isOverflowing = true);
      }
      _startLoop();
    } else {
      if (_isOverflowing) {
        setState(() => _isOverflowing = false);
      }
    }
  }

  void _startLoop() async {
    while (mounted && _scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      if (maxScroll <= 0) break;

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_scrollController.hasClients) break;

      final duration = Duration(
        milliseconds: (maxScroll / widget.velocity * 1000).toInt(),
      );
      await _scrollController.animateTo(
        maxScroll,
        duration: duration,
        curve: Curves.linear,
      );

      await Future.delayed(const Duration(seconds: 1));
      if (!mounted || !_scrollController.hasClients) break;

      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      child: Text(widget.text, style: widget.style, maxLines: 1),
    );
  }
}
