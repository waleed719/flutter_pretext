import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:flutter_pretext/flutter_pretext.dart';
import 'package:flutter_pretext/src/analysis.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Text Analysis & Segmentation', () {
    test('Basic segmentation splits words and spaces', () {
      final profile = AnalysisProfile();
      final analysis = analyzeText("Hello world! 123", profile);

      // Expected pieces roughly: "Hello", " ", "world!", " ", "123"
      expect(analysis.len, 5);
      expect(analysis.texts[0], "Hello");
      expect(analysis.kinds[0], SegmentBreakKind.text);
      expect(analysis.texts[1], " ");
      expect(analysis.kinds[1], SegmentBreakKind.space);
      expect(analysis.texts[2], "world!");
      expect(analysis.kinds[2], SegmentBreakKind.text);
    });

    test('Sticky punctuation merges leftward', () {
      final profile = AnalysisProfile();
      final analysis = analyzeText("Wait, no!", profile);

      // "Wait,", " ", "no!"
      expect(analysis.texts[0], "Wait,");
      expect(analysis.texts[2], "no!");
    });
  });

  group('Measurement and Layout', () {
    testWidgets('prepare measures segment lengths properly',
        (WidgetTester tester) async {
      const style = TextStyle(fontSize: 20);
      final prepared = prepare("Test string", style);

      expect(prepared.segments.length, 3); // "Test", " ", "string"
      expect(prepared.widths.length, 3);
      expect(prepared.widths[0] > 0, true);
    });

    testWidgets('layout calculates line breaks accurately without strings',
        (WidgetTester tester) async {
      const style = TextStyle(fontSize: 20);
      const text = "This is a surprisingly long string designed to wrap.";
      final prepared = prepare(text, style);

      // Calculate pure width
      final naturalW = measureNaturalWidth(prepared);
      expect(naturalW > 0, true);

      // Layout mathematically in a narrow box
      final resultNarrow = layout(prepared, 100.0, 24.0);
      expect(resultNarrow.lineCount > 1, true);

      // Layout mathematically in a wide box
      final resultWide = layout(prepared, 5000.0, 24.0);
      expect(resultWide.lineCount, 1);
    });

    testWidgets('layoutWithLines returns correct substrings mapped to lines',
        (WidgetTester tester) async {
      const style = TextStyle(fontSize: 20);
      const text = "First second third";
      final prepared = prepare(text, style);

      // Should wrap every word onto a new line if width is tightly restricted.
      // TextPainter usually needs a min intrinsic widths so we set something tight.
      final result = layoutWithLines(prepared, 50.0, 24.0);
      
      expect(result.lineCount, greaterThan(1));
      
      // Ensure all reconstructed text combined matches original characters
      final combined = result.lines.map((l) => l.text).join('').replaceAll(' ', '');
      final originalNoSpace = text.replaceAll(' ', '');
      
      expect(combined, originalNoSpace);
    });

    testWidgets('measureNaturalWidth matches underlying TextPainter closely',
        (WidgetTester tester) async {
      const style = TextStyle(fontSize: 16);
      const text = "Shrink wrap test";
      final prepared = prepare(text, style);

      final mathWidth = measureNaturalWidth(prepared);

      final painter = TextPainter(
        text: const TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
      )..layout();

      // Should be roughly equal (account for minor float mismatches)
      expect((mathWidth - painter.width).abs() < 1.0, true);
    });
  });

  group('Dynamic Layout Iterators', () {
    testWidgets('layoutNextLine adapts to custom width queries',
        (WidgetTester tester) async {
      const style = TextStyle(fontSize: 16);
      const text = "A really long paragraph that wraps";
      final prepared = prepare(text, style);

      // First line gets 1000px, second gets 50px
      var cursor = LayoutCursor(segmentIndex: 0, graphemeIndex: 0);
      
      final line1 = layoutNextLine(prepared, cursor, 1000.0);
      expect(line1, isNotNull);
      // Because width is 1000px, the first line should easily consume all words
      expect(line1!.text, text);
    });
  });
}
