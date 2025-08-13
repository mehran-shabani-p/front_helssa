import 'dart:convert';
import 'package:flutter/material.dart';
import '../../domain/chat_models.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage msg;
  final VoidCallback onDelete;
  final VoidCallback onCopy;

  const MessageBubble({super.key, required this.msg, required this.onDelete, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    final isUser = msg.sender == 'user';
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(12),
      topRight: const Radius.circular(12),
      bottomLeft: isUser ? const Radius.circular(12) : const Radius.circular(4),
      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(12),
    );

    return Align(
      alignment: isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: isUser ? 8 : 56, start: isUser ? 56 : 8, top: 4, bottom: 4),
        child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isUser ? Colors.white : Theme.of(context).colorScheme.surface,
            borderRadius: radius,
            border: Border.all(color: Colors.white10),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (msg.imagesB64.isNotEmpty) ...[
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(base64Decode(msg.imagesB64.first), width: 140, height: 140, fit: BoxFit.cover),
                ),
                if (msg.imagesB64.length > 1)
                  Positioned(
                    right: 6, bottom: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                      child: Text('+${msg.imagesB64.length - 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                    ),
                  )
              ]),
              const SizedBox(height: 8),
            ],
            SelectableText(
              msg.text,
              style: TextStyle(color: isUser ? Colors.black : Colors.white, height: 1.45, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Text(TimeOfDay.fromDateTime(msg.timestamp).format(context),
                  style: TextStyle(color: isUser ? Colors.black45 : Colors.white70, fontSize: 11)),
              const SizedBox(width: 6),
              PopupMenuButton(
                icon: Icon(Icons.more_horiz, size: 16, color: isUser ? Colors.black54 : Colors.white70),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'copy', child: Row(children: [Icon(Icons.copy, size: 16), SizedBox(width: 8), Text('کپی')])) ,
                  PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, size: 16), SizedBox(width: 8), Text('حذف')])) ,
                ],
                onSelected: (v) { if (v == 'copy') onCopy(); if (v == 'delete') onDelete(); },
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}
