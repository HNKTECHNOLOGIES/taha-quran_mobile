import 'reciter.dart';

enum AudioStatus {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

class AudioPlaybackState {
  const AudioPlaybackState({
    this.status = AudioStatus.idle,
    this.surahId,
    this.ayahNumber,
    this.verseCount,
    required this.reciter,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.errorMessage,
  });

  final AudioStatus status;
  final int? surahId;
  final int? ayahNumber;
  final int? verseCount;
  final Reciter reciter;
  final Duration position;
  final Duration duration;
  final String? errorMessage;

  bool get isActive =>
      status == AudioStatus.playing ||
      status == AudioStatus.paused ||
      status == AudioStatus.loading;

  double get progress {
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  AudioPlaybackState copyWith({
    AudioStatus? status,
    int? surahId,
    int? ayahNumber,
    int? verseCount,
    Reciter? reciter,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    bool clearError = false,
    bool clearSurah = false,
    bool clearAyah = false,
  }) {
    return AudioPlaybackState(
      status: status ?? this.status,
      surahId: clearSurah ? null : (surahId ?? this.surahId),
      ayahNumber: (clearSurah || clearAyah)
          ? null
          : (ayahNumber ?? this.ayahNumber),
      verseCount: clearSurah ? null : (verseCount ?? this.verseCount),
      reciter: reciter ?? this.reciter,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
