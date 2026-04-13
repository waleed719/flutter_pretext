import 'package:flutter/widgets.dart';
import 'package:dart_pretext/dart_pretext.dart';

class ObstacleTextFlow extends StatelessWidget {
  final PreparedText preparedText;
  final TextStyle textStyle;
  final List<Rect> obstacles;
  final double lineHeight;
  final bool wrapBothSides; // When true, text fills both sides of an obstacle.

  const ObstacleTextFlow({
    super.key,
    required this.preparedText,
    required this.textStyle,
    required this.obstacles,
    required this.lineHeight,
    this.wrapBothSides = true,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomPaint(
          size: Size(constraints.maxWidth, constraints.maxHeight),
          painter: _ObstacleTextPainter(preparedText, textStyle, obstacles, lineHeight, wrapBothSides),
        );
      }
    );
  }
}

class _Interval {
  double left;
  double right;
  double get width => right - left;
  _Interval(this.left, this.right);
}

class _ObstacleTextPainter extends CustomPainter {
  final PreparedText preparedText;
  final TextStyle textStyle;
  final List<Rect> obstacles;
  final double lineHeight;
  final bool wrapBothSides;

  _ObstacleTextPainter(this.preparedText, this.textStyle, this.obstacles, this.lineHeight, this.wrapBothSides);

  List<_Interval> _getFreeIntervals(double y, double totalWidth) {
    List<_Interval> blocked = [];
    for (final rect in obstacles) {
      if (y + lineHeight > rect.top && y < rect.bottom) {
        double start = rect.left < 0 ? 0 : rect.left;
        double end = rect.right > totalWidth ? totalWidth : rect.right;
        if (start < end) {
          blocked.add(_Interval(start, end));
        }
      }
    }
    
    if (blocked.isEmpty) return [_Interval(0, totalWidth)];
    
    blocked.sort((a,b) => a.left.compareTo(b.left));
    List<_Interval> merged = [];
    for (final b in blocked) {
      if (merged.isEmpty) {
        merged.add(b);
      } else {
        final last = merged.last;
        if (b.left <= last.right) {
          if (b.right > last.right) last.right = b.right;
        } else {
          merged.add(b);
        }
      }
    }
    
    List<_Interval> free = [];
    double currentX = 0;
    for (final b in merged) {
      if (b.left > currentX) {
        free.add(_Interval(currentX, b.left));
      }
      if (b.right > currentX) currentX = b.right;
    }
    if (currentX < totalWidth) {
      free.add(_Interval(currentX, totalWidth));
    }
    
    return free;
  }

  @override
  void paint(Canvas canvas, Size size) {
    LayoutCursor cursor = LayoutCursor(segmentIndex: 0, graphemeIndex: 0);
    double y = 0;

    final painter = TextPainter(textDirection: TextDirection.ltr);

    while (cursor.segmentIndex < preparedText.widths.length) {
      if (y > size.height) break; 

      final intervals = _getFreeIntervals(y, size.width);
      
      // If the user wants the default float behavior, skip the smaller chunks
      if (!wrapBothSides && intervals.isNotEmpty) {
        intervals.sort((a,b) => b.width.compareTo(a.width));
        final largest = intervals.first;
        intervals.clear();
        intervals.add(largest);
      }

      bool advancedThisLine = false;

      for (final interval in intervals) {
        if (interval.width < 15) continue; // Skip un-drawable thin strips

        final line = layoutNextLine(preparedText, cursor, interval.width);
        if (line != null) {
          painter.text = TextSpan(text: line.text, style: textStyle);
          painter.layout(maxWidth: interval.width);
          painter.paint(canvas, Offset(interval.left, y));
          
          cursor = line.end;
          advancedThisLine = true;
          
          if (cursor.segmentIndex >= preparedText.widths.length) break;
        }
      }

      // Automatically advance visually
      y += lineHeight;

      // Fail-safe if an obstacle blocks everything but we couldn't advance text
      if (!advancedThisLine && cursor.segmentIndex < preparedText.widths.length) {
        // The text is too thick to fit in this line's thin gaps, we just skip the line visually
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ObstacleTextPainter old) {
     return true;
  }
}
