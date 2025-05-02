class DurationUtils {
  static Duration parseDuration(String timeString) {
    final parts = timeString.split(':').map(int.parse).toList();
    if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    } else {
      throw FormatException("Invalid time string format");
    }
  }
}
