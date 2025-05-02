import 'package:video_js/src/models/options.dart';
import 'package:mime/mime.dart' as mime;
import 'package:video_js/src/models/value.dart';
import 'package:webview_flutter/webview_flutter.dart';

extension VideoTypeExtension on VideoJSType {
  String? get toMimeType => mime.lookupMimeType("test.$name");
}

extension VideoJSViewExtension on VideoJSView {
  String get toCssObjectFit {
    if (this == VideoJSView.stretch) return "fill";
    if (this == VideoJSView.crop) return "cover";
    return "";
  }
}

extension WebViewControllerExtension on WebViewController {
  void setWindowSize({double? width, double? height}) {
    String script =
        "${width != null ? """
        document.documentElement.style.width = "${width}px";
        document.body.style.width = "${width}px";""" : ""}"
        "${height != null ? """
        document.documentElement.style.height = "${height}px";
        document.body.style.height = "${height}px";
        """ : ""}";
    runJavaScript(script);
  }
}
