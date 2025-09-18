import 'package:flutter/material.dart';
import 'package:shonenx/utils/html_parser.dart';

class AnimeSynopsis extends StatefulWidget {
  final String description;
  final double collapsedHeight;

  const AnimeSynopsis({
    super.key,
    required this.description,
    this.collapsedHeight = 150,
  });

  @override
  State<AnimeSynopsis> createState() => _AnimeSynopsisState();
}

class _AnimeSynopsisState extends State<AnimeSynopsis>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: _isExpanded
                ? const BoxConstraints() // no height limit
                : BoxConstraints(maxHeight: widget.collapsedHeight),
            child: Text(
              parseHtmlToString(widget.description),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              softWrap: true,
              overflow: TextOverflow.fade,
            ),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          child: Text(_isExpanded ? 'Show Less' : 'Read More'),
        ),
      ],
    );
  }
}
