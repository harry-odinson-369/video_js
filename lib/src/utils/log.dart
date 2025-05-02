Function? _logger;

class VideoJSLogger {

  static showLog(String msg) {
    _logger?.call("[video_js] $msg");
  }

  static Function? get logger => _logger;
  static set logger(Function? l) {
    _logger = l;
  }

}