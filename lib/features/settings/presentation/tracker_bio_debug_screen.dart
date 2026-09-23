import 'package:flutter/material.dart';

import 'package:shonenx/features/tracking/presentation/widgets/tracker_bio_renderer.dart';

class TrackerBioDebugScreen extends StatefulWidget {
  const TrackerBioDebugScreen({super.key});

  @override
  State<TrackerBioDebugScreen> createState() => _TrackerBioDebugScreenState();
}

class _TrackerBioDebugScreenState extends State<TrackerBioDebugScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tracker Bio Debug')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 800;
          final children = [
            Expanded(
              child: TextField(
                controller: _controller,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  hintText: 'Enter Markdown bio here...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (isWide) const VerticalDivider() else const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: TrackerBioRenderer(bio: _controller.text),
              ),
            ),
          ];

          return isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                )
              : Column(children: children);
        },
      ),
    );
  }
}
