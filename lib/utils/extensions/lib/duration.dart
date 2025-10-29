extension DurationExtension on Duration {
  String toCountdownString() => [
        inHours,
        inMinutes % 60,
        inSeconds % 60,
      ].map((e) => e.toString().padLeft(2, '0')).join(':');
}
