/// Expanded stub for dart:io on web platform.
/// Provides Platform, File, Directory, HttpClient, FileMode stubs.

import 'dart:typed_data';

class Platform {
  static bool get isIOS => false;
  static bool get isAndroid => false;
  static bool get isMacOS => true;  // Web uses desktop (macOS-like) UI layout
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isFuchsia => false;
  static String get pathSeparator => '/';
  static String get operatingSystem => 'web';
  static Map<String, String> get environment => {};
}

class FileMode {
  static const FileMode read = FileMode._('read');
  static const FileMode write = FileMode._('write');
  static const FileMode append = FileMode._('append');
  static const FileMode writeOnly = FileMode._('writeOnly');
  static const FileMode writeOnlyAppend = FileMode._('writeOnlyAppend');
  const FileMode._(this._name);
  final String _name;
}

class File {
  final String path;
  File(this.path);
  
  bool existsSync() => false;
  void deleteSync({bool recursive = false}) {}
  File copySync(String newPath) => File(newPath);
  Future<String> readAsString() async => '';
  String readAsStringSync() => '';
  Future<File> writeAsString(String contents, {FileMode mode = FileMode.write}) async => this;
  void writeAsStringSync(String contents, {FileMode mode = FileMode.write}) {}
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Uint8List readAsBytesSync() => Uint8List(0);
  Future<File> writeAsBytes(List<int> bytes, {FileMode mode = FileMode.write}) async => this;
  void writeAsBytesSync(List<int> bytes, {FileMode mode = FileMode.write}) {}
  Future<File> create({bool recursive = false}) async => this;
  void createSync({bool recursive = false}) {}
  Uri get uri => Uri.parse(path);
  String get absolute => path;
  Future<int> length() async => 0;
  int lengthSync() => 0;
  Future<bool> exists() async => false;
  FileStat statSync() => FileStat._stat();
}

class Directory {
  final String path;
  Directory(this.path);
  
  bool existsSync() => false;
  void createSync({bool recursive = false}) {}
  Future<Directory> create({bool recursive = false}) async => this;
  List<FileSystemEntity> listSync({bool recursive = false, bool followLinks = true}) => [];
  Stream<FileSystemEntity> list({bool recursive = false, bool followLinks = true}) => const Stream.empty();
  
  static Directory get current => Directory('.');
  Directory get absolute => this;
}

class FileSystemEntity {
  final String path;
  FileSystemEntity(this.path);
  
  static bool isDirectorySync(String path) => false;
  static bool isFileSync(String path) => false;
}

class FileStat {
  final DateTime changed;
  final DateTime modified;
  final DateTime accessed;
  final int size;
  FileStat._(this.changed, this.modified, this.accessed, this.size);
  factory FileStat._stat() {
    var now = DateTime.now();
    return FileStat._(now, now, now, 0);
  }
  
  static Future<FileStat> stat(String path) async {
    var now = DateTime.now();
    return FileStat._(now, now, now, 0);
  }
  static FileStat statSync(String path) {
    var now = DateTime.now();
    return FileStat._(now, now, now, 0);
  }
}

class HttpClient {
  Future<HttpClientRequest> openUrl(String method, Uri url) async {
    return HttpClientRequest._();
  }
}

class HttpClientRequest {
  HttpClientRequest._();
  final HttpHeaders headers = HttpHeaders._();
  Future<HttpClientResponse> close() async => HttpClientResponse._();
}

class HttpClientResponse {
  HttpClientResponse._();
}

class HttpHeaders {
  HttpHeaders._();
  void set(String name, Object value) {}
}

class HttpException implements Exception {
  final String message;
  HttpException(this.message);
  @override
  String toString() => 'HttpException: $message';
}

class SocketException implements Exception {
  final String message;
  SocketException(this.message);
  @override
  String toString() => 'SocketException: $message';
}

class InternetAddress {
  static Future<List<InternetAddress>> lookup(String host) async => [];
  final String address;
  InternetAddress(this.address);
}

/// Stub for path_provider on web
Future<Directory> getApplicationDocumentsDirectory() async {
  return Directory('/web_documents');
}

Future<Directory> getTemporaryDirectory() async {
  return Directory('/web_tmp');
}

Future<Directory> getApplicationSupportDirectory() async {
  return Directory('/web_support');
}

Future<Directory?> getDownloadsDirectory() async {
  return Directory('/web_downloads');
}
