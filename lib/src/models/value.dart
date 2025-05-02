import 'dart:ui';

enum VideoJSState {
  idle,
  initializing,
  ready,
  buffering,
  playing,
  paused,
  ended,
  error,
}

class DurationRange {
  final Duration start;
  final Duration end;

  DurationRange({required this.start, required this.end});

  factory DurationRange.fromMap(Map<String, dynamic> map) {
    return DurationRange(
      start: Duration(milliseconds: (map['start'] * 1000).toInt()),
      end: Duration(milliseconds: (map['end'] * 1000).toInt()),
    );
  }

  Map<String, dynamic> toMap() => {
    "start": start.inSeconds,
    "end": end.inSeconds,
  };
}

class VideoJSValue {
  Size size = Size.zero;
  Duration current = Duration.zero;
  Duration duration = Duration.zero;
  VideoJSState state = VideoJSState.idle;
  List<DurationRange> buffered = <DurationRange>[];
  bool isLoop = false;
  bool isInitialized = false;
  double volume = 0;
  double speed = 0;
  String? error;

  double get aspectRatio {
    if (!isInitialized || size.width == 0 || size.height == 0) return 16 / 9;
    final double aspectRatio = size.width / size.height;
    if (aspectRatio <= 0) return 16 / 9;
    return aspectRatio;
  }

  bool get isIdle => state == VideoJSState.idle;
  bool get isReady => state == VideoJSState.ready;
  bool get isPlaying => state == VideoJSState.playing;
  bool get isPaused => state == VideoJSState.paused;
  bool get isBuffering => state == VideoJSState.buffering;
  bool get isEnded => state == VideoJSState.ended;
  bool get isError => state == VideoJSState.error;
  bool get isInitializing => state == VideoJSState.initializing;

  VideoJSValue({
    this.size = Size.zero,
    this.duration = const Duration(),
    this.current = const Duration(),
    this.state = VideoJSState.idle,
    this.isInitialized = false,
    this.buffered = const <DurationRange>[],
    this.isLoop = false,
    this.volume = 0.0,
    this.speed = 1.0,
    this.error,
  });

  VideoJSValue copyWith({
    Duration? duration,
    Duration? current,
    VideoJSState? state,
    Size? size,
    bool? isInitialized,
    List<DurationRange>? buffered,
    bool? isLoop,
    double? volume,
    double? speed,
    String? error,
  }) => VideoJSValue(
    size: size ?? this.size,
    current: current ?? this.current,
    duration: duration ?? this.duration,
    state: state ?? this.state,
    isInitialized: isInitialized ?? this.isInitialized,
    buffered: buffered ?? this.buffered,
    isLoop: isLoop ?? this.isLoop,
    volume: volume ?? this.volume,
    speed: speed ?? this.speed,
    error: error ?? this.error,
  );

  factory VideoJSValue.fromMap(Map<String, dynamic> map) => VideoJSValue(
    size: Size(
      double.parse((map["size"]["width"] ?? 0).toString()),
      double.parse((map["size"]["height"] ?? 0).toString()),
    ),
    state: VideoJSState.values.firstWhere(
      (e) => e.name == (map["state"] ?? "idle"),
    ),
    duration: Duration(
      seconds: double.parse((map["duration"] ?? 0).toString()).toInt(),
    ),
    current: Duration(
      seconds: double.parse((map["current"] ?? 0).toString()).toInt(),
    ),
    isInitialized: map["initialized"] ?? false,
    buffered: List<DurationRange>.from(
      (map["buffered"] ?? []).map((e) => DurationRange.fromMap(e)),
    ),
    isLoop: map["loop"] ?? false,
    volume: double.parse((map["volume"] ?? 0).toString()),
    speed: double.parse((map["speed"] ?? 0).toString()),
    error: map["error"],
  );

  Map<String, dynamic> toMap([Map<String, dynamic>? map]) {
    var temp = {
      "size": {"width": size.width, "height": size.height},
      "state": state.name,
      "current": current.inSeconds,
      "duration": duration.inSeconds,
      "initialized": isInitialized,
      "buffered": buffered.map((e) => e.toMap()).toList(),
      "loop": isLoop,
      "volume": volume,
      "speed": speed,
      "error": error,
    };

    if (map != null) {
      for (final entry in map.entries) {
        if (entry.value != null) {
          temp[entry.key] = entry.value;
        }
      }
    }

    return temp;
  }

  @override
  int get hashCode =>
      size.hashCode ^
      state.hashCode ^
      current.hashCode ^
      duration.hashCode ^
      isInitialized.hashCode ^
      buffered.hashCode ^
      isLoop.hashCode ^
      volume.hashCode ^
      speed.hashCode ^
      error.hashCode;

  @override
  bool operator ==(Object other) {
    return other is VideoJSValue &&
        size.width == other.size.width &&
        size.height == other.size.height &&
        isInitialized == other.isInitialized &&
        duration.inSeconds == other.duration.inSeconds &&
        current.inSeconds == other.current.inSeconds &&
        state == other.state &&
        buffered.length == other.buffered.length &&
        isLoop == other.isLoop &&
        volume == other.volume &&
        speed == other.speed &&
        error == other.error;
  }
}
