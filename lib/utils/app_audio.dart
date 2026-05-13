/// AppAudio: Unified audio engine for Spikerbot.
/// Uses SoLoud on native platforms, Web Audio API on web.
/// Drop-in replacement — same API surface as SoLoud.
///
/// Usage:
///   soloud = AppAudio.instance;
///   await soloud.init();
///   var src = await soloud.loadAsset('assets/audio/ButtonPop.mp3');
///   var handle = await soloud.play(src!, looping: false);
///   soloud.fadeVolume(handle!, 0.0, Duration(milliseconds: 300));
///   soloud.scheduleStop(handle!, Duration(milliseconds: 300));

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:spikerbot/utils/web_audio.dart' if (dart.library.io) 'package:spikerbot/utils/web_audio_stub.dart';

class AppAudio {
  AppAudio._();
  static final AppAudio instance = AppAudio._();

  SoLoud? _soloud;
  WebAudio? _webAudio;
  bool _initialized = false;

  bool get isInitialized => _initialized;

  /// Initialize the audio engine (SoLoud on native, WebAudio on web).
  /// Safe to call multiple times — no-ops if already initialized.
  Future<void> init() async {
    if (_initialized) return; // Already initialized (singleton shared across widgets)
    if (kIsWeb) {
      _webAudio = WebAudio.instance;
      await _webAudio!.init();
      _initialized = _webAudio!.isInitialized;
      if (_initialized) print('AppAudio: Web Audio initialized');
    } else {
      _soloud = SoLoud.instance;
      await _soloud!.init();
      _initialized = _soloud!.isInitialized;
      if (_initialized) print('AppAudio: SoLoud initialized');
    }
  }

  /// Load an audio asset. Returns dynamic (AudioSource on native, WebAudioSource on web).
  Future<dynamic> loadAsset(String path) async {
    if (kIsWeb && _webAudio != null) {
      return await _webAudio!.loadAsset(path);
    } else if (_soloud != null) {
      return await _soloud!.loadAsset(path);
    }
    return null;
  }

  /// Play a loaded sound. Returns dynamic (SoundHandle on native, WebSoundHandle on web).
  Future<dynamic> play(dynamic source, {bool looping = false}) async {
    if (source == null) return null;
    if (kIsWeb && _webAudio != null && source is WebAudioSource) {
      return _webAudio!.play(source, looping: looping);
    } else if (_soloud != null && source is AudioSource) {
      return await _soloud!.play(source, looping: looping);
    }
    return null;
  }

  /// Fade volume on a playing sound.
  void fadeVolume(dynamic handle, double targetVol, Duration duration) {
    if (handle == null) return;
    if (kIsWeb && _webAudio != null && handle is WebSoundHandle) {
      _webAudio!.fadeVolume(handle, targetVol, duration);
    } else if (_soloud != null && handle is SoundHandle) {
      _soloud!.fadeVolume(handle, targetVol, duration);
    }
  }

  /// Schedule a stop after duration (fade to 0 then stop).
  void scheduleStop(dynamic handle, Duration duration) {
    if (handle == null) return;
    if (kIsWeb && _webAudio != null && handle is WebSoundHandle) {
      _webAudio!.scheduleStop(handle, duration);
    } else if (_soloud != null && handle is SoundHandle) {
      _soloud!.scheduleStop(handle, duration);
    }
  }

  /// Stop a playing sound immediately.
  void stop(dynamic handle) {
    if (handle == null) return;
    if (kIsWeb && _webAudio != null && handle is WebSoundHandle) {
      _webAudio!.stop(handle);
    } else if (_soloud != null && handle is SoundHandle) {
      _soloud!.stop(handle);
    }
  }

  /// Set looping on a playing sound.
  void setLooping(dynamic handle, bool loop) {
    if (handle == null) return;
    if (kIsWeb && _webAudio != null && handle is WebSoundHandle) {
      _webAudio!.setLooping(handle, loop);
    } else if (_soloud != null && handle is SoundHandle) {
      _soloud!.setLooping(handle, loop);
    }
  }

  /// Dispose an audio source.
  Future<void> disposeSource(dynamic source) async {
    if (source == null) return;
    if (!kIsWeb && _soloud != null && source is AudioSource) {
      await _soloud!.disposeSource(source);
    }
    // WebAudio doesn't need explicit disposal (GC handles AudioBuffer)
  }
}
