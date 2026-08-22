import 'dart:async';
import 'dart:html' as html;

class PickedImageData {
  final String name;
  final String dataUrl;

  PickedImageData({
    required this.name,
    required this.dataUrl,
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
      final rawDataUrl = reader.result as String?;
      if (rawDataUrl == null) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }

      // Redimensiona e comprime via HTML5 Canvas
      final img = html.ImageElement();
      img.src = rawDataUrl;
      img.onLoad.listen((_) {
        int width = img.width ?? 1280;
        int height = img.height ?? 720;
        const maxDim = 1280;

        if (width > maxDim || height > maxDim) {
          if (width > height) {
            height = (height * maxDim / width).round();
            width = maxDim;
          } else {
            width = (width * maxDim / height).round();
            height = maxDim;
          }
        }

        final canvas = html.CanvasElement(width: width, height: height);
        final ctx = canvas.context2D;
        ctx.drawImageScaled(img, 0, 0, width, height);

        // Exporta como JPEG otimizado
        final compressedDataUrl = canvas.toDataUrl('image/jpeg', 0.82);

        if (!completer.isCompleted) {
          completer.complete(PickedImageData(
            name: file.name,
            dataUrl: compressedDataUrl,
          ));
        }
      });

      img.onError.listen((_) {
        // Fallback: se falhar o resize, usa o data URL original
        if (!completer.isCompleted) {
          completer.complete(PickedImageData(
            name: file.name,
            dataUrl: rawDataUrl,
          ));
        }
      });
    });

    reader.onError.listen((event) {
      if (!completer.isCompleted) completer.complete(null);
    });

    reader.readAsDataUrl(file);
  });

  return completer.future;
}
