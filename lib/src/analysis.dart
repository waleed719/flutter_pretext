import 'package:characters/characters.dart';

enum WhiteSpaceMode { normal, preWrap }

enum SegmentBreakKind {
  text,
  space,
  preservedSpace,
  tab,
  glue,
  zeroWidthBreak,
  softHyphen,
  hardBreak
}

class MergedSegmentation {
  final int len;
  final List<String> texts;
  final List<bool> isWordLike;
  final List<SegmentBreakKind> kinds;
  final List<int> starts;

  MergedSegmentation({
    required this.len,
    required this.texts,
    required this.isWordLike,
    required this.kinds,
    required this.starts,
  });
}

class AnalysisChunk {
  final int startSegmentIndex;
  final int endSegmentIndex;
  final int consumedEndSegmentIndex;

  AnalysisChunk({
    required this.startSegmentIndex,
    required this.endSegmentIndex,
    required this.consumedEndSegmentIndex,
  });
}

class TextAnalysis extends MergedSegmentation {
  final String normalized;
  final List<AnalysisChunk> chunks;

  TextAnalysis({
    required this.normalized,
    required this.chunks,
    required super.len,
    required super.texts,
    required super.isWordLike,
    required super.kinds,
    required super.starts,
  });
}

class AnalysisProfile {
  final bool carryCJKAfterClosingQuote;
  AnalysisProfile({this.carryCJKAfterClosingQuote = true});
}

class WhiteSpaceProfile {
  final WhiteSpaceMode mode;
  final bool preserveOrdinarySpaces;
  final bool preserveHardBreaks;

  WhiteSpaceProfile({
    required this.mode,
    required this.preserveOrdinarySpaces,
    required this.preserveHardBreaks,
  });
}

WhiteSpaceProfile getWhiteSpaceProfile(WhiteSpaceMode? mode) {
  final resolvedMode = mode ?? WhiteSpaceMode.normal;
  return resolvedMode == WhiteSpaceMode.preWrap
      ? WhiteSpaceProfile(
          mode: resolvedMode,
          preserveOrdinarySpaces: true,
          preserveHardBreaks: true)
      : WhiteSpaceProfile(
          mode: resolvedMode,
          preserveOrdinarySpaces: false,
          preserveHardBreaks: false);
}

final _collapsibleWhitespaceRunRe = RegExp(r'[ \t\n\r\f]+');
final _needsWhitespaceNormalizationRe = RegExp(r'[\t\n\r\f]| {2,}|^ | $');

