import 'package:flutter/widgets.dart';
import '../layout.dart';

class ShrinkWrapText extends StatelessWidget {
  final String text;
  final TextStyle style;
  final double lineHeight;
  
  const ShrinkWrapText(this.text, this.style, this.lineHeight, {super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final prepared = prepare(text, style);
      
      double maxW = measureNaturalWidth(prepared);
      double naturalWidth = maxW > constraints.maxWidth ? constraints.maxWidth : maxW;
      
      final result = layoutWithLines(prepared, naturalWidth, lineHeight);

      return SizedBox(
        width: naturalWidth,
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
