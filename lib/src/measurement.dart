import 'package:flutter/widgets.dart';
import 'analysis.dart';

class SegmentMetrics {
  final double width;
  final bool containsCJK;
  List<double>? graphemeWidths;
  List<double>? graphemePrefixWidths;

  SegmentMetrics({required this.width, required this.containsCJK});
}

class EngineProfile {
  final double lineFitEpsilon;
  final bool carryCJKAfterClosingQuote;
  final bool preferPrefixWidthsForBreakableRuns;
  final bool preferEarlySoftHyphenBreak;

  EngineProfile({
    this.lineFitEpsilon = 0.005,
    this.carryCJKAfterClosingQuote = false,
    this.preferPrefixWidthsForBreakableRuns = false,
    this.preferEarlySoftHyphenBreak = false,
  });
}

final _segmentMetricCaches = <TextStyle, Map<String, SegmentMetrics>>{};
EngineProfile? _cachedEngineProfile;

EngineProfile getEngineProfile() {
  _cachedEngineProfile ??= EngineProfile();
  return _cachedEngineProfile!;
}

Map<String, SegmentMetrics> getSegmentMetricCache(TextStyle style) {
  if (!_segmentMetricCaches.containsKey(style)) {
    _segmentMetricCaches[style] = {};
  }
  return _segmentMetricCaches[style]!;
}

SegmentMetrics getSegmentMetrics(
  String seg,
  Map<String, SegmentMetrics> cache,
  TextStyle style,
) {
  var metrics = cache[seg];
  if (metrics == null) {
    final painter = TextPainter(
      text: TextSpan(text: seg, style: style),
      textDirection: TextDirection.ltr,
    )..layout();

    metrics = SegmentMetrics(width: painter.width, containsCJK: isCJK(seg));
    cache[seg] = metrics;
  }
  return metrics;
}

List<double>? getSegmentGraphemeWidths(
  String seg,
  SegmentMetrics metrics,
  Map<String, SegmentMetrics> cache,
  TextStyle style,
) {
  if (metrics.graphemeWidths != null) return metrics.graphemeWidths;

  List<double> widths = [];
  for (final gs in seg.characters) {
    var gsMetrics = getSegmentMetrics(gs, cache, style);
    widths.add(gsMetrics.width);
  }

  metrics.graphemeWidths = widths.length > 1 ? widths : null;
  return metrics.graphemeWidths;
}

List<double>? getSegmentGraphemePrefixWidths(
  String seg,
  SegmentMetrics metrics,
  Map<String, SegmentMetrics> cache,
  TextStyle style,
) {
  if (metrics.graphemePrefixWidths != null) return metrics.graphemePrefixWidths;

  List<double> prefixWidths = [];
  String prefix = '';
  for (final gs in seg.characters) {
    prefix += gs;
    var prefixMetrics = getSegmentMetrics(prefix, cache, style);
    prefixWidths.add(prefixMetrics.width);
  }

  metrics.graphemePrefixWidths = prefixWidths.length > 1 ? prefixWidths : null;
  return metrics.graphemePrefixWidths;
}

void clearMeasurementCaches() {
  _segmentMetricCaches.clear();
}
