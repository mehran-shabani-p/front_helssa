// ignore_for_file: deprecated_member_use
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;

class MediaService {
  final _picker = ImagePicker();

  Future<Uint8List?> pick(ImageSource src) async {
    if (kIsWeb && src == ImageSource.camera) {
      final input = html.FileUploadInputElement()
        ..accept = 'image/*'
        ..setAttribute('capture', 'environment');
      input.click();
      await input.onChange.first;
      if (input.files == null || input.files!.isEmpty) return null;
      final reader = html.FileReader()..readAsArrayBuffer(input.files!.first);
      await reader.onLoad.first;
      return _toJpeg(reader.result as List<int>);
    }

    final x = await _picker.pickImage(
      source: src, imageQuality: 100, maxWidth: 4096, maxHeight: 4096, preferredCameraDevice: CameraDevice.rear,
    );
    if (x == null) return null;
    final bytes = await x.readAsBytes();
    return _toJpeg(bytes);
  }

  Future<Uint8List> rotate90(Uint8List src) async {
    final i = img.decodeImage(src); if (i == null) return src;
    final r = img.copyRotate(i, angle: 90);
    return Uint8List.fromList(img.encodeJpg(r, quality: 85));
  }

  Future<Uint8List> cropCenterSquare(Uint8List src) async {
    final i = img.decodeImage(src); if (i == null) return src;
    final m = i.width < i.height ? i.width : i.height;
    final x = (i.width - m) ~/ 2, y = (i.height - m) ~/ 2;
    final c = img.copyCrop(i, x: x, y: y, width: m, height: m);
    return Uint8List.fromList(img.encodeJpg(c, quality: 85));
  }

  Future<Uint8List> _toJpeg(List<int> bytes) async {
    final src = img.decodeImage(Uint8List.fromList(bytes));
    if (src == null) return Uint8List.fromList(bytes);

    const maxSide = 1600;
    img.Image resized = src;
    if (src.width > maxSide || src.height > maxSide) {
      resized = src.width >= src.height ? img.copyResize(src, width: maxSide) : img.copyResize(src, height: maxSide);
    }

    int q = 82;
    Uint8List out = Uint8List.fromList(img.encodeJpg(resized, quality: q));
    while (out.lengthInBytes > 900 * 1024 && q > 55) {
      q -= 5;
      out = Uint8List.fromList(img.encodeJpg(resized, quality: q));
    }
    return out;
  }
}
