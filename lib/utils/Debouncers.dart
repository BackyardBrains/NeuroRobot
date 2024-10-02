import 'dart:math';

import 'package:flutter/foundation.dart';
import 'dart:async';

class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({required this.milliseconds});

  run(VoidCallback action) {
    try {
      _timer?.cancel();
    } catch (err) {}
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  cancel() {
    _timer?.cancel();
  }
}
