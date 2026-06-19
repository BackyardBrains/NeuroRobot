import 'package:spikerbot/utils/platform_imports.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:spikerbot/utils/path_provider_imports.dart';
import 'package:path/path.dart';

/// Known example brain files bundled with the app.
/// On web, AssetManifest.json may be incomplete in debug mode,
/// so we enumerate these explicitly and try to load each one.
const List<String> _knownExampleBrains = [
  'Blue is My Favorite Color.brain',
  'Count from 0 to 3 like a Computer.brain',
  'Cowboy Stops to Chat.brain',
  'Cranial Chameleon.brain',
  'Curious Cat.brain',
  'Dance Partner.brain',
  'Elementary Motion Detection.brain',
  'Explorer.brain',
  'Fixed Action Pattern.brain',
  'Greet Nearby People.brain',
  'High Pitch Low Pitch.brain',
  'I Spy a Banana, I Spy a Human.brain',
  'Keyboard Controlled Car.brain',
  'Left Right and Center.brain',
  'Marco Polo.brain',
  'Music Note Visualizer.brain',
  'On and Off Switch.brain',
  'Predator or Prey.brain',
  'Red Light Green Light.brain',
  'Remote Control Dancer.brain',
  'Remote Control Duck Waddle.brain',
  'Sharp Note Theremin.brain',
  'Simple Gamepad Controlled Car.brain',
  'Simple Tank.brain',
  'Spike the Dog.brain',
  'This Car is Scared of People.brain',
  'Two Speed Tank.brain',
  'Vanishing Act.brain',
  'Volume Meter.brain',
  'Watchdog.brain',
];

Future<List<File>> loadExampleBrains(List<Map<String, String>> fileInfos) async {
  List<File> fileNames = [];
  fileInfos.clear(); // Clear existing infos to match the file list

  if (kIsWeb) {
    return _loadExampleBrainsWeb(fileInfos);
  }

  try {
    // ── NATIVE PATH: Use AssetManifest to discover files, copy to cache ──
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final exampleFiles = manifestMap.keys
        .where((String key) {
           var decoded = Uri.decodeFull(key);
           return decoded.contains('assets/example brains/') && decoded.endsWith('.brain');
        })
        .toList();

    final directory = await getApplicationSupportDirectory();
    final exampleDir = Directory('${directory.path}/example_brains_cache');
    if (!exampleDir.existsSync()) {
      exampleDir.createSync(recursive: true);
    }

    for (String assetPath in exampleFiles) {
      try {
        final byteData = await rootBundle.load(assetPath);
        final fileName = Uri.decodeFull(basename(assetPath));
        final tempFile = File('${exampleDir.path}/$fileName');
        
        await tempFile.writeAsBytes(byteData.buffer.asUint8List());
        fileNames.add(tempFile);

        // Extract Metadata
        Map<String, String> brainInfo = {};
        try {
          String content = await tempFile.readAsString();
          brainInfo = _extractBrainInfo(content, fileName);
        } catch (e) {
          brainInfo["title"] = fileName.replaceAll(".brain", "");
          brainInfo["description"] = "Example Brain";
          brainInfo["complexity"] = "0";
        }
        fileInfos.add(brainInfo);
      } catch (e) {
        print("Error processing example brain $assetPath: $e");
      }
    }
  } catch (e) {
    print("Error loading example brains: $e");
  }
  
  return fileNames;
}

