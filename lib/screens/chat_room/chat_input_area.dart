// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ChatColors {
  static const primaryGreen = Color(0xFF2E7D66);
  static const lightGreen   = Color(0xFF4CAF50);
  static const darkGreen    = Color(0xFF1B5E20);
  static const paleGreen    = Color(0xFFE8F7E8);
  static const softGreen    = Color(0xFF66BB6A);
  static const backgroundGreen = Color(0xFFF1F8E9);
}

/// onSend: (String text, List<String> imagesB64)
class ChatInputArea extends StatefulWidget {
  final TextEditingController messageController;
  final FocusNode focusNode;
  final void Function(String, List<String>) onSend;

  const ChatInputArea({
    super.key,
    required this.messageController,
    required this.focusNode,
    required this.onSend,
  });

  @override
  State<ChatInputArea> createState() => _ChatInputAreaState();
}

class _ChatInputAreaState extends State<ChatInputArea> {
  final ImagePicker _picker = ImagePicker();
  final List<String> _imagesB64 = [];

  bool get hasText => widget.messageController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    widget.messageController.removeListener(() {});
    super.dispose();
  }

  Future<void> _pick(ImageSource src) async {
    final XFile? f = await _picker.pickImage(
      source: src,
      imageQuality: 70,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (f == null) return;
    final bytes = await File(f.path).readAsBytes();
    setState(() => _imagesB64.add(base64Encode(bytes)));
  }

  void _handlePaste() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text;
    if (text == null || text.isEmpty) return;

    final sel = widget.messageController.selection;
    final newText = widget.messageController.text.replaceRange(sel.start, sel.end, text);
    widget.messageController.value = widget.messageController.value.copyWith(
      text: newText,
      selection: TextSelection.collapsed(offset: sel.start + text.length),
    );
  }

  void _attemptSend() {
    final text = widget.messageController.text.trim();
    if (text.isEmpty) {
      // ارسال تصویر به‌تنهایی مجاز نیست
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ارسال تصویر بدون متن مجاز نیست. لطفاً متن پیام را وارد کنید.')),
      );
      HapticFeedback.heavyImpact();
      return;
    }
    widget.onSend(text, List.of(_imagesB64));
    widget.messageController.clear();
    _imagesB64.clear();
    HapticFeedback.lightImpact();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 16),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: ChatColors.lightGreen.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: ChatColors.primaryGreen.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // پیش‌نمایش کوچک تصاویر انتخاب‌شده (داخل همان باکس)
            if (_imagesB64.isNotEmpty) ...[
              SizedBox(
                height: 64,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagesB64.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            base64Decode(_imagesB64[i]),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: -6,
                          right: -6,
                          child: GestureDetector(
                            onTap: () => setState(() => _imagesB64.removeAt(i)),
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(11),
                              ),
                              child: const Icon(Icons.close, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'دوربین',
                  icon: const Icon(Icons.camera_alt, color: ChatColors.primaryGreen),
                  onPressed: () => _pick(ImageSource.camera),
                  splashRadius: 22,
                ),
                IconButton(
                  tooltip: 'گالری',
                  icon: const Icon(Icons.photo, color: ChatColors.primaryGreen),
                  onPressed: () => _pick(ImageSource.gallery),
                  splashRadius: 22,
                ),
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 120),
                    child: Scrollbar(
                      child: TextField(
                        controller: widget.messageController,
                        focusNode: widget.focusNode,
                        minLines: 1,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'پیام خود را بنویسید…',
                          hintStyle: TextStyle(color: ChatColors.primaryGreen.withOpacity(0.5)),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                        ),
                        style: const TextStyle(fontSize: 16, color: ChatColors.darkGreen),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _attemptSend(),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'چسباندن',
                  icon: const Icon(Icons.content_paste_go, color: ChatColors.primaryGreen),
                  onPressed: _handlePaste,
                  splashRadius: 22,
                ),
                IconButton(
                  tooltip: 'ارسال',
                  icon: Icon(
                    Icons.send_rounded,
                    color: hasText ? Colors.white : Colors.grey.shade300,
                  ),
                  onPressed: hasText ? _attemptSend : null,
                  splashRadius: 22,
                  style: ButtonStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      hasText ? ChatColors.primaryGreen : Colors.transparent,
                    ),
                    shape: const WidgetStatePropertyAll(CircleBorder()),
                    padding: const WidgetStatePropertyAll(EdgeInsets.all(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}