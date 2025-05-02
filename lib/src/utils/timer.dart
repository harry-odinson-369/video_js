import 'dart:async';

class TimerUtils {
  static Future<void> wait(int milliseconds) =>
      Future.delayed(Duration(milliseconds: milliseconds));

  /// Wait until the [condition] is return true.
  static Future waitFor(
    bool Function() condition, {
    int msInterval = 300,
    int? timeout,
  }) {
    if (condition()) return Future.value();

    Completer completer = Completer();

    Timer? timer;

    if (timeout != null) {
      Future.delayed(Duration(seconds: timeout), () {
        timer?.cancel();
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
    }

    timer ??= Timer.periodic(Duration(milliseconds: msInterval), (t) {
      if (condition()) {
        t.cancel();
        timer?.cancel();
        timer = null;
        if (!completer.isCompleted) {
          completer.complete();
        }
      }
    });

    return completer.future;
  }
}
