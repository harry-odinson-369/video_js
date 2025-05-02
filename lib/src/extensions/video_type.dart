import 'package:video_js/src/models/options.dart';
import 'package:mime/mime.dart' as mime;

extension VideoTypeExtension on VideoType {
  String? get toMimeType => mime.lookupMimeType("test.$name");
}