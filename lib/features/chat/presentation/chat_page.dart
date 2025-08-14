// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/chat_session.dart';
import 'bloc/chat_cubit.dart';
import 'session_drawer.dart';
import 'widgets/chat_input_area.dart';
import 'widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final String sessionId; // از /chat/:sessionId
  const ChatPage({super.key, required this.sessionId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<ChatCubit, ChatState>(
          builder: (context, state) {
            final active = state.sessions.firstWhere(
              (s) => s.id == state.activeId,
              orElse: () => state.sessions.isNotEmpty ? state.sessions.first : ChatSession(id: 'new', title: 'چت', createdAt: DateTime.now(), messages: []),
            );
            return Text(active.title);
          },
        ),
        actions: [
          BlocBuilder<ChatCubit, ChatState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  final active = context.read<ChatCubit>().state.active;
                  if (active == null || active.messages.isEmpty) return;
                  if (active.messages.isEmpty) return;
                  final text = active.messages
                      .map((m) => '${m.sender}: ${m.text}${m.imagesB64.isNotEmpty ? ' [تصویر]' : ''}')
                      .join('\n');
                  SharePlus.instance.share(ShareParams(text: text, subject: active.title));
                },
                icon: const Icon(Icons.share),
              );
            },
          ),
        ],
      ),
      drawer: BlocBuilder<ChatCubit, ChatState>(
        builder: (context, state) {
          return SessionDrawer(
            sessions: state.sessions,
            activeId: state.activeId,
          );
        },
      ),
      body: SafeArea(
        child: BlocConsumer<ChatCubit, ChatState>(
          listener: (context, state) {
            if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
              context.read<ChatCubit>().clearError();
            }
            if (!state.isTyping) {
              _scrollToBottom();
            }
          },
          builder: (context, state) {
            final active = state.sessions.firstWhere(
              (s) => s.id == state.activeId,
              orElse: () => state.sessions.isNotEmpty ? state.sessions.first : ChatSession(id: 'new', title: 'چت', createdAt: DateTime.now(), messages: []),
            );
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    itemCount: active.messages.length,
                    itemBuilder: (_, i) {
                      final m = active.messages[i];
                      return MessageBubble(
                        msg: m,
                        onCopy: () => Clipboard.setData(ClipboardData(text: m.text)),
                        onDelete: () async {
                          await context.read<ChatCubit>().removeMessageAt(i);
                        },
                      );
                    },
                  ),
                ),
                if (state.isTyping)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('در حال نوشتن...', style: TextStyle(color: Colors.grey)),
                  ),
                Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                  ),
                  child: ChatInputArea(
                    controller: _controller,
                    focus: _focus,
                    onSend: (text, {imagesB64 = const [], String? pdfText}) {
                      context.read<ChatCubit>().send(text, imagesB64: imagesB64, pdfText: pdfText);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
