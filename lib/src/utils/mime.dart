import 'dart:io';

import 'package:video_js/src/models/options.dart';
import 'package:video_js/src/utils/hls.dart';

class MimeUtils {
  static Future<VideoJSType> findType(
    String src, [
    Map<String, String>? headers,
  ]) async {
    for (VideoJSType type in VideoJSType.values) {
      if (src.toLowerCase().contains(type.name)) {
        return type;
      }
    }

    if (!src.startsWith("http")) {
      bool isHls = await HlsUtils.isHlsFile(File(src));
      return isHls ? VideoJSType.m3u8 : VideoJSType.mp4;
    } else {
      bool isHls = await HlsUtils.isHls(src, headers);
      return isHls ? VideoJSType.m3u8 : VideoJSType.mp4;
    }
  }
}