/// Web-specific loader: loads pre-built manifest for instant metadata.
/// Falls back to loading individual brain files if manifest is unavailable.
Future<List<File>> _loadExampleBrainsWeb(List<Map<String, String>> fileInfos) async {
  List<File> fileNames = [];
  
  // Try loading the pre-built manifest first (instant, ~5KB)
  try {
    final manifestContent = await rootBundle.loadString('assets/example_brains_manifest.json');
    final List<dynamic> manifest = json.decode(manifestContent);
    print("Web: Loaded manifest with ${manifest.length} example brains");
    
    for (var entry in manifest) {
      final Map<String, dynamic> info = entry as Map<String, dynamic>;
      final String assetPath = info['assetPath'] as String? ?? 'assets/example brains/${info['filename']}';
      fileNames.add(File(assetPath));
      fileInfos.add({
        'title': info['title'] as String? ?? '',
        'description': info['description'] as String? ?? 'Example Brain',
        'complexity': info['complexity']?.toString() ?? '0',
        'tags': info['tags'] as String? ?? '',
        'timestamp': info['timestamp'] as String? ?? '',
      });
    }
    return fileNames;
  } catch (e) {
    print("Web: Manifest not found ($e), falling back to individual file loading...");
  }
  
  // Fallback: load each brain file individually (slow, ~42MB)
  print("Web: Loading ${_knownExampleBrains.length} known example brain files...");
  
  for (String brainName in _knownExampleBrains) {
    final assetPath = 'assets/example brains/$brainName';
    try {
      final content = await rootBundle.loadString(assetPath);
      print("Web: Loaded '$brainName' (${content.length} chars)");
      
      final stubFile = File(assetPath);
      fileNames.add(stubFile);

      Map<String, String> brainInfo = _extractBrainInfo(content, brainName);
      fileInfos.add(brainInfo);
    } catch (e) {
      print("Web: Could not load '$brainName': $e");
    }
  }
  
  print("Web: Successfully loaded ${fileNames.length} example brains");
  return fileNames;
}

/// Shared metadata extraction from brain JSON content
Map<String, String> _extractBrainInfo(String content, String fileName) {
  Map<String, String> brainInfo = {};
  try {
    Map<String, dynamic> jsonMap = jsonDecode(content);
    
    // Extract Complexity Size
    int neuronsCount = jsonMap.containsKey("nodes") ? (jsonMap["nodes"] as List).length : 0;
    int synapsesCount = jsonMap.containsKey("edges") ? (jsonMap["edges"] as List).length : 0;
    brainInfo["complexity"] = (neuronsCount + synapsesCount).toString();
    
    Set<String> tags = {};
    if (jsonMap.containsKey("edges") && jsonMap.containsKey("nodes")) {
       List edges = jsonMap["edges"] as List;
       Set<String> connectedKeys = {};
       for (var edge in edges) {
          if (edge is String) {
             var parts = edge.split("_#_");
             if (parts.length == 2) {
                connectedKeys.add(parts[0]);
                connectedKeys.add(parts[1]); 
             }
          }
       }
       List nodes = jsonMap["nodes"] as List;
       for (var n in nodes) {
          if (n is Map && connectedKeys.contains(n["valKey"])) {
             int idx = n["index"] ?? -1;
             if (idx == 0) tags.add("Distance");
             else if (idx == 1 || idx == 2) tags.add("Camera Target");
             else if (idx == 3) tags.add("Microphone Input");
             else if (idx == 4) tags.add("Speaker");
             else if (idx >= 5 && idx <= 8) tags.add("Motor Movement");
             else if (idx >= 9 && idx <= 12) tags.add("LED Lights");
          }
       }
    }
    if (jsonMap["mapRemoteControlNeuron"] != null && (jsonMap["mapRemoteControlNeuron"] as Map).isNotEmpty) {
       tags.add("Remote Control");
    }
    brainInfo["tags"] = tags.join(",");
    
    if (jsonMap.containsKey("info")) {
       var info = jsonMap["info"];
       brainInfo["title"] = info["title"] ?? fileName.replaceAll(".brain", "");
       brainInfo["description"] = info["description"] ?? "Example Brain";
       if (info["timestamp"] != null) brainInfo["timestamp"] = info["timestamp"].toString();
    } else {
       brainInfo["title"] = fileName.replaceAll(".brain", "");
       brainInfo["description"] = "Example Brain";
    }
  } catch (e) {
    brainInfo["title"] = fileName.replaceAll(".brain", "");
    brainInfo["description"] = "Example Brain";
    brainInfo["complexity"] = "0";
  }
  return brainInfo;
}
