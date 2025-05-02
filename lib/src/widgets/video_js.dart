import 'package:flutter/material.dart';
import 'package:video_js/src/constants/web_const.dart';
import 'package:video_js/src/controllers/controller.dart';
import 'package:video_js/src/extensions/context.dart';
import 'package:video_js/src/extensions/video.dart';

class VideoJS extends StatelessWidget {
  final VideoJSController controller;
  const VideoJS({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    bool show = controller.controller != null;
    return Container(
      width: context.screen.width,
      height: context.screen.height,
      color: Colors.black,
      child:
          show
              ? LayoutBuilder(
                builder: (context, constraint) {
                  controller.controller?.setWindowSize(
                    width: constraint.maxWidth,
                    height: constraint.maxHeight,
                  );
                  return WebConstants.view(controller.controller!);
                },
              )
              : null,
    );
  }
}
