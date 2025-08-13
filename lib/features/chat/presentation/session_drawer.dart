import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../domain/chat_session.dart';

class SessionDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? activeId;
  final Future<void> Function() onCreate;
  final Future<void> Function(ChatSession) onRename;
  final Future<void> Function(ChatSession) onDelete;

  const SessionDrawer({super.key, required this.sessions, required this.activeId, required this.onCreate, required this.onRename, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(leading: const Icon(Icons.add), title: const Text('جلسه جدید'), onTap: () async { Navigator.pop(context); await onCreate(); }),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: sessions.length,
                itemBuilder: (_, i) {
                  final s = sessions[i];
                  final selected = s.id == activeId;
                  return ListTile(
                    selected: selected,
                    leading: const Icon(Icons.chat_bubble_outline),
                    title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('${s.createdAt}'),
                    onTap: () { Navigator.pop(context); context.go('/chat/${s.id}'); },
                    trailing: PopupMenuButton(
                      itemBuilder: (_) => const [PopupMenuItem(value: 'rename', child: Text('تغییر نام')), PopupMenuItem(value: 'delete', child: Text('حذف'))],
                      onSelected: (v) async { if (v == 'rename') await onRename(s); if (v == 'delete') await onDelete(s); },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
