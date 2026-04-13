import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_pretext/flutter_pretext.dart';

class ShapedTextDemo extends StatefulWidget {
  const ShapedTextDemo({super.key});

  @override
  State<ShapedTextDemo> createState() => _ShapedTextDemoState();
}

class _ShapedTextDemoState extends State<ShapedTextDemo> {
  String _selectedShape = 'Circle';
  final List<String> _shapes = ['Circle', 'Triangle', 'Diamond'];

  @override
  Widget build(BuildContext context) {
    final style =
        TextStyle(fontSize: 14, color: Colors.indigo[900], height: 1.1);
    const lorem =
        "You can write pure mathematical equations to bound the layout iterator. Here, an iterator maps over the formula for a geometric shape. The text effortlessly pours into the boundary natively. \n\nNo longer are you bound to purely rectangular boxes in UI design. Graphic design paradigms reserved only for digital magazines and photoshop documents can now run seamlessly in Flutter. This solves some of the most difficult challenges in modern fluid typographics.";

    late PreparedText prepared;
    try {
      prepared = prepare(lorem, TextStyleFont(style));
    } catch (_) {
      // In case prepare fails before initialization
      prepared = prepare(" ", TextStyleFont(style));
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Mathematical Wrapper: $_selectedShape",
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 10),
          DropdownButton<String>(
            value: _selectedShape,
            items: _shapes
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedShape = val);
            },
          ),
          const SizedBox(height: 20),
          Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.transparent),
            ),
            child: CustomPaint(
              painter: _ShapePainter(prepared, style, 14 * 1.1, _selectedShape),
            ),
          ),
        ],
      ),
    );
  }
}

class _ShapePainter extends CustomPainter {
  final PreparedText preparedText;
  final TextStyle style;
  final double lineHeight;
  final String shapeType;

  _ShapePainter(this.preparedText, this.style, this.lineHeight, this.shapeType);

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Draw the background shape using Canvas
    final paintShape = Paint()
      ..color = Colors.indigo.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final paintBorder = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (shapeType == 'Circle') {
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), size.width / 2, paintShape);
      canvas.drawCircle(
          Offset(size.width / 2, size.height / 2), size.width / 2, paintBorder);
    } else if (shapeType == 'Triangle') {
      Path p = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      canvas.drawPath(p, paintShape);
      canvas.drawPath(p, paintBorder);
    } else if (shapeType == 'Diamond') {
      Path p = Path()
        ..moveTo(size.width / 2, 0)
        ..lineTo(size.width, size.height / 2)
        ..lineTo(size.width / 2, size.height)
        ..lineTo(0, size.height / 2)
        ..close();
      canvas.drawPath(p, paintShape);
      canvas.drawPath(p, paintBorder);
    }

    // 2. Iterate text constrained to the mathematical shape bounds
    double y = 0;
    LayoutCursor cursor = LayoutCursor(segmentIndex: 0, graphemeIndex: 0);
    final painter = TextPainter(textDirection: TextDirection.ltr);

    while (cursor.segmentIndex < preparedText.widths.length) {
      if (y > size.height) break; // Overflow

      double availableWidth = 0;
      double xOffset = 0;

      if (shapeType == 'Circle') {
        double r = size.width / 2;
        double relY = y + lineHeight / 2 - r;
        if (relY <= -r || relY >= r) {
          y += lineHeight;
          continue;
        }
        double dx = math.sqrt(r * r - relY * relY);
        availableWidth = 2 * dx;
        xOffset = r - dx;
      } else if (shapeType == 'Triangle') {
        // Triangle from top center to bottom edges
        // Width grows linearly with y
        double relY = y + lineHeight;
        double ratio = relY / size.height;
        availableWidth = size.width * ratio;
        xOffset = (size.width - availableWidth) / 2;
      } else if (shapeType == 'Diamond') {
        double halfH = size.height / 2;
        double relY = y + lineHeight / 2;
        double ratio =
            relY < halfH ? relY / halfH : (size.height - relY) / halfH;
        availableWidth = size.width * ratio;
        xOffset = (size.width - availableWidth) / 2;
      }

      if (availableWidth > 15) {
        final line = layoutNextLine(preparedText, cursor, availableWidth);
        if (line != null) {
          painter.text = TextSpan(text: line.text, style: style);
          painter.textAlign = TextAlign.center;
          painter.layout(maxWidth: availableWidth, minWidth: availableWidth);
          painter.paint(canvas, Offset(xOffset, y));
          cursor = line.end;
        }
      }
      y += lineHeight;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePainter old) =>
      old.shapeType != shapeType || old.preparedText != preparedText;
}
