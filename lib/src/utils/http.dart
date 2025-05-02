import 'dart:convert';

import 'package:http/http.dart';
import 'package:video_js/src/utils/log.dart';

class HttpUtils {
  static Future<StreamedResponse?> send(
    String url, {
    Map<String, String>? headers,
    String method = "GET",
    String? body,
  }) async {
    Client client = Client();
    try {
      Request request = Request(method, Uri.parse(url));
      if (headers != null && headers.entries.isNotEmpty) {
        request.headers.addAll(headers);
      }
      if (method != "HEAD" && method != "GET" && body != null) {
        request.bodyBytes = utf8.encode(body);
      }
      final response = await client.send(request);
      return response;
    } catch (err) {
      VideoJSLogger.showLog("Http Error: ${err.toString()}");
      return null;
    }
  }
}
