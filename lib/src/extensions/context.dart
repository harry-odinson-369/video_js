import 'package:flutter/widgets.dart';

extension ContextExtension on BuildContext {

  MediaQueryData get media => MediaQuery.of(this);

  Size get screen => media.size;

}