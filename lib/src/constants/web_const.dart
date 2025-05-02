import 'dart:io';

import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

class WebConstants {
  static String get blankedHtml => """
  <!DOCTYPE html>
  <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>Document</title>
    </head>
    <style>
      body,
      html {
        margin: 0;
        padding: 0;
        height: 100%;
        width: 100%;
        overflow: hidden;
        background-color: black;
      }
    </style>
    <body></body>
  </html>
  """;
  static WebViewController get defaultWebViewController {
    return (Platform.isIOS
          ? WebViewController.fromPlatform(
            WebKitWebViewController(
              WebKitWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
                const PlatformWebViewControllerCreationParams(),
                allowsInlineMediaPlayback: true,
                mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
              ),
            ),
          )
          : WebViewController.fromPlatform(
            AndroidWebViewController(
              AndroidWebViewControllerCreationParams.fromPlatformWebViewControllerCreationParams(
                PlatformWebViewControllerCreationParams(),
              ),
            )..setMediaPlaybackRequiresUserGesture(false),
          ))
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
  }

  static PlatformWebViewWidgetCreationParams defaultWebViewWidgetParams(
    WebViewController controller,
  ) {
    return Platform.isIOS
        ? WebKitWebViewWidgetCreationParams(controller: controller.platform)
        : AndroidWebViewWidgetCreationParams(
          controller: controller.platform,
          displayWithHybridComposition: true,
        );
  }
}
