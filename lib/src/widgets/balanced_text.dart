import 'package:flutter/widgets.dart';
import '../layout.dart';

class BalancedText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double lineHeight;
  
  const BalancedText(this.text, this.style, this.lineHeight, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final prepared = prepare(text, style);
      
      final minLinesCount = layout(prepared, constraints.maxWidth, lineHeight).lineCount;
      
      double low = 0;
      double high = constraints.maxWidth;
      double optimal = high;
      
      for(int i = 0; i < 15; i++) { 
        final mid = (low + high) / 2;
        if (layout(prepared, mid, lineHeight).lineCount <= minLinesCount) {
           optimal = mid;
           high = mid; 
        } else {
           low = mid; 
        }
      }
      
      final result = layoutWithLines(prepared, optimal + 1, lineHeight);

      return SizedBox(
        width: optimal + 1,
        height: result.height,
        child: CustomPaint(
          painter: _LinesPainter(result.lines, style, lineHeight),
        ),
      );
    });
  }
}

class _LinesPainter extends CustomPainter {
  final List<LayoutLine> lines;
  final TextStyle style;
  final double lineHeight;

  _LinesPainter(this.lines, this.style, this.lineHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final painter = TextPainter(textDirection: TextDirection.ltr);
    double y = 0;
    for (final line in lines) {
      painter.text = TextSpan(text: line.text, style: style);
      painter.layout();
      painter.paint(canvas, Offset(0, y));
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _LinesPainter old) => false;
}
