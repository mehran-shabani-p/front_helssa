import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter/widgets.dart';

class OcrService {
  Future<String> extract(Uint8List imageBytes) async {
    if (kIsWeb) return '';
    final input = InputImage.fromBytes(
      bytes: imageBytes,
      metadata: InputImageMetadata(
        size: const Size(0, 0),
        rotation: InputImageRotation.rotation0deg,
        bytesPerRow: 0,
        format: InputImageFormat.bgra8888,
      ),
    );
    final rec = TextRecognizer();
    final res = await rec.processImage(input);
    await rec.close();
    return res.text.trim();
  }
}
