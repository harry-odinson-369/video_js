import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:video_js/src/constants/web_const.dart';
import 'package:video_js/src/extensions/video.dart';
import 'package:video_js/src/models/options.dart';
import 'package:video_js/src/models/source.dart';
import 'package:video_js/src/utils/generate.dart';
import 'package:video_js/src/utils/log.dart';
import 'package:video_js/src/utils/mime.dart';
import 'package:video_js/src/utils/server.dart';
import 'package:video_js/src/utils/timer.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../models/value.dart';

class VideoJSController extends ValueNotifier<VideoJSValue> {
  VideoJSOptions options = VideoJSOptions();

  String _baseSrc = "";

  SourceType _sourceType;

  VideoJSServer? _server;

  WebViewController? _controller;
  WebViewController? get controller => _controller;

  VideoJSController.network(String url, {VideoJSOptions? options})
    : _sourceType = SourceType.network,
      _controller = WebConstants.defaultWebViewController,
      super(VideoJSValue()) {
    this.options = options ?? VideoJSOptions.defaultOptions();
    this.options.src = url;
    _baseSrc = url;
  }

  VideoJSController.file(String path, {VideoJSOptions? options})
    : _sourceType = SourceType.file,
      _controller = WebConstants.defaultWebViewController,
      super(VideoJSValue()) {
    this.options = options ?? VideoJSOptions.defaultOptions();
    this.options.src = path;
    _baseSrc = path;
  }

  VideoJSController.asset(String asset, {VideoJSOptions? options})
    : _sourceType = SourceType.asset,
      _controller = WebConstants.defaultWebViewController,
      super(VideoJSValue()) {
    this.options = options ?? VideoJSOptions.defaultOptions();
    this.options.src = asset;
    _baseSrc = asset;
  }

  VideoJSController.idle()
    : _sourceType = SourceType.network,
      _controller = WebConstants.defaultWebViewController,
      super(VideoJSValue(state: VideoJSState.idle));

  void setLog(void Function(dynamic data)? log) {
    VideoJSLogger.logger = log;
  }

  Future _serveIfNot() async {
    if (_server == null || (await _server?.isServing) != true) {
      await _server?.close();
      _server = VideoJSServer()..port = GenerateUtils.random(3000, 9999);
      await _server?.serve();
      await TimerUtils.wait(500);
      _server?.onMessage?.listen(_valueListener);
    }
  }

  String _getProps() {
    if (_sourceType == SourceType.network) {
      if (options.headers != null && options.headers!.entries.isNotEmpty) {
        options.src = _server!.proxy(
          options.src,
          headers: options.headers,
          sourceType: _sourceType,
        );
      }
    } else {
      options.src = _server!.proxy(options.src, sourceType: _sourceType);
    }
    return options.encodedProps;
  }

  Future initialize() async {
    assert(
      !(_baseSrc.isEmpty && value.state == VideoJSState.idle),
      "VideoJSController is in idle mode. please call 'change' function instead.",
    );
    value = value.copyWith(state: VideoJSState.initializing);
    await _serveIfNot();
    options.type ??= await MimeUtils.findType(_baseSrc, options.headers);
    String props = _getProps();
    final uri = Uri.parse("${_server!.url}/?props=$props");
    VideoJSLogger.logger?.call(
      "Initializing type ${options.type?.name} from ${_sourceType.name} with src ${options.src}.",
    );
    await _controller?.loadRequest(uri);
    await TimerUtils.waitFor(() => value.isInitialized);
  }

  /// Change to another video src.
  Future change(
    String src, {
    SourceType? source,
    VideoJSOptions? options,
  }) async {
    _baseSrc = src;
    _controller?.loadHtmlString(WebConstants.blankedHtml);
    if (options != null) this.options = options;
    this.options.src = src;
    if (source != null) _sourceType = source;
    value = VideoJSValue(state: VideoJSState.initializing);
    await _serveIfNot();
    this.options.type ??= await MimeUtils.findType(
      _baseSrc,
      this.options.headers,
    );
    String props = _getProps();
    final uri = Uri.parse("${_server!.url}/?props=$props");
    VideoJSLogger.logger?.call(
      "Change to type ${this.options.type?.name} from ${_sourceType.name} with src ${this.options.src}.",
    );
    _controller?.loadRequest(uri);
    await TimerUtils.waitFor(() => value.isInitialized);
  }

  Future _sendMessage(Map<String, dynamic> data) async =>
      _server?.sendMessage(json.encode(data));

  Future play() {
    value = value.copyWith(state: VideoJSState.playing);
    return _sendMessage({"action": "play"});
  }

  Future pause() {
    value = value.copyWith(state: VideoJSState.paused);
    return _sendMessage({"action": "pause"});
  }

  /// Seek the video to the given position [duration]
  Future seek(Duration position) {
    int pos = position.inSeconds;
    if (pos < 0) {
      pos = 0;
    } else if (pos > value.duration.inSeconds) {
      pos = value.duration.inSeconds;
    }
    value = value.copyWith(current: Duration(seconds: pos));
    return _sendMessage({"action": "seek", "position": pos});
  }

  /// min 0.5, max 2, normal 1.
  Future speed(double rate) {
    value = value.copyWith(speed: rate);
    return _sendMessage({"action": "speed", "rate": rate});
  }

  /// from 0 to 1.
  Future volume(double vol) {
    value = value.copyWith(volume: vol);
    return _sendMessage({"action": "volume", "level": vol});
  }

  Future setLoop(bool isLoop) {
    value = value.copyWith(isLoop: isLoop);
    return _sendMessage({"action": "loop", "allow": isLoop});
  }

  void setView(VideoJSView view) {
    value = value.copyWith(view: view);
    _controller?.runJavaScript(
      'document.querySelector("video").style.objectFit = "${view.toCssObjectFit}"',
    );
  }

  void _valueListener(dynamic data) {
    try {
      final decoded = json.decode(data.toString());
      final newValue = VideoJSValue.fromMap(value.toMap(decoded));
      if (value != newValue) {
        VideoJSLogger.logger?.call(newValue.toMap());
        value = newValue;
      }
    } catch (err) {
      VideoJSLogger.showLog("Error value listener: ${err.toString()}");
    }
  }

  @override
  Future dispose() async {
    await _controller?.loadHtmlString(WebConstants.blankedHtml);
    value = VideoJSValue();
    await _server?.close();
    _server = null;
    _controller = null;
    super.dispose();
  }
}
