import 'package:flutter/material.dart';
import 'package:flutter_xlider/flutter_xlider.dart';

class SeekBar extends StatefulWidget {
  final Duration position;
  final Duration duration;
  final void Function(Duration) onSeek;
  final ThemeData theme;

  const SeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.theme,
  });

  @override
  State<SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<SeekBar> {
  double _currentPosition = 0;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.position.inSeconds.toDouble();
  }

  @override
  void didUpdateWidget(SeekBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update the current position if the widget's position changes
    if (oldWidget.position != widget.position) {
      setState(() {
        _currentPosition = widget.position.inSeconds.toDouble();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxDuration = widget.duration.inSeconds > 0
        ? widget.duration.inSeconds.toDouble()
        : 1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate a responsive height based on screen size
        final screenHeight = MediaQuery.of(context).size.height;
        final isLandscape =
            MediaQuery.of(context).orientation == Orientation.landscape;
        final sliderHeight =
            isLandscape ? screenHeight * 0.1 : screenHeight * 0.05;
        final handlerHeight = sliderHeight * 0.4; // Responsive handler height
        final handlerWidth =
            constraints.maxWidth * 0.005; // Responsive handler width

        return SizedBox(
          height:
              sliderHeight.clamp(20, 30), // Ensure a minimum and maximum height
          child: FlutterSlider(
            values: [_currentPosition],
            min: 0,
            max: maxDuration,
            handler: FlutterSliderHandler(
              decoration: BoxDecoration(
                color: widget.theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const SizedBox.shrink(),
            ),
            trackBar: FlutterSliderTrackBar(
              activeTrackBar: BoxDecoration(
                color: widget.theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(4),
              ),
              inactiveTrackBar: BoxDecoration(
                color: widget.theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              activeTrackBarHeight: 4,
              inactiveTrackBarHeight: 4,
            ),
            handlerHeight: handlerHeight,
            handlerWidth: handlerWidth,
            onDragging: (handlerIndex, lowerValue, upperValue) {
              setState(() {
                _currentPosition = lowerValue as double;
              });
            },
            onDragCompleted: (handlerIndex, lowerValue, upperValue) {
              final newPosition = Duration(seconds: lowerValue.toInt());
              widget.onSeek(newPosition);
              setState(() {
                _currentPosition = newPosition.inSeconds.toDouble();
              });
            },
          ),
        );
      },
    );
  }
}
