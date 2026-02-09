import 'package:flutter/material.dart';

enum ResponsiveBreakpoint {
  compact,
  medium,
  expanded,
  ultra
}

ResponsiveBreakpoint responsiveBreakpoint(BuildContext context) {
   final width = MediaQuery.sizeOf(context).width;

  if (width < 480) return ResponsiveBreakpoint.compact;
  if (width < 900) return ResponsiveBreakpoint.medium;
  if (width < 1400) return ResponsiveBreakpoint.expanded;
  return ResponsiveBreakpoint.ultra;
}
