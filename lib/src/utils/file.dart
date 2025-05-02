import 'package:video_js/src/models/file_range.dart';

class FileUtils {
  static FileRange? parseRangeHeader(String? rangeHeader, int totalLength) {
    if (rangeHeader == null || !rangeHeader.startsWith('bytes=')) return null;
    final parts = rangeHeader.replaceFirst('bytes=', '').split('-');
    final start = int.tryParse(parts[0]) ?? 0;
    final end = parts.length > 1 && parts[1].isNotEmpty ? int.tryParse(parts[1]) ?? totalLength - 1 : totalLength - 1;
    if (start > end || start >= totalLength) return null;
    return FileRange(start: start, end: end, length: end - start + 1);
  }
}
