import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as image_lib;

// image_lib.Image convertJPEGToImage(CameraImage cameraImage) {
//   // Extract the bytes from the CameraImage
//   final bytes = cameraImage.planes[0].bytes;

//   // Create a new Image instance from the JPEG bytes
//   final image = image_lib.decodeImage(bytes);

//   return image!;
// }
image_lib.Image convertFramesToImage(Uint8List jpegBytes) {
  return image_lib.decodeImage(jpegBytes)!;
}

Future<void> saveImage(
  image_lib.Image image,
  String path,
  String name,
) async {
  Uint8List bytes = image_lib.encodeJpg(image);
  final fileOnDevice = File('$path/$name.jpg');
  await fileOnDevice.writeAsBytes(bytes, flush: true);
}
