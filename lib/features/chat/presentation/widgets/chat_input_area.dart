// ignore_for_file: deprecated_member_use
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/media_service.dart';

typedef OnSend = void Function(String text, {List<String> imagesB64, String? pdfText});

class ChatInputArea extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final OnSend onSend;
  const ChatInputArea({super.key, required this.controller, required this.focus, required this.onSend});

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final _media = MediaService();
  final List<Uint8List> _images = [];
  String? _pdfText;

  Future<void> _pick(ImageSource src) async {
    final b = await _media.pick(src);
    if (b != null) setState(() => _images.add(b));
  }

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
    if (res == null || res.files.single.bytes == null) return;
    // PDF را به صورت base64 موقتاً می‌فرستیم تا صفحه استخراج متن را انجام دهد.
    setState(() => _pdfText = base64Encode(res.files.single.bytes!));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF انتخاب شد.')));
  }

  void _attemptSend() {
    final txt = widget.controller.text.trim();
    if (txt.isEmpty && _images.isEmpty && _pdfText == null) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('پیامی وارد کنید.')));
      return;
    }
    widget.onSend(
      txt.isEmpty ? '(بدون متن)' : txt,
      imagesB64: _images.map((b) => base64Encode(b)).toList(),
      pdfText: _pdfText,
    );
    widget.controller.clear();
    setState(() { _images.clear(); _pdfText = null; });
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_images.isNotEmpty || _pdfText != null) ...[
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (int i = 0; i < _images.length; i++)
                  Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(_images[i], width: 72, height: 72, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: -6, right: -6,
                      child: IconButton.filled(
                        onPressed: () => setState(() => _images.removeAt(i)),
                        icon: const Icon(Icons.close, size: 16),
                        style: const ButtonStyle(padding: WidgetStatePropertyAll(EdgeInsets.zero)),
                      ),
                    ),
                  ]),
                if (_pdfText != null)
                  InputChip(avatar: const Icon(Icons.picture_as_pdf), label: const Text('PDF انتخاب‌شده'), onDeleted: () => setState(() => _pdfText = null)),
              ]),
              const SizedBox(height: 8),
            ],
            Row(children: [
              IconButton(icon: const Icon(Icons.camera_alt), onPressed: () => _pick(ImageSource.camera), tooltip: 'دوربین'),
              IconButton(icon: const Icon(Icons.photo), onPressed: () => _pick(ImageSource.gallery), tooltip: 'گالری'),
              IconButton(icon: const Icon(Icons.picture_as_pdf), onPressed: _pickPdf, tooltip: 'PDF'),
              const SizedBox(width: 8),
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: TextField(
                    controller: widget.controller, focusNode: widget.focus,
                    minLines: 1, maxLines: 6,
                    decoration: const InputDecoration(border: InputBorder.none, hintText: 'پیام خود را بنویسید…'),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _attemptSend(),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Rotate',
                onPressed: _images.isEmpty ? null : () async {
                  final r = await _media.rotate90(_images.last);
                  setState(() => _images[_images.length - 1] = r);
                },
                icon: const Icon(Icons.rotate_90_degrees_ccw),
              ),
              IconButton(
                tooltip: 'Crop',
                onPressed: _images.isEmpty ? null : () async {
                  final r = await _media.cropCenterSquare(_images.last);
                  setState(() => _images[_images.length - 1] = r);
                },
                icon: const Icon(Icons.crop_square),
              ),
              const SizedBox(width: 6),
              FilledButton.icon(icon: const Icon(Icons.send_rounded), label: const Text('ارسال'), onPressed: _attemptSend),
            ]),
          ],
        ),
      ),
    );
  }
}
