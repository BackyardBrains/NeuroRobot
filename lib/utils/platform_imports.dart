/// Conditional platform import — selects the correct Platform implementation.
/// On native (dart:io available): exports dart:io's Platform.
/// On web (dart:html available): exports our stub Platform.
export 'platform_stub.dart'
    if (dart.library.io) 'platform_native.dart';
