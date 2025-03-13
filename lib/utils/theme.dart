import 'package:flutter/material.dart';

BorderRadius? getCardBorderRadius(BuildContext context) {
  return Theme.of(context).cardTheme.shape is RoundedRectangleBorder
      ? (Theme.of(context).cardTheme.shape as RoundedRectangleBorder).borderRadius as BorderRadius?
      : null;
}
