// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

/// --- طیف سبز سازمانی
class ChatColors {
  static const primaryGreen     = Color(0xFF2E7D66);
  static const lightGreen       = Color(0xFF4CAF50);
  static const darkGreen        = Color(0xFF1B5E20);
  static const paleGreen        = Color(0xFFE8F7E8);
  static const softGreen        = Color(0xFF66BB6A);
  static const backgroundGreen  = Color(0xFFF1F8E9);
}

/// ناحیهٔ ورودی چت
class ChatInputArea extends StatefulWidget {
  /// کنترل‌کنندهٔ متن
  final TextEditingController messageController;

  /// فوکوس ناحیهٔ متن
  final FocusNode focusNode;

  /// کال‌بک ارسال؛ نخست متن، سپس فهرست تصاویر (Base64)
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

  /// تصاویر انتخاب‌شده به‌صورت بایت خام (به‌جای String برای کارایی بهتر)
  final List<Uint8List> _images = [];

  @override
  void initState() {
    super.initState();
    widget.messageController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    widget.messageController.removeListener(_onInputChanged);
    super.dispose();
  }

  /* ------------------------- منطق کمکی ------------------------- */

  bool get _hasText  => widget.messageController.text.trim().isNotEmpty;
  bool get _hasMedia => _images.isNotEmpty;

  void _onInputChanged() => setState(() {}); // صرفاً برای فعال/غیرفعال شدن دکمه ارسال

  Future<void> _pickImage(ImageSource src) async {
    final XFile? x = await _picker.pickImage(source: src, imageQuality: 65);
    if (x == null) return;
    _images.add(await x.readAsBytes());
    setState(() {});
  }

  void _handleSend() {
    if (!_hasText && !_hasMedia) return;        // چیزی برای ارسال نیست
    widget.onSend(
      widget.messageController.text.trim(),
      _images.map(base64Encode).toList(),
    );

    // پاک‌سازی
    widget.messageController.clear();
    _images.clear();
    HapticFeedback.lightImpact();

    // فوکوس دوباره روی TextField
    widget.focusNode.requestFocus();
    setState(() {});
  }

  /* ------------------------- ویجت ------------------------- */

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ChatColors.backgroundGreen,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Container(
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
            /* ---- پیش‌نمایش تصاویر ---- */
            if (_hasMedia)
              SizedBox(
                height: 70,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: _images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) => Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          _images[i],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _images.removeAt(i)),
                        child: const CircleAvatar(
                          radius: 9,
                          backgroundColor: Colors.black54,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /* ---- خط ورودی متن و دکمه‌ها ---- */
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /* الصاق فایل */
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  color: ChatColors.primaryGreen,
                  splashRadius: 22,
                  tooltip: 'پیوست',
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),

                /* فیلد متنی */
                Expanded(
                  child: TextField(
                    controller: widget.messageController,
                    focusNode: widget.focusNode,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleSend(),
                    keyboardType: TextInputType.multiline,
                    textDirection: TextDirection.rtl,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'پیام خود را بنویسید…',
                      hintStyle: TextStyle(
                        color: ChatColors.primaryGreen.withOpacity(0.5),
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 16, color: ChatColors.darkGreen),
                    enableSuggestions: true,
                    autocorrect: true,
                  ),
                ),

                /* دکمهٔ ارسال */
                InkWell(
                  onTap: _handleSend,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.send_rounded,
                      size: 22,
                      color: (_hasText || _hasMedia)
                          ? ChatColors.primaryGreen
                          : Colors.grey.shade300,
                    ),
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
