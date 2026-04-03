import 'analysis.dart';
import 'measurement.dart';

class LineBreakCursor {
  final int segmentIndex;
  final int graphemeIndex;

  LineBreakCursor({required this.segmentIndex, required this.graphemeIndex});
}

class PreparedLineBreakData {
  final List<double> widths;
  final List<SegmentBreakKind> kinds;
  final List<List<double>?> breakableWidths;
  final List<List<double>?> breakablePrefixWidths;

  PreparedLineBreakData({
    required this.widths,
    required this.kinds,
    required this.breakableWidths,
    required this.breakablePrefixWidths,
  });
}

class InternalLayoutLine {
  final int startSegmentIndex;
  final int startGraphemeIndex;
  final int endSegmentIndex;
  final int endGraphemeIndex;
  final double width;

  InternalLayoutLine({
    required this.startSegmentIndex,
    required this.startGraphemeIndex,
    required this.endSegmentIndex,
    required this.endGraphemeIndex,
    required this.width,
  });
}

bool canBreakAfter(SegmentBreakKind kind) {
  return kind == SegmentBreakKind.space ||
      kind == SegmentBreakKind.preservedSpace ||
      kind == SegmentBreakKind.tab ||
      kind == SegmentBreakKind.zeroWidthBreak ||
      kind == SegmentBreakKind.softHyphen;
}

double _getBreakableAdvance(List<double> graphemeWidths,
    List<double>? graphemePrefixWidths, int graphemeIndex, bool preferPrefix) {
  if (!preferPrefix || graphemePrefixWidths == null) {
    return graphemeWidths[graphemeIndex];
  }
  return graphemePrefixWidths[graphemeIndex] -
      (graphemeIndex > 0 ? graphemePrefixWidths[graphemeIndex - 1] : 0);
}

int normalizeSimpleLineStartSegmentIndex(
    PreparedLineBreakData prepared, int segmentIndex) {
  while (segmentIndex < prepared.widths.length) {
    final kind = prepared.kinds[segmentIndex];
    if (kind != SegmentBreakKind.space &&
        kind != SegmentBreakKind.zeroWidthBreak &&
        kind != SegmentBreakKind.softHyphen) {
      break;
    }
    segmentIndex++;
  }
  return segmentIndex;
}

LineBreakCursor normalizeLineStart(
    PreparedLineBreakData prepared, LineBreakCursor start) {
  int segmentIndex = start.segmentIndex;

  if (segmentIndex >= prepared.widths.length) return start;

  if (start.graphemeIndex > 0) return start;

  segmentIndex = normalizeSimpleLineStartSegmentIndex(prepared, segmentIndex);
  return LineBreakCursor(segmentIndex: segmentIndex, graphemeIndex: 0);
}

