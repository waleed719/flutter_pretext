import 'package:flutter/widgets.dart';
import 'package:dart_pretext/dart_pretext.dart';

/// A Flutter-specific implementation of the abstract [Font] interface.
/// Safely manages native [TextPainter] lifecycles and provides measurement capabilities.
class TextStyleFont extends Font {
  final TextStyle style;
  final TextDirection textDirection;

  TextStyleFont(this.style, {this.textDirection = TextDirection.ltr});

  @override
  double measureWidth(String seg) {
    final painter = TextPainter(
      text: TextSpan(text: seg, style: style),
      textDirection: textDirection,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TextStyleFont &&
          style == other.style &&
          textDirection == other.textDirection;

  @override
  int get hashCode => Object.hash(style, textDirection);
}
