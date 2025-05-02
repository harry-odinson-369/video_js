import 'dart:convert';

import 'package:video_js/src/extensions/video.dart';
import 'package:video_js/src/models/source.dart';

enum VideoJSType { mp4, m3u8, webm, mkv, avi, mov, flv, unset }

class VideoJSOptions {

  static const String _transparent = "data:image/gif;base64,R0lGODlhAQABAIAAAP///wAAACH5BAEAAAAALAAAAAABAAEAAAICRAEAOw==";

  /// The source url to play.
  String src = "";

  /// Set to [true] to auto play the video immediately after the initialization.
  bool? autoPlay;

  /// Set the video poster.
  String? poster;

  /// The [content-type] of the source url.
  VideoJSType? type;

  /// Set the request [headers] to the source [src] if needed. it work on [SourceType.network] only.
  Map<String, String>? headers;

  VideoJSOptions({
    this.autoPlay,
    this.poster,
    this.type,
    this.headers,
  });

  factory VideoJSOptions.defaultOptions() => VideoJSOptions(
    autoPlay: false,
    headers: null,
    type: null,
    poster: null,
  );

  VideoJSOptions copyWith({
    bool? autoPlay,
    String? poster,
    VideoJSType? type,
    Map<String, String>? headers,
  }) => VideoJSOptions(
    autoPlay: autoPlay ?? this.autoPlay,
    poster: poster ?? this.poster,
    type: type ?? this.type,
    headers: headers ?? this.headers,
  );

  String get encodedProps {
    final map = {
      "src": src,
      "poster": poster ?? VideoJSOptions._transparent,
      "autoplay": autoPlay,
      "type": type?.toMimeType,
    };
    return base64.encode(utf8.encode(json.encode(map)));
  }
}
