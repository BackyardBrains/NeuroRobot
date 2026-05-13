/// Native stub for WebBrainStorage — all methods are no-ops.
/// This file is used on iOS/macOS/Android where dart:indexed_db is unavailable.

import 'dart:typed_data';

class WebBrainStorage {
  static final WebBrainStorage instance = WebBrainStorage._();
  WebBrainStorage._();

  Future<void> saveBrain(String filename, String jsonContent, String title, String description) async {}
  Future<String?> loadBrain(String filename) async => null;
  Future<void> deleteBrain(String filename) async {}
  Future<List<Map<String, String>>> listBrains() async => [];
  Future<Uint8List> getThumbnail(String filename) async => Uint8List(0);
}

/// No-op on native — browser download is web-only.
void triggerWebDownload(String content, String filename) {}

