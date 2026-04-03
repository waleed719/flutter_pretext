import 'package:flutter/widgets.dart';
import 'analysis.dart';
import 'measurement.dart';
import 'line_break.dart';
export 'line_break.dart' show LineBreakCursor;
export 'analysis.dart' show WhiteSpaceMode;

class LayoutResult {
  final int lineCount;
  final double height;

  LayoutResult({required this.lineCount, required this.height});
}

class LayoutCursor {
  final int segmentIndex;
  final int graphemeIndex;

  LayoutCursor({required this.segmentIndex, required this.graphemeIndex});

  LineBreakCursor toLineBreak() =>
      LineBreakCursor(segmentIndex: segmentIndex, graphemeIndex: graphemeIndex);
  factory LayoutCursor.fromLineBreak(LineBreakCursor cursor) => LayoutCursor(
    segmentIndex: cursor.segmentIndex,
    graphemeIndex: cursor.graphemeIndex,
  );
}

class LayoutLineRange {
  final double width;
  final LayoutCursor start;
  final LayoutCursor end;

  LayoutLineRange({
    required this.width,
    required this.start,
    required this.end,
  });
}

class LayoutLine extends LayoutLineRange {
  final String text;

  LayoutLine({
    required this.text,
    required super.width,
    required super.start,
    required super.end,
  });
}

class LayoutLinesResult extends LayoutResult {
  final List<LayoutLine> lines;

  LayoutLinesResult({
    required super.lineCount,
    required super.height,
    required this.lines,
  });
}

class PreparedText extends PreparedLineBreakData {
  final List<String> segments;
  PreparedText({
    required this.segments,
    required super.widths,
    required super.kinds,
    required super.breakableWidths,
    required super.breakablePrefixWidths,
  });
}

PreparedText prepare(
  String text,
  TextStyle font, {
  WhiteSpaceMode whiteSpace = WhiteSpaceMode.normal,
}) {
  final profile = AnalysisProfile();
  final analysis = analyzeText(text, profile, whiteSpace: whiteSpace);

  if (analysis.len == 0) {
    return PreparedText(
      segments: [],
      widths: [],
      kinds: [],
      breakableWidths: [],
      breakablePrefixWidths: [],
    );
  }

  final cache = getSegmentMetricCache(font);
  final engineProfile = getEngineProfile();

  final List<double> widths = [];
  final List<SegmentBreakKind> kinds = [];
  final List<List<double>?> breakableWidths = [];
  final List<List<double>?> breakablePrefixWidths = [];
  final List<String> segments = [];

  for (int m = 0; m < analysis.len; m++) {
    final segText = analysis.texts[m];
    final segKind = analysis.kinds[m];

    if (segKind == SegmentBreakKind.softHyphen ||
        segKind == SegmentBreakKind.hardBreak ||
        segKind == SegmentBreakKind.tab) {
      widths.add(0);
      kinds.add(segKind);
      breakableWidths.add(null);
      breakablePrefixWidths.add(null);
      segments.add(segText);
      continue;
    }

    final segMetrics = getSegmentMetrics(segText, cache, font);
    widths.add(segMetrics.width);
    kinds.add(segKind);
    segments.add(segText);

    if (analysis.isWordLike[m] && segText.length > 1) {
      final gWidths = getSegmentGraphemeWidths(
        segText,
        segMetrics,
        cache,
        font,
      );
      breakableWidths.add(gWidths);
      final gpuPrefixWidths = engineProfile.preferPrefixWidthsForBreakableRuns
          ? getSegmentGraphemePrefixWidths(segText, segMetrics, cache, font)
          : null;
      breakablePrefixWidths.add(gpuPrefixWidths);
    } else {
      breakableWidths.add(null);
      breakablePrefixWidths.add(null);
    }
  }

  return PreparedText(
    segments: segments,
    widths: widths,
    kinds: kinds,
    breakableWidths: breakableWidths,
    breakablePrefixWidths: breakablePrefixWidths,
  );
}

LayoutResult layout(PreparedText prepared, double maxWidth, double lineHeight) {
  final count = countPreparedLines(prepared, maxWidth);
  return LayoutResult(lineCount: count, height: count * lineHeight);
}

void walkLineRanges(
  PreparedText prepared,
  double maxWidth,
  void Function(LayoutLineRange) onLine,
) {
  walkPreparedLinesSimple(prepared, maxWidth, (line) {
    onLine(
      LayoutLineRange(
        width: line.width,
        start: LayoutCursor(
          segmentIndex: line.startSegmentIndex,
          graphemeIndex: line.startGraphemeIndex,
        ),
        end: LayoutCursor(
          segmentIndex: line.endSegmentIndex,
          graphemeIndex: line.endGraphemeIndex,
        ),
      ),
    );
  });
}

double measureNaturalWidth(PreparedText prepared) {
  double maxW = 0;
  walkLineRanges(prepared, double.infinity, (line) {
    if (line.width > maxW) maxW = line.width;
  });
  return maxW;
}

String _buildLineTextFromRange(
  List<String> segments,
  List<SegmentBreakKind> kinds,
  int startSegment,
  int startGraph,
  int endSegment,
  int endGraph,
) {
  String text = '';
  for (int i = startSegment; i < endSegment; i++) {
    if (kinds[i] == SegmentBreakKind.softHyphen) continue;
    final chars = segments[i].characters;
    if (i == startSegment && startGraph > 0) {
      if (startGraph < chars.length) {
        text += chars.skip(startGraph).string;
      }
    } else {
      text += segments[i];
    }
  }
  if (endGraph > 0 && endSegment < segments.length) {
    if (kinds[endSegment] != SegmentBreakKind.softHyphen) {
      final chars = segments[endSegment].characters;
      text += chars.take(endGraph).string;
    }
  }
  return text;
}

LayoutLine? layoutNextLine(
  PreparedText prepared,
  LayoutCursor start,
  double maxWidth,
) {
  final line = layoutNextLineRangeSimple(
    prepared,
    start.toLineBreak(),
    maxWidth,
  );
  if (line == null) return null;

  final text = _buildLineTextFromRange(
    prepared.segments,
    prepared.kinds,
    line.startSegmentIndex,
    line.startGraphemeIndex,
    line.endSegmentIndex,
    line.endGraphemeIndex,
  );

  return LayoutLine(
    text: text,
    width: line.width,
    start: LayoutCursor(
      segmentIndex: line.startSegmentIndex,
      graphemeIndex: line.startGraphemeIndex,
    ),
    end: LayoutCursor(
      segmentIndex: line.endSegmentIndex,
      graphemeIndex: line.endGraphemeIndex,
    ),
  );
}

LayoutLinesResult layoutWithLines(
  PreparedText prepared,
  double maxWidth,
  double lineHeight,
) {
  List<LayoutLine> lines = [];
  LayoutCursor cursor = LayoutCursor(segmentIndex: 0, graphemeIndex: 0);

  while (cursor.segmentIndex < prepared.widths.length) {
    final nLine = layoutNextLine(prepared, cursor, maxWidth);
    if (nLine == null) break;
    lines.add(nLine);
    cursor = nLine.end;
  }
  return LayoutLinesResult(
    lineCount: lines.length,
    height: lines.length * lineHeight,
    lines: lines,
  );
}
