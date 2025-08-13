import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactInfoPage extends StatelessWidget {
  const ContactInfoPage({super.key});

  Future<void> _open(Uri uri) async { await launchUrl(uri, mode: LaunchMode.externalApplication); }

  @override
  Widget build(BuildContext context) {
    final items = <_Item>[
      _Item(icon: Icons.phone, label: 'تلفن پشتیبانی', value: '+989961733668', uri: Uri.parse('tel:+989961733668')),
      _Item(icon: Icons.email_outlined, label: 'ایمیل', value: 'support@helssa.ir', uri: Uri.parse('mailto:support@helssa.ir')),
      _Item(icon: Icons.language, label: 'وب‌سایت', value: 'helssa.ir', uri: Uri.parse('https://helssa.ir')),
      _Item(icon: Icons.telegram, label: 'تلگرام', value: '@helssa', uri: Uri.parse('https://t.me/helssa')),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('تماس با ما')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final it = items[i];
                return ListTile(
                  leading: Icon(it.icon),
                  title: Text(it.label),
                  subtitle: Text(it.value),
                  trailing: const Icon(Icons.open_in_new),
                  onTap: () => _open(it.uri),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _Item { final IconData icon; final String label; final String value; final Uri uri;
  _Item({required this.icon, required this.label, required this.value, required this.uri});
}
