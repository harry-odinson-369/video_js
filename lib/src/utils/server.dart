import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart' as mime;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart' as router;
import 'package:shelf_web_socket/shelf_web_socket.dart';
import 'package:video_js/src/models/file_range.dart';
import 'package:video_js/src/models/source.dart';
import 'package:video_js/src/utils/file.dart';
import 'package:video_js/src/utils/generate.dart';
import 'package:video_js/src/utils/hls.dart';
import 'package:video_js/src/utils/http.dart';
import 'package:video_js/src/utils/log.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:video_js/src/utils/assets.dart';

int _port = 3698;
String _address = "127.0.0.1";

class VideoJSServer {
  String get address => _address;
  set address(String adr) {
    _address = adr;
  }

  int get port => _port;
  set port(int p) {
    _port = p;
  }

  final String protocol = "http";

  String get url => "$protocol://$address:$port";

  HttpServer? _server;
  WebSocketChannel? _channel;

  StreamController<dynamic>? _controller;
  StreamSubscription<dynamic>? _subscription;

  VideoJSServer({String? address, int? port}) {
    _address = address ?? _address;
    _port = port ?? _port;
    _controller = StreamController<dynamic>.broadcast();
  }

  Stream<dynamic>? get onMessage => _controller?.stream;

  Future sendMessage(String msg) async => _channel?.sink.add(msg);

  String proxy(
    String d, {
    Map<String, String>? headers,
    SourceType sourceType = SourceType.network,
  }) {
    return "$url/${sourceType.name}?d=${Uri.encodeComponent(d)}${headers != null ? "&h=${Uri.encodeComponent(json.encode(headers))}" : ""}";
  }

  Future<Response> _rootHandler(Request request) async {
    String? file = request.url.queryParameters["asset"];
    if (file != null) {
      file = Uri.decodeComponent(file);
      final asset = AssetsUtils.assets(file);
      final data = await rootBundle.load(asset);
      return Response(
        HttpStatus.ok,
        body: data.buffer.asUint8List(),
        headers: {
          HttpHeaders.contentTypeHeader:
              mime.lookupMimeType(file) ?? "application/octet-stream",
        },
      );
    } else {
      final data = await rootBundle.load(AssetsUtils.assets("index.html"));
      return Response(
        HttpStatus.ok,
        body: data.buffer.asUint8List(),
        headers: {HttpHeaders.contentTypeHeader: "text/html"},
      );
    }
  }

  Future<Response> _requestResponse(
    String d,
    Request request, [
    Map<String, String>? headers,
    Map<String, String>? respHeaders,
  ]) async {
    http.StreamedResponse? response = await HttpUtils.send(
      d,
      headers: headers,
      method: request.method,
      body: await request.readAsString(),
    );
    if (response == null) return Response.internalServerError();
    return Response(
      response.statusCode,
      body: response.stream,
      headers: response.headers..addAll(respHeaders ?? {}),
    );
  }

  Future<Response> _proxyHandler(Request request) async {
    String? d = request.url.queryParameters["d"];
    String? h = request.url.queryParameters["h"];
    String? rh = request.url.queryParameters["rh"];
    bool noHlsCheck = request.url.queryParameters["no-check"] == "true";
    if (noHlsCheck) {
      VideoJSLogger.showLog("Proxying without checking file format!");
    }
    if (d == null) return Response.badRequest();
    d = Uri.decodeComponent(d);
    Map<String, String>? headers;
    if (h != null) {
      h = Uri.decodeComponent(h);
      headers = GenerateUtils.parseHeaders<String, String>(h);
    }
    Map<String, String>? respHeaders;
    if (rh != null) {
      rh = Uri.decodeComponent(rh);
      respHeaders = GenerateUtils.parseHeaders(rh);
    }
    if (!noHlsCheck) {
      bool isHls = await HlsUtils.isHls(d, headers);
      if (isHls) {
        final response = await http.get(Uri.parse(d), headers: headers);
        String newContent = await HlsUtils.modifyUrls(
          response.body,
          replace: (uri, isMaster) {
            if (uri.startsWith(url)) {
              // Skip this replacement since it has already replaced with proxy.
              return null;
            } else {
              if (uri.startsWith("http")) {
                return proxy(uri, headers: headers);
              } else {
                return proxy(
                  Uri.parse(d!).resolve(uri).toString(),
                  headers: headers,
                );
              }
            }
          },
        );
        response.headers[HttpHeaders.contentTypeHeader] =
            "application/vnd.apple.mpegurl";
        response.headers[HttpHeaders.contentDisposition] =
            'attachment; filename="index.m3u"';
        return Response(
          response.statusCode,
          body: newContent,
          headers: response.headers..addAll(respHeaders ?? {}),
        );
      } else {
        return _requestResponse(d, request, headers, respHeaders);
      }
    } else {
      return _requestResponse(d, request, headers, respHeaders);
    }
  }

