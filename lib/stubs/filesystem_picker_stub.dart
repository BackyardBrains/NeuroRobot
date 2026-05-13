/// Web stub for filesystem_picker package.
/// filesystem_picker requires native filesystem access which doesn't exist on web.
/// On web, file operations use the browser File API via file_picker instead.

enum FilesystemType { folder, file, all }
enum FileTileSelectMode { wholeTile, checkButton }

class FilesystemPicker {
  static Future<String?> open({
    required String title,
    required dynamic context,
    required dynamic rootDirectory,
    FilesystemType fsType = FilesystemType.file,
    List<String>? allowedExtensions,
    FileTileSelectMode? fileTileSelectMode,
    String? pickText,
  }) async {
    // On web, filesystem picker is not available.
    // Use file_picker package's web implementation instead.
    return null;
  }
}
