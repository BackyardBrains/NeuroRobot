/// Web Audio API wrapper for Spikerbot SFX.
/// Drop-in replacement for flutter_soloud on web.
/// Uses dart:js_util to call the audio_bridge.js functions.
///
/// Usage (same call sites as SoLoud):
///   var audio = WebAudio.instance;
///   audio.init();
///   var src = await audio.loadAsset('assets/audio/ButtonPop.mp3');
///   var handle = audio.play(src);
///   audio.fadeVolume(handle, 0.0, Duration(milliseconds: 300));
///   audio.scheduleStop(handle, Duration(milliseconds: 300));

import 'dart:async';
import 'dart:js_util' as js_util;
import 'dart:html' as html;

/// Opaque source identifier (just the asset name string).
class WebAudioSource {
  final String name;
  final String url;
  WebAudioSource(this.name, this.url);
}

/// Opaque handle to a playing sound.
class WebSoundHandle {
  final int id;
  WebSoundHandle(this.id);
}

class WebAudio {
  WebAudio._();
  static final WebAudio instance = WebAudio._();

  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize the Web Audio context.
  Future<void> init() async {
    try {
      final result = js_util.callMethod(html.window, 'webAudioInit', []);
      _initialized = (result == true);
      if (_initialized) {
        print('WebAudio: Dart wrapper initialized');
      }
    } catch (e) {
      print('WebAudio: init error: $e');
      _initialized = false;
    }
  }

  /// Load an audio asset. Returns a WebAudioSource for playback.
  Future<WebAudioSource?> loadAsset(String assetPath) async {
    if (!_initialized) return null;
    try {
      // Flutter web serves assets under assets/ prefix
      final url = 'assets/$assetPath';
      // Extract a short name from the path (e.g., "NeuronSpikes" from "assets/audio/NeuronSpikes.mp3")
      final name = assetPath.split('/').last.replaceAll('.mp3', '');

      final result = await js_util.promiseToFuture(
        js_util.callMethod(html.window, 'webAudioLoad', [name, url])
      );

      if (result == true) {
        return WebAudioSource(name, url);
      }
      print('WebAudio: Failed to load $assetPath');
      return null;
    } catch (e) {
      print('WebAudio: loadAsset error: $e');
      return null;
    }
  }

  /// Play a loaded sound. Returns a handle for fade/stop control.
  WebSoundHandle? play(WebAudioSource source, {bool looping = false}) {
    if (!_initialized) return null;
    try {
      final handleId = js_util.callMethod(
        html.window, 'webAudioPlay', [source.name, looping]
      );
      if (handleId is int && handleId > 0) {
        return WebSoundHandle(handleId);
      }
      // JS may return num, not int
      if (handleId is num && handleId > 0) {
        return WebSoundHandle(handleId.toInt());
      }
      return null;
    } catch (e) {
      print('WebAudio: play error: $e');
      return null;
    }
  }

  /// Smoothly fade volume to [targetVol] over [duration].
  void fadeVolume(WebSoundHandle handle, double targetVol, Duration duration) {
    if (!_initialized) return;
    try {
      js_util.callMethod(
        html.window, 'webAudioFadeVolume',
        [handle.id, targetVol, duration.inMilliseconds]
      );
    } catch (_) {}
  }

  /// Fade out and stop after [duration].
  void scheduleStop(WebSoundHandle handle, Duration duration) {
    if (!_initialized) return;
    try {
      js_util.callMethod(
        html.window, 'webAudioFadeStop',
        [handle.id, duration.inMilliseconds]
      );
    } catch (_) {}
  }

  /// Stop immediately.
  void stop(WebSoundHandle handle) {
    if (!_initialized) return;
    try {
      js_util.callMethod(html.window, 'webAudioStop', [handle.id]);
    } catch (_) {}
  }

  /// Set looping on a playing sound.
  void setLooping(WebSoundHandle handle, bool loop) {
    if (!_initialized) return;
    try {
      js_util.callMethod(html.window, 'webAudioSetLoop', [handle.id, loop]);
    } catch (_) {}
  }
}