InternalLayoutLine? layoutNextLineRangeSimple(
    PreparedLineBreakData prepared, LineBreakCursor startRaw, double maxWidth) {
  final normalizedStart = normalizeLineStart(prepared, startRaw);
  if (normalizedStart.segmentIndex >= prepared.widths.length) return null;

  final widths = prepared.widths;
  final kinds = prepared.kinds;
  final breakableWidths = prepared.breakableWidths;
  final breakablePrefixWidths = prepared.breakablePrefixWidths;

  final engineProfile = getEngineProfile();
  final double lineFitEpsilon = engineProfile.lineFitEpsilon;

  double lineW = 0.0;
  bool hasContent = false;
  int lineStartSegmentIndex = normalizedStart.segmentIndex;
  int lineStartGraphemeIndex = normalizedStart.graphemeIndex;
  int lineEndSegmentIndex = lineStartSegmentIndex;
  int lineEndGraphemeIndex = lineStartGraphemeIndex;
  int pendingBreakSegmentIndex = -1;
  double pendingBreakPaintWidth = 0;

  InternalLayoutLine? finishLine({
    int? endSegmentIndex,
    int? endGraphemeIndex,
    double? width,
  }) {
    if (!hasContent) return null;
    return InternalLayoutLine(
      startSegmentIndex: lineStartSegmentIndex,
      startGraphemeIndex: lineStartGraphemeIndex,
      endSegmentIndex: endSegmentIndex ?? lineEndSegmentIndex,
      endGraphemeIndex: endGraphemeIndex ?? lineEndGraphemeIndex,
      width: width ?? lineW,
    );
  }

  void startLineAtSegment(int segmentIndex, double width) {
    hasContent = true;
    lineEndSegmentIndex = segmentIndex + 1;
    lineEndGraphemeIndex = 0;
    lineW = width;
  }

  void startLineAtGrapheme(int segmentIndex, int graphemeIndex, double width) {
    hasContent = true;
    lineEndSegmentIndex = segmentIndex;
    lineEndGraphemeIndex = graphemeIndex + 1;
    lineW = width;
  }

  void appendWholeSegment(int segmentIndex, double width) {
    if (!hasContent) {
      startLineAtSegment(segmentIndex, width);
      return;
    }
    lineW += width;
    lineEndSegmentIndex = segmentIndex + 1;
    lineEndGraphemeIndex = 0;
  }

  void updatePendingBreak(int segmentIndex, double segmentWidth) {
    if (!canBreakAfter(kinds[segmentIndex])) return;
    pendingBreakSegmentIndex = segmentIndex + 1;
    pendingBreakPaintWidth = lineW - segmentWidth;
  }

  InternalLayoutLine? appendBreakableSegmentFrom(
      int segmentIndex, int startGraphemeIndex) {
    final gWidths = breakableWidths[segmentIndex]!;
    final gPrefixWidths = breakablePrefixWidths[segmentIndex];
    for (int g = startGraphemeIndex; g < gWidths.length; g++) {
      final gw = _getBreakableAdvance(gWidths, gPrefixWidths, g,
          engineProfile.preferPrefixWidthsForBreakableRuns);

      if (!hasContent) {
        startLineAtGrapheme(segmentIndex, g, gw);
        continue;
      }

      if (lineW + gw > maxWidth + lineFitEpsilon) {
        return finishLine();
      }

      lineW += gw;
      lineEndSegmentIndex = segmentIndex;
      lineEndGraphemeIndex = g + 1;
    }

    if (hasContent &&
        lineEndSegmentIndex == segmentIndex &&
        lineEndGraphemeIndex == gWidths.length) {
      lineEndSegmentIndex = segmentIndex + 1;
      lineEndGraphemeIndex = 0;
    }
    return null;
  }

  for (int i = normalizedStart.segmentIndex; i < widths.length; i++) {
    final w = widths[i];
    final kind = kinds[i];
    final startGraphemeIndex =
        (i == normalizedStart.segmentIndex) ? normalizedStart.graphemeIndex : 0;

    if (!hasContent) {
      if (startGraphemeIndex > 0) {
        final line = appendBreakableSegmentFrom(i, startGraphemeIndex);
        if (line != null) return line;
      } else if (w > maxWidth && breakableWidths[i] != null) {
        final line = appendBreakableSegmentFrom(i, 0);
        if (line != null) return line;
      } else {
        startLineAtSegment(i, w);
      }
      updatePendingBreak(i, w);
      continue;
    }

    final newW = lineW + w;
    if (newW > maxWidth + lineFitEpsilon) {
      if (canBreakAfter(kind)) {
        appendWholeSegment(i, w);
        return finishLine(
            endSegmentIndex: i + 1, endGraphemeIndex: 0, width: lineW - w);
      }

      if (pendingBreakSegmentIndex >= 0) {
        if (lineEndSegmentIndex > pendingBreakSegmentIndex ||
            (lineEndSegmentIndex == pendingBreakSegmentIndex &&
                lineEndGraphemeIndex > 0)) {
          return finishLine();
        }
        return finishLine(
            endSegmentIndex: pendingBreakSegmentIndex,
            endGraphemeIndex: 0,
            width: pendingBreakPaintWidth);
      }

      if (w > maxWidth && breakableWidths[i] != null) {
        final currentLine = finishLine();
        if (currentLine != null) return currentLine;
        final line = appendBreakableSegmentFrom(i, 0);
        if (line != null) return line;
      }

      return finishLine();
    }

    appendWholeSegment(i, w);
    updatePendingBreak(i, w);
  }

  return finishLine();
}

int walkPreparedLinesSimple(
  PreparedLineBreakData prepared,
  double maxWidth,
  void Function(InternalLayoutLine line)? onLine,
) {
  int lineCount = 0;
  LineBreakCursor cursor = LineBreakCursor(segmentIndex: 0, graphemeIndex: 0);

  while (true) {
    if (cursor.segmentIndex >= prepared.widths.length) break;
    final line = layoutNextLineRangeSimple(prepared, cursor, maxWidth);
    if (line == null) break;
    lineCount++;
    if (onLine != null) onLine(line);
    cursor = LineBreakCursor(
        segmentIndex: line.endSegmentIndex,
        graphemeIndex: line.endGraphemeIndex);
  }

  return lineCount;
}

int countPreparedLines(PreparedLineBreakData prepared, double maxWidth) {
  return walkPreparedLinesSimple(prepared, maxWidth, null);
}
