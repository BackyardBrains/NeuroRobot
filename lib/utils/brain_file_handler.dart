import 'package:spikerbot/utils/platform_imports.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:spikerbot/utils/path_provider_imports.dart';

class BrainFileHandler {
  static final BrainFileHandler instance = BrainFileHandler._();

  static const _channel =
      MethodChannel('com.backyardbrains.spikerbot/fileopen');

  Function(String filename, {String? filePath})? _onFileOpen;
  String? _pendingFilePath;

  BrainFileHandler._() {
    print('BrainFileHandler: MethodChannel initialized');
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  /// Register the callback (called from DesignBrainPage.initState)
  void registerCallback(
      Function(String filename, {String? filePath}) callback) {
    _onFileOpen = callback;
    print('BrainFileHandler: callback registered, pending=$_pendingFilePath');
    if (_pendingFilePath != null) {
      final path = _pendingFilePath!;
      _pendingFilePath = null;
      // Delay to ensure DesignBrainPage is fully built
      Future.delayed(const Duration(milliseconds: 500), () {
        _processFile(path);
      });
    }
  }

  void unregisterCallback() {
    _onFileOpen = null;
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    print('BrainFileHandler: received method=${call.method} args=${call.arguments}');
    if (call.method == 'openFile') {
      final String filePath = call.arguments as String;
      await _processFile(filePath);
    }
  }

  Future<void> _processFile(String filePath) async {
    print('BrainFileHandler: _processFile path=$filePath, hasCallback=${_onFileOpen != null}');
    if (_onFileOpen == null) {
      _pendingFilePath = filePath;
      print('BrainFileHandler: No callback yet, queuing file');
      return;
    }

    try {
      // On macOS, the native side already copies to Documents/spikerbot/text/
      // On iOS, we may receive a path that's already in the app container
      // Check if the file is already in our Documents/spikerbot/text/ directory
      final Directory docDir = await getApplicationDocumentsDirectory();
      final String textPath =
          '${Platform.pathSeparator}spikerbot${Platform.pathSeparator}text';
      final String targetDirPath = '${docDir.path}$textPath';

      String finalPath = filePath;

      if (!filePath.startsWith(targetDirPath)) {
        // File is not yet in our Documents folder — copy it
        final File srcFile = File(filePath);
        if (!srcFile.existsSync()) {
          print('BrainFileHandler: Source file does not exist: $filePath');
          return;
        }

        final Directory targetDir = Directory(targetDirPath);
        if (!targetDir.existsSync()) {
          targetDir.createSync(recursive: true);
        }

        final String baseFileName = p.basename(srcFile.path);
        final File destFile = File(
            '${targetDir.path}${Platform.pathSeparator}$baseFileName');

        if (srcFile.path != destFile.path) {
          srcFile.copySync(destFile.path);
          print('BrainFileHandler: Copied to ${destFile.path}');
        }
        finalPath = destFile.path;
      } else {
        print('BrainFileHandler: File already in Documents, using directly');
      }

      final String baseFileName = p.basename(finalPath);
      final String nameWithoutExt = baseFileName.replaceAll('.brain', '');
      print('BrainFileHandler: Calling selectSavedBrain with name=$nameWithoutExt path=$finalPath');
      _onFileOpen!(nameWithoutExt, filePath: finalPath);
    } catch (e) {
      print('BrainFileHandler error: $e');
    }
  }
}
