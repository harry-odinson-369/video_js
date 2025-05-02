import 'dart:convert';
import 'dart:io';

import 'package:flutter_hls_parser/flutter_hls_parser.dart';
import 'package:http/http.dart' as http;
import 'package:video_js/src/utils/log.dart';

class HlsUtils {
  static Future<String> modifyUrls(
    String input, {
    required String? Function(String url, bool isMaster) replace,
  }) async {
    final parsed = await HlsPlaylistParser.create().parseString(
      Uri.parse(""),
      input,
    );
    List<String> lines = input.split("\n");
    Map<String, int> mappedIndex = {};

    for (int i = 0; i < lines.length; i++) {
      mappedIndex[lines[i].trim()] = i;
    }

    if (parsed is HlsMasterPlaylist) {
      int counter = 1;
      for (Variant variant in parsed.variants) {
        String url = variant.url.toString();
        int? index = mappedIndex[url.trim()];
        if (index != null) {
          String rh = Uri.encodeComponent(json.encode({
            HttpHeaders.contentTypeHeader: "application/vnd.apple.mpegurl",
            HttpHeaders.contentDisposition: 'attachment; filename="playlist_$counter.m3u"',
          }));
          String? newUrl = replace(url, true);
          if (newUrl != null) {
            newUrl = "$newUrl${!newUrl.contains("rh") ? "${newUrl.contains("?") ? "&" : "?"}rh=$rh" : ""}";
            String newLine = lines[index].replaceAll(url, newUrl);
            lines[index] = newLine;
          }
        }
      }
    }
    if (parsed is HlsMediaPlaylist) {
      int counter = 1;
      for (Segment segment in parsed.segments) {
        String? url = segment.url;
        if (url != null) {
          int? index = mappedIndex[url.trim()];
          if (index != null) {
            String? newUrl = replace(url, false);
            if (newUrl != null) {
              String rh = Uri.encodeComponent(json.encode({
                HttpHeaders.contentTypeHeader: "video/mp2t",
                HttpHeaders.contentDisposition: 'attachment; filename="seg_$counter.ts"',
              }));
              newUrl = "$newUrl${newUrl.contains("?") ? "&" : "?"}no-check=true&rh=$rh";
              String newLine = lines[index].replaceAll(url, newUrl);
              lines[index] = newLine;
              counter++;
            }
          }
        }
      }
    }
    String newContent = lines.join("\n");
    VideoJSLogger.showLog("New M3U8 content: $newContent");
    return newContent;
  }

  static Future<bool> isHlsFile(File file) async {
    try {
      final arr = await file.openRead().take(1).toList();
      String content = utf8.decode(arr.first);
      return content.trimLeft().startsWith("#EXTM3U");
    } catch(err) {
      VideoJSLogger.showLog("Error checking hls from file: ${file.path}\n${err.toString()}");
      return false;
    }
  }

  static Future<bool> isHls(String url, [Map<String, String>? headers]) async {
    http.Client client = http.Client();
    String body = "";
    try {
      http.Request request = http.Request("GET", Uri.parse(url));
      if (headers != null) request.headers.addAll(headers);
      final response = await client.send(request);
      final arr = await response.stream.take(1).toList();
      body = utf8.decode(arr.first);
    } catch (err) {
      VideoJSLogger.showLog("Error checking hls from url: $url\n${err.toString()}");
    } finally {
      client.close();
    }
    return body.trimLeft().startsWith("#EXTM3U");
  }
}
