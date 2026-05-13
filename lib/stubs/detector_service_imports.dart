/// Conditional import for Detector service.
export 'detector_service_stub.dart'
    if (dart.library.io) 'detector_service_native.dart';
