import 'package:infinite_canvas/infinite_canvas.dart';

/// Global annotation selection state, read by canvas rendering widgets
/// (node_renderer.dart, synapse_renderer.dart) to paint annotation highlights
/// without needing to thread state through the entire widget tree.
///
/// These are mutated only from _DesignBrainPageState when isAnnotationMode == true.

/// Node keys (valKey / key.toString()) currently selected in annotation mode.
Set<String> annotationHighlightNodeKeys = {};

/// Edge objects currently selected in annotation mode.
/// Compared by object identity inside synapse_renderer.dart.
Set<InfiniteCanvasEdge> annotationHighlightEdges = {};

/// True while the user is in annotation selection mode.
bool isInAnnotationMode = false;

/// Clear all annotation selection state (call on mode exit or new annotation).
void clearAnnotationHighlights() {
  annotationHighlightNodeKeys.clear();
  annotationHighlightEdges.clear();
}
