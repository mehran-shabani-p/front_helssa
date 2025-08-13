import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/visit_service.dart';

class PreviousPrescriptionsPage extends StatefulWidget {
  const PreviousPrescriptionsPage({super.key});
  @override
  State<PreviousPrescriptionsPage> createState() => _PreviousPrescriptionsPageState();
}

class _PreviousPrescriptionsPageState extends State<PreviousPrescriptionsPage> {
  final _svc = VisitService();
  bool _busy = false;
  List<Map<String, dynamic>> _items = const [];

  Future<void> _load() async {
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString('access_token') ?? '';
      _items = await _svc.previousPrescriptions(t);
    } catch (e) { _snack('خطا: $e'); }
    finally { setState(() => _busy = false); }
  }

  void _snack(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  void initState() { super.initState(); _load(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسخه‌های قبلی')),
      body: SafeArea(
        child: _busy
            ? const Center(child: CircularProgressIndicator())
            : ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final it = _items[i];
                  return ListTile(
                    leading: const Icon(Icons.receipt_long),
                    title: Text(it['title']?.toString() ?? 'نسخه'),
                    subtitle: Text(it['summary']?.toString() ?? ''),
                    trailing: Text(it['date']?.toString() ?? ''),
                  );
                },
              ),
      ),
    );
  }
}
