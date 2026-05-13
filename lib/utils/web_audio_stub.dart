/// Stub for web_audio.dart on native platforms.
/// Provides the same class interface but does nothing.
/// This file is only imported on non-web platforms via conditional import.

class WebAudioSource {
  final String name;
  final String url;
  WebAudioSource(this.name, this.url);
}

class WebSoundHandle {
  final int id;
  WebSoundHandle(this.id);
}

class WebAudio {
  WebAudio._();
  static final WebAudio instance = WebAudio._();
  bool get isInitialized => false;
  Future<void> init() async {}
  Future<WebAudioSource?> loadAsset(String assetPath) async => null;
  WebSoundHandle? play(WebAudioSource source, {bool looping = false}) => null;
  void fadeVolume(WebSoundHandle handle, double targetVol, Duration duration) {}
  void scheduleStop(WebSoundHandle handle, Duration duration) {}
  void stop(WebSoundHandle handle) {}
  void setLooping(WebSoundHandle handle, bool loop) {}
}
