import 'dart:async';
import 'dart:html' as html;
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
  final completer = Completer<PickedImageData?>();
  final uploadInput = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..multiple = false;

  uploadInput.click();

  uploadInput.onChange.listen((event) {
    final files = uploadInput.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }

    final file = files[0];
    final reader = html.FileReader();

    reader.onLoadEnd.listen((event) {
      final result = reader.result;
      Uint8List? bytes;
      if (result is Uint8List) {
        bytes = result;
      } else if (result is ByteBuffer) {
        bytes = result.asUint8List();
      } else if (result is List<int>) {
        bytes = Uint8List.fromList(result);
      }

      if (bytes != null) {
        final ext = file.name.contains('.') ? file.name.split('.').last.toLowerCase() : 'jpeg';
        if (!completer.isCompleted) {
          completer.complete(PickedImageData(
            name: file.name,
            extension: ext,
            bytes: bytes,
          ));
        }
      } else {
        if (!completer.isCompleted) completer.complete(null);
      }
    });

    reader.onError.listen((event) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}