  Future<Response> _handleNoneHlsFile(File file, Request request) async {
    final contentType = mime.lookupMimeType(file.path) ?? "application/octet-stream";
    final fileLength = await file.length();
    final rangeHeader = request.headers[HttpHeaders.rangeHeader];
    FileRange? range = FileUtils.parseRangeHeader(rangeHeader, fileLength);
    if (range != null) {
      return Response(
        HttpStatus.partialContent,
        body: file.openRead(range.start, range.end + 1),
        headers: {
          HttpHeaders.contentTypeHeader: contentType,
          HttpHeaders.contentRangeHeader: 'bytes ${range.start}-${range.end}/$fileLength',
          HttpHeaders.contentLengthHeader: range.length.toString(),
          HttpHeaders.acceptRangesHeader: 'bytes',
        },
      );
    } else {
      return Response(
        HttpStatus.ok,
        body: file.openRead(),
        headers: {
          HttpHeaders.contentTypeHeader: contentType,
          HttpHeaders.contentLengthHeader: fileLength.toString(),
        },
      );
    }
  }

  Future<Response> _fileHandler(Request request) async {
    String? d = request.url.queryParameters["d"];
    if (d == null) return Response.badRequest();
    d = Uri.decodeComponent(d);
    File file = File(d);
    if (!(await file.exists())) {
      VideoJSLogger.showLog("File not found => $d!");
      return Response.notFound("Requested file not found! $d");
    }
    bool noHlsCheck = request.url.queryParameters["no-check"] == "true";
    if (noHlsCheck) {
      VideoJSLogger.showLog("Proxying without checking file format!");
    }
    if (!noHlsCheck) {
      bool isHls = await HlsUtils.isHlsFile(file);
      if (isHls) {
        String content = await file.readAsString();
        String newContent = await HlsUtils.modifyUrls(
          content,
          replace: (uri, isMaster) {
            if (uri.startsWith(url)) {
              // Skip this replacement since it has already replaced with proxy.
              return null;
            } else {
              return proxy(
                Uri.parse(file.path).resolve(uri).toString(),
                sourceType: SourceType.file,
              );
            }
          },
        );
        return Response(
          HttpStatus.ok,
          body: newContent,
          headers: {
            HttpHeaders.contentTypeHeader: "application/vnd.apple.mpegurl",
            HttpHeaders.contentDisposition: 'attachment; filename="index.m3u"',
          },
        );
      } else {
        return _handleNoneHlsFile(file, request);
      }
    } else {
      return _handleNoneHlsFile(file, request);
    }
  }

  Future<Response> _assetHandler(Request request) async {
    String? d = request.url.queryParameters["d"];
    if (d == null) {
      return Response.badRequest(body: "Missing 'd' query parameter");
    }
    d = Uri.decodeComponent(d);
    final contentType = mime.lookupMimeType(d) ?? "application/octet-stream";
    try {
      final data = await rootBundle.load(d);
      final fullBytes = data.buffer.asUint8List();
      final fileLength = fullBytes.length;
      final rangeHeader = request.headers[HttpHeaders.rangeHeader];
      FileRange? range = FileUtils.parseRangeHeader(rangeHeader, fileLength);
      if (range != null) {
        final clampedEnd = range.end.clamp(range.start, fileLength - 1);
        final content = fullBytes.sublist(range.start, clampedEnd + 1);
        return Response(
          HttpStatus.partialContent,
          body: content,
          headers: {
            HttpHeaders.contentTypeHeader: contentType,
            HttpHeaders.contentLengthHeader: content.length.toString(),
            HttpHeaders.contentRangeHeader:
                'bytes ${range.start}-${range.end}/$fileLength',
            HttpHeaders.acceptRangesHeader: 'bytes',
          },
        );
      }
      return Response.ok(
        fullBytes,
        headers: {
          HttpHeaders.contentTypeHeader: contentType,
          HttpHeaders.contentLengthHeader: fileLength.toString(),
          HttpHeaders.acceptRangesHeader: 'bytes',
        },
      );
    } catch (e) {
      VideoJSLogger.showLog("Error on asset handler: ${e.toString()}");
      return Response.internalServerError(body: "Failed to load asset: $e");
    }
  }

  Future<Response> _wsHandler(Request request) async {
    return await webSocketHandler((channel, _) {
      try {
        _channel = channel;
        _subscription = channel.stream.listen(
          (data) {
            _controller?.add(data);
          },
          onError: (err) {
            _controller?.addError(err);
          },
          onDone: () {
            _controller?.done;
          },
        );
      } catch (err) {
        VideoJSLogger.showLog("WebSocket Error: ${err.toString()}");
      }
    })(request);
  }

  Future<Response> _statusHandler(Request request) async {
    return Response.ok("ok");
  }

  Future<bool> get isServing async {
    try {
      return (await http.get(Uri.parse("$url/status"))).statusCode == 200;
    } catch(_) {
      return false;
    }
  }

  Future serve() async {
    final app = router.Router();
    app.get("/", _rootHandler);
    app.get("/ws", _wsHandler);
    app.get("/status", _statusHandler);
    app.get("/${SourceType.network.name}", _proxyHandler);
    app.get("/${SourceType.file.name}", _fileHandler);
    app.get("/${SourceType.asset.name}", _assetHandler);
    _server = await shelf_io.serve(
      logRequests().addHandler(app.call),
      address,
      port,
    );
    VideoJSLogger.showLog("Created new http server at $url.");
  }

  Future close() async {
    await _server?.close(force: true);
    await _controller?.close();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _server = null;
    _controller = null;
    _subscription = null;
    _channel = null;
  }
}
