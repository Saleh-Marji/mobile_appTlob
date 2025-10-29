import 'dart:async';

import 'package:flutter/material.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime endDateTime;
  final Widget Function(Duration remaining) builder;
  final Duration refreshRateDuration;

  const CountdownTimer({
    super.key,
    required this.endDateTime,
    required this.builder,
    required this.refreshRateDuration,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(widget.refreshRateDuration, (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(widget.endDateTime.difference(DateTime.now()));
  }
}
