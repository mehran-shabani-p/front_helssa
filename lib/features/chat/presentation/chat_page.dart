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

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  final ScrollController _scroll = ScrollController();
  late AnimationController _overlayController;
  late Animation<double> _overlayAnimation;
  bool _showOverlay = false;

  @override
  void initState() {
    super.initState();
    _overlayController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _overlayAnimation = CurvedAnimation(
      parent: _overlayController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    _scroll.dispose();
    _overlayController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(_scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
      if (_showOverlay) {
        _overlayController.forward();
      } else {
        _overlayController.reverse();
      }
    });
  }

  void _hideOverlay() {
    if (_showOverlay) {
      setState(() {
        _showOverlay = false;
        _overlayController.reverse();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Main chat interface
            Column(
              children: [
                // Top header with session title and menu button
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Menu button
                      IconButton(
                        onPressed: _toggleOverlay,
                        icon: const Icon(Icons.menu),
                        style: IconButton.styleFrom(
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Session title
                      Expanded(
                        child: BlocBuilder<ChatCubit, ChatState>(
                          builder: (context, state) {
                            final active = state.sessions.firstWhere(
                              (s) => s.id == state.activeId,
                              orElse: () => state.sessions.isNotEmpty
                                  ? state.sessions.first
                                  : ChatSession(
                                      id: 'new',
                                      title: 'چت جدید',
                                      createdAt: DateTime.now(),
                                      messages: []),
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  active.title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (active.messages.isNotEmpty)
                                  Text(
                                    '${active.messages.length} پیام',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      // Share button
                      BlocBuilder<ChatCubit, ChatState>(
                        builder: (context, state) {
                          return IconButton(
                            onPressed: () {
                              final active = state.sessions.firstWhere(
                                (s) => s.id == state.activeId,
                                orElse: () => state.sessions.isNotEmpty
                                    ? state.sessions.first
                                    : ChatSession(
                                        id: 'new',
                                        title: 'چت جدید',
                                        createdAt: DateTime.now(),
                                        messages: []),
                              );
                              if (active.messages.isEmpty) return;
                              final text = active.messages
                                  .map((m) =>
                                      '${m.sender}: ${m.text}${m.imagesB64.isNotEmpty ? ' [تصویر]' : ''}')
                                  .join('\n');
                              SharePlus.instance.share(ShareParams(
                                  text: text, subject: active.title));
                            },
                            icon: const Icon(Icons.share_outlined),
                            style: IconButton.styleFrom(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.3),
                              foregroundColor:
                                  Theme.of(context).colorScheme.primary,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Chat messages area
                Expanded(
                  child: BlocConsumer<ChatCubit, ChatState>(
                    listener: (context, state) {
                      if (state.errorMessage != null &&
                          state.errorMessage!.isNotEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(state.errorMessage!),
                          behavior: SnackBarBehavior.floating,
                        ));
                        context.read<ChatCubit>().clearError();
                      }
                      if (!state.isTyping) {
                        _scrollToBottom();
                      }
                    },
                    builder: (context, state) {
                      final active = state.sessions.firstWhere(
                        (s) => s.id == state.activeId,
                        orElse: () => state.sessions.isNotEmpty
                            ? state.sessions.first
                            : ChatSession(
                                id: 'new',
                                title: 'چت جدید',
                                createdAt: DateTime.now(),
                                messages: []),
                      );

                      if (active.messages.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'چت جدید را شروع کنید',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineSmall
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.6),
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'سوال خود را بپرسید یا فایل ارسال کنید',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.4),
                                    ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 8),
                        itemCount:
                            active.messages.length + (state.isTyping ? 1 : 0),
                        itemBuilder: (_, i) {
                          if (i == active.messages.length && state.isTyping) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'در حال تایپ...',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.7),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final m = active.messages[i];
                          return MessageBubble(
                            msg: m,
                            onCopy: () =>
                                Clipboard.setData(ClipboardData(text: m.text)),
                            onDelete: () async {
                              await context
                                  .read<ChatCubit>()
                                  .removeMessageAt(i);
                            },
                          );
                        },
                      );
                    },
                  ),
                ),

                // Input area
                Container(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    bottom: MediaQuery.of(context).padding.bottom + 8,
                    top: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .dividerColor
                            .withValues(alpha: 0.1),
                      ),
                    ),
                  ),
                  child: ChatInputArea(
                    controller: _controller,
                    focus: _focus,
                    onSend: (text, {imagesB64 = const [], String? pdfText}) {
                      context
                          .read<ChatCubit>()
                          .send(text, imagesB64: imagesB64, pdfText: pdfText);
                      _hideOverlay();
                    },
                  ),
                ),
              ],
            ),

            // Overlay for navigation
            if (_showOverlay)
              GestureDetector(
                onTap: _hideOverlay,
                child: Container(
                  color: Colors.black54,
                  child: SafeArea(
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(-1.0, 0.0),
                        end: Offset.zero,
                      ).animate(_overlayAnimation),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Material(
                          child: Container(
                            width: MediaQuery.of(context).size.width * 0.85,
                            height: double.infinity,
                            child: BlocBuilder<ChatCubit, ChatState>(
                              builder: (context, state) {
                                return SessionDrawer(
                                  sessions: state.sessions,
                                  activeId: state.activeId,
                                  onNavigate: _hideOverlay,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
