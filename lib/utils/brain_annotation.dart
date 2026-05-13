import 'dart:convert';
import 'dart:typed_data';

/// A single annotation attached to a brain file.
///
/// Stores the set of selected neuron/edge identifiers, a user description,
/// and a 256×256 JPEG thumbnail showing only the annotated elements.
class BrainAnnotation {
  final String id;

  /// `valKey` strings matching InfiniteCanvasNode.key.toString() in the save JSON.
  final List<String> neuronKeys;

  /// Edge strings in the "fromId_#_toId" format matching the edges array in save JSON.
  final List<String> edgeStrings;

  /// User-authored description of what the selected circuit does.
  final String description;

  /// JPEG-encoded 256×256 thumbnail (may be empty if capture failed).
  final Uint8List thumbnail;

  const BrainAnnotation({
    required this.id,
    required this.neuronKeys,
    required this.edgeStrings,
    required this.description,
    required this.thumbnail,
  });

  // ─── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'id': id,
        'neuronKeys': neuronKeys,
        'edgeStrings': edgeStrings,
        'description': description,
        // Store JPEG bytes as base64 string to keep the parent JSON valid UTF-8
        'thumbnail': base64Encode(thumbnail),
      };

  factory BrainAnnotation.fromJson(Map<String, dynamic> j) => BrainAnnotation(
        id: j['id'] as String? ?? '',
        neuronKeys: List<String>.from(j['neuronKeys'] as List? ?? []),
        edgeStrings: List<String>.from(j['edgeStrings'] as List? ?? []),
        description: j['description'] as String? ?? '',
        thumbnail: j['thumbnail'] != null && (j['thumbnail'] as String).isNotEmpty
            ? base64Decode(j['thumbnail'] as String)
            : Uint8List(0),
      );

  /// Parse the annotations list from a decoded brain file JSON map.
  /// Returns an empty list if the key is absent (backward-compatible).
  static List<BrainAnnotation> listFromJson(Map decodedJson) {
    final raw = decodedJson['annotations'];
    if (raw == null || raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => BrainAnnotation.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// Serialise a list of annotations for inclusion in the brain file JSON.
  static List<Map<String, dynamic>> listToJson(List<BrainAnnotation> list) =>
      list.map((a) => a.toJson()).toList();

  // ─── Helpers ───────────────────────────────────────────────────────────────

  BrainAnnotation copyWith({
    String? description,
    List<String>? neuronKeys,
    List<String>? edgeStrings,
    Uint8List? thumbnail,
  }) =>
      BrainAnnotation(
        id: id,
        neuronKeys: neuronKeys ?? this.neuronKeys,
        edgeStrings: edgeStrings ?? this.edgeStrings,
        description: description ?? this.description,
        thumbnail: thumbnail ?? this.thumbnail,
      );
}
