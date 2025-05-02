import 'dart:convert';
import 'dart:math';

class GenerateUtils {
  static int random(int min, int max) {
    return min + Random().nextInt(max - min);
  }

  static Stream<List<int>> prependStream(List<int> prefix, Stream<List<int>> rest) async* {
    yield prefix;
    yield* rest;
  }

  static Map<K, V> parseHeaders<K, V>(String h) {
    Map<K, V> headers = {};
    for (final entry in json.decode(h).entries) {
      if (V is String) {
        headers[entry.key] = entry.value.toString() as V;
      } else {
        headers[entry.key] = entry.value;
      }
    }
    return headers;
  }

}