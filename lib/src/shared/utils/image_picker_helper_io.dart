import 'dart:typed_data';

class PickedImageData {
  final String name;
  final String extension;
  final Uint8List bytes;

  PickedImageData({
    required this.name,
    required this.extension,
    required this.bytes,
  });
}

Future<PickedImageData?> pickImageFile() async {
  return null;
}
