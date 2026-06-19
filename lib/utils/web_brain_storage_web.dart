/// Web-only IndexedDB storage for brain files.
/// Provides Save/Load/Delete/List operations for the "My Brains" tab on Chrome.
///
/// Uses dart:indexed_db (part of the Dart SDK, zero external dependencies).
/// Each brain is stored as a record in the "brains" object store:
///   { filename (key), title, description, timestamp, json }
///
/// This file is only imported on web via conditional import.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:indexed_db' as idb;
import 'dart:html' as html;
import 'dart:typed_data';

class WebBrainStorage {
  static final WebBrainStorage instance = WebBrainStorage._();
  WebBrainStorage._();

  static const String _dbName = 'spikerbot_brains';
  static const int _dbVersion = 1;
  static const String _storeName = 'brains';

  idb.Database? _db;

  /// Opens (or creates) the IndexedDB database.
  Future<idb.Database> _getDb() async {
    if (_db != null) return _db!;
    _db = await html.window.indexedDB!.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (idb.VersionChangeEvent event) {
        final db = event.target.result as idb.Database;
        if (!db.objectStoreNames!.contains(_storeName)) {
          db.createObjectStore(_storeName, keyPath: 'filename');
        }
      },
    );
    return _db!;
  }

  /// Save a brain JSON string to IndexedDB.
  /// [filename] is the unique key (e.g. "My Robot@@@_@@@16789234.brain")
  /// [jsonContent] is the full brain JSON string (including screenshot)
  Future<void> saveBrain(String filename, String jsonContent, String title, String description) async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, 'readwrite');
    final store = txn.objectStore(_storeName);
    
    // Extract complexity from the JSON content
    String complexity = '0';
    String tags = '';
    try {
      final Map<String, dynamic> parsed = jsonDecode(jsonContent);
      int neuronsCount = parsed.containsKey('nodes') ? (parsed['nodes'] as List).length : 0;
      int synapsesCount = parsed.containsKey('edges') ? (parsed['edges'] as List).length : 0;
      complexity = (neuronsCount + synapsesCount).toString();
      
      // Extract tags (same logic as native loadBrainFiles)
      Set<String> tagSet = {};
      if (parsed.containsKey('edges') && parsed.containsKey('nodes')) {
        List edges = parsed['edges'] as List;
        Set<String> connectedKeys = {};
        for (var edge in edges) {
          if (edge is String) {
            var parts = edge.split('_#_');
            if (parts.length == 2) {
              connectedKeys.add(parts[0]);
              connectedKeys.add(parts[1]);
            }
          }
        }
        List nodes = parsed['nodes'] as List;
        for (var n in nodes) {
          if (n is Map && connectedKeys.contains(n['valKey'])) {
            int idx = n['index'] ?? -1;
            if (idx == 0) tagSet.add('Distance');
            else if (idx == 1 || idx == 2) tagSet.add('Camera Target');
            else if (idx == 3) tagSet.add('Microphone Input');
            else if (idx == 4) tagSet.add('Speaker');
            else if (idx >= 5 && idx <= 8) tagSet.add('Motor Movement');
            else if (idx >= 9 && idx <= 12) tagSet.add('LED Lights');
          }
        }
      }
      if (parsed['mapRemoteControlNeuron'] != null && 
          (parsed['mapRemoteControlNeuron'] as Map).isNotEmpty) {
        tagSet.add('Remote Control');
      }
      tags = tagSet.join(',');
    } catch (_) {}

    await store.put({
      'filename': filename,
      'title': title,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
      'complexity': complexity,
      'tags': tags,
      'json': jsonContent,
    });
    await txn.completed;
  }

  /// Load a brain JSON string from IndexedDB by filename.
  /// Returns null if not found.
  Future<String?> loadBrain(String filename) async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, 'readonly');
    final store = txn.objectStore(_storeName);
    final result = await store.getObject(filename);
    if (result == null) return null;
    final map = result as Map;
    return map['json'] as String?;
  }

  /// Delete a brain from IndexedDB.
  Future<void> deleteBrain(String filename) async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, 'readwrite');
    final store = txn.objectStore(_storeName);
    await store.delete(filename);
    await txn.completed;
  }

  /// List all saved brains. Returns metadata maps matching the native fileInfos format:
  /// [{ title, description, timestamp, complexity, tags, filename }]
  /// Sorted by timestamp descending (most recent first).
  Future<List<Map<String, String>>> listBrains() async {
    final db = await _getDb();
    final txn = db.transaction(_storeName, 'readonly');
    final store = txn.objectStore(_storeName);
    
    final List<Map<String, String>> results = [];
    
    // Use cursor to iterate all records
    final cursorStream = store.openCursor(autoAdvance: true);
    await for (final cursor in cursorStream) {
      final map = cursor.value as Map;
      results.add({
        'title': (map['title'] ?? 'Untitled').toString(),
        'description': (map['description'] ?? '').toString(),
        'timestamp': (map['timestamp'] ?? '').toString(),
        'complexity': (map['complexity'] ?? '0').toString(),
        'tags': (map['tags'] ?? '').toString(),
        'filename': (map['filename'] ?? '').toString(),
      });
    }
    
    // Sort by timestamp descending (most recent first)
    results.sort((a, b) {
      try {
        return DateTime.parse(b['timestamp']!).compareTo(DateTime.parse(a['timestamp']!));
      } catch (_) {
        return 0;
      }
    });
    
    return results;
  }

  /// Extract thumbnail bytes from a stored brain.
  /// Returns empty Uint8List if not found or no screenshot.
  Future<Uint8List> getThumbnail(String filename) async {
    try {
      final jsonStr = await loadBrain(filename);
      if (jsonStr == null || jsonStr.isEmpty) return Uint8List(0);
      
      final Map<String, dynamic> parsed = jsonDecode(jsonStr);
      final ss = parsed['screenshot'];
      if (ss == null) return Uint8List(0);
      if (ss is String && ss.isNotEmpty) {
        // New format: base64-encoded JPEG
        return base64Decode(ss);
      } else if (ss is List && ss.isNotEmpty) {
        // Legacy format: List<int> of raw PNG bytes
        return Uint8List.fromList(ss.cast<int>());
      }
    } catch (_) {}
    return Uint8List(0);
  }
}

/// Trigger a browser file download with the given content and filename.
/// Creates a temporary Blob URL, clicks an invisible anchor, then revokes the URL.
void triggerWebDownload(String content, String filename) {
  final bytes = utf8.encode(content);
  final blob = html.Blob([bytes], 'application/json');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..style.display = 'none';
  html.document.body!.children.add(anchor);
  anchor.click();
  html.document.body!.children.remove(anchor);
  html.Url.revokeObjectUrl(url);
}
