import 'package:flutter/widgets.dart';

/// Monospace that does not inherit the app's variable `wght` axis.
///
/// A null [TextStyle.fontVariations] means inherit. The engine also injects
/// `wght` from [TextStyle.fontWeight] when the list has no `wght`, so a normal
/// weight has to be set explicitly. On Linux that injected axis draws a
/// non-variable monospace face as zeros.
TextStyle monospaceTextStyle({
  required Color color,
  required double fontSize,
  double? height,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    height: height,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w400,
    fontVariations: const <FontVariation>[],
  );
}
