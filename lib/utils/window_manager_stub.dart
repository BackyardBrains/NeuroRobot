/// Stub for window_manager package on web.
/// Provides the WindowListener mixin, WindowManager, WindowOptions,
/// and TitleBarStyle so class declarations compile.

import 'package:flutter/material.dart';

/// Stub mixin — all methods are no-ops.
mixin WindowListener {
  void onWindowClose() {}
  void onWindowFocus() {}
  void onWindowBlur() {}
  void onWindowMaximize() {}
  void onWindowUnmaximize() {}
  void onWindowMinimize() {}
  void onWindowRestore() {}
  void onWindowResize() {}
  void onWindowMove() {}
  void onWindowEnterFullScreen() {}
  void onWindowLeaveFullScreen() {}
  void onWindowMoved() {}
  void onWindowResized() {}
  void onWindowEvent(String eventName) {}
}

class TitleBarStyle {
  static const TitleBarStyle hidden = TitleBarStyle._('hidden');
  static const TitleBarStyle normal = TitleBarStyle._('normal');
  const TitleBarStyle._(this._name);
  final String _name;
}

class WindowOptions {
  final Size? size;
  final Size? minimumSize;
  final bool? center;
  final Color? backgroundColor;
  final bool? skipTaskbar;
  final TitleBarStyle? titleBarStyle;
  final String? title;
  
  const WindowOptions({
    this.size,
    this.minimumSize,
    this.center,
    this.backgroundColor,
    this.skipTaskbar,
    this.titleBarStyle,
    this.title,
  });
}

class WindowManager {
  static final WindowManager instance = WindowManager._();
  WindowManager._();
  
  Future<void> ensureInitialized() async {}
  Future<void> waitUntilReadyToShow([WindowOptions? options, VoidCallback? callback]) async {
    callback?.call();
  }
  Future<void> show() async {}
  Future<void> setTitle(String title) async {}
  Future<void> setMinimumSize(Size size) async {}
  Future<void> setSize(Size size) async {}
  Future<void> focus() async {}
  void addListener(WindowListener listener) {}
  void removeListener(WindowListener listener) {}
}

final windowManager = WindowManager.instance;