String normalizeWhitespaceNormal(String text) {
  if (!_needsWhitespaceNormalizationRe.hasMatch(text)) return text;
  var normalized = text.replaceAll(_collapsibleWhitespaceRunRe, ' ');
  if (normalized.isNotEmpty && normalized.codeUnitAt(0) == 0x20) {
    normalized = normalized.substring(1);
  }
  if (normalized.isNotEmpty &&
      normalized.codeUnitAt(normalized.length - 1) == 0x20) {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

String normalizeWhitespacePreWrap(String text) {
  if (!RegExp(r'[\r\f]').hasMatch(text)) {
    return text.replaceAll('\r\n', '\n');
  }
  return text.replaceAll('\r\n', '\n').replaceAll(RegExp(r'[\r\f]'), '\n');
}

final _wordLikeRe = RegExp(r'^[\p{L}\p{N}_\-]+$', unicode: true);
final _segmentSplitterRe = RegExp(r'[\p{L}\p{N}_]+|[^\p{L}\p{N}_\s]+|\s+', unicode: true);

bool isCJK(String s) {
  for (int i = 0; i < s.length; i++) {
    int c = s.codeUnitAt(i);
    if ((c >= 0x4E00 && c <= 0x9FFF) ||
        (c >= 0x3400 && c <= 0x4DBF) ||
        (c >= 0x3000 && c <= 0x303F) ||
        (c >= 0x3040 && c <= 0x309F) ||
        (c >= 0x30A0 && c <= 0x30FF) ||
        (c >= 0xAC00 && c <= 0xD7AF) ||
        (c >= 0xFF00 && c <= 0xFFEF)) {
      return true;
    }
  }
  return false;
}

final leftStickyPunctuation = {
  '.', ',', '!', '?', ':', ';', ')', ']', '}', '%', '"', '”', '’', '»', '›', '…'
};

bool isLeftStickyPunctuationSegment(String segment) {
  bool sawPunctuation = false;
  for (int i = 0; i < segment.length; i++) {
    if (leftStickyPunctuation.contains(segment[i])) {
      sawPunctuation = true;
      continue;
    }
    return false;
  }
  return sawPunctuation;
}

SegmentBreakKind classifySegmentBreakChar(String ch, WhiteSpaceProfile profile) {
  if (profile.preserveOrdinarySpaces || profile.preserveHardBreaks) {
    if (ch == ' ') return SegmentBreakKind.preservedSpace;
    if (ch == '\t') return SegmentBreakKind.tab;
    if (profile.preserveHardBreaks && ch == '\n') return SegmentBreakKind.hardBreak;
  }
  if (ch == ' ') return SegmentBreakKind.space;
  if (ch == '\u00A0' || ch == '\u202F' || ch == '\u2060' || ch == '\uFEFF') {
    return SegmentBreakKind.glue;
  }
  if (ch == '\u200B') return SegmentBreakKind.zeroWidthBreak;
  if (ch == '\u00AD') return SegmentBreakKind.softHyphen;
  return SegmentBreakKind.text;
}

class SegmentationPiece {
  final String text;
  final bool isWordLike;
  final SegmentBreakKind kind;
  final int start;

  SegmentationPiece({
    required this.text,
    required this.isWordLike,
    required this.kind,
    required this.start,
  });
}

List<SegmentationPiece> splitSegmentByBreakKind(
    String segment, bool isWordLike, int start, WhiteSpaceProfile profile) {
  List<SegmentationPiece> pieces = [];
  SegmentBreakKind? currentKind;
  String currentText = '';
  int currentStart = start;
  bool currentWordLike = false;
  int offset = 0;

  for (final ch in segment.characters) {
    final kind = classifySegmentBreakChar(ch, profile);
    final wordLike = kind == SegmentBreakKind.text && isWordLike;

    if (currentKind != null && kind == currentKind && wordLike == currentWordLike) {
      currentText += ch;
      offset += ch.length;
      continue;
    }

    if (currentKind != null) {
      pieces.add(SegmentationPiece(
          text: currentText,
          isWordLike: currentWordLike,
          kind: currentKind,
          start: currentStart));
    }

    currentKind = kind;
    currentText = ch;
    currentStart = start + offset;
    currentWordLike = wordLike;
    offset += ch.length;
  }

  if (currentKind != null) {
    pieces.add(SegmentationPiece(
        text: currentText,
        isWordLike: currentWordLike,
        kind: currentKind,
        start: currentStart));
  }

  return pieces;
}

MergedSegmentation buildMergedSegmentation(
  String normalized,
  AnalysisProfile profile,
  WhiteSpaceProfile whiteSpaceProfile,
) {
  List<String> mergedTexts = [];
  List<bool> mergedWordLike = [];
  List<SegmentBreakKind> mergedKinds = [];
  List<int> mergedStarts = [];

  final matches = _segmentSplitterRe.allMatches(normalized);
  int globalIndex = 0;

  for (final match in matches) {
    String segmentText = match.group(0)!;
    bool wordLike = _wordLikeRe.hasMatch(segmentText);

    for (var piece in splitSegmentByBreakKind(
        segmentText, wordLike, globalIndex, whiteSpaceProfile)) {
      bool isText = piece.kind == SegmentBreakKind.text;

      if (isText &&
          mergedTexts.isNotEmpty &&
          mergedKinds.last == SegmentBreakKind.text &&
          (!piece.isWordLike && isLeftStickyPunctuationSegment(piece.text))) {
        // Merge sticky punctuation leftwards
        mergedTexts.last += piece.text;
      } else {
        mergedTexts.add(piece.text);
        mergedWordLike.add(piece.isWordLike);
        mergedKinds.add(piece.kind);
        mergedStarts.add(piece.start);
      }
    }
    globalIndex += segmentText.length;
  }

  return MergedSegmentation(
      len: mergedTexts.length,
      texts: mergedTexts,
      isWordLike: mergedWordLike,
      kinds: mergedKinds,
      starts: mergedStarts);
}

List<AnalysisChunk> compileAnalysisChunks(
    MergedSegmentation segmentation, WhiteSpaceProfile profile) {
  if (segmentation.len == 0) return [];
  if (!profile.preserveHardBreaks) {
    return [
      AnalysisChunk(
          startSegmentIndex: 0,
          endSegmentIndex: segmentation.len,
          consumedEndSegmentIndex: segmentation.len)
    ];
  }

  List<AnalysisChunk> chunks = [];
  int startSegmentIndex = 0;

  for (int i = 0; i < segmentation.len; i++) {
    if (segmentation.kinds[i] != SegmentBreakKind.hardBreak) continue;

    chunks.add(AnalysisChunk(
        startSegmentIndex: startSegmentIndex,
        endSegmentIndex: i,
        consumedEndSegmentIndex: i + 1));
    startSegmentIndex = i + 1;
  }

  if (startSegmentIndex < segmentation.len) {
    chunks.add(AnalysisChunk(
        startSegmentIndex: startSegmentIndex,
        endSegmentIndex: segmentation.len,
        consumedEndSegmentIndex: segmentation.len));
  }

  return chunks;
}

TextAnalysis analyzeText(String text, AnalysisProfile profile,
    {WhiteSpaceMode whiteSpace = WhiteSpaceMode.normal}) {
  final whiteSpaceProfile = getWhiteSpaceProfile(whiteSpace);
  final normalized = whiteSpaceProfile.mode == WhiteSpaceMode.preWrap
      ? normalizeWhitespacePreWrap(text)
      : normalizeWhitespaceNormal(text);

  if (normalized.isEmpty) {
    return TextAnalysis(
        normalized: normalized,
        chunks: [],
        len: 0,
        texts: [],
        isWordLike: [],
        kinds: [],
        starts: []);
  }

  final segmentation =
      buildMergedSegmentation(normalized, profile, whiteSpaceProfile);
  final chunks = compileAnalysisChunks(segmentation, whiteSpaceProfile);

  return TextAnalysis(
      normalized: normalized,
      chunks: chunks,
      len: segmentation.len,
      texts: segmentation.texts,
      isWordLike: segmentation.isWordLike,
      kinds: segmentation.kinds,
      starts: segmentation.starts);
}
