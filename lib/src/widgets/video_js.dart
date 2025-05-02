import 'package:flutter/material.dart';
import 'package:video_js/src/constants/web_const.dart';
import 'package:video_js/src/controllers/controller.dart';
import 'package:video_js/src/extensions/context.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoJS extends StatelessWidget {
  final VideoJSController controller;
  const VideoJS({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: context.screen.width,
      height: context.screen.height,
      color: Colors.black,
      child:
          controller.controller != null
              ? WebViewWidget.fromPlatformCreationParams(
                params: WebConstants.defaultWebViewWidgetParams(
                  controller.controller!,
                ),
              )
              : SizedBox(),
    );
  }
}
