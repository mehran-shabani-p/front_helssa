import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/utils/snackbar.dart';
import '../data/visit_service.dart';

class PreviousPrescriptionsPage extends StatefulWidget {
  const PreviousPrescriptionsPage({super.key});
  @override
  State<PreviousPrescriptionsPage> createState() => _PreviousPrescriptionsPageState();
}

class _PreviousPrescriptionsPageState extends State<PreviousPrescriptionsPage> {
  final _svc = VisitService();
  bool _busy = false;
  final _national = TextEditingController();
  List<Map<String, dynamic>> _items = const [];

  Future<void> _load() async {
    if (_national.text.trim().isEmpty) {
      AppSnack.show(context, 'کد ملی را وارد کنید');
      return;
    }
    setState(() => _busy = true);
    try {
      final sp = await SharedPreferences.getInstance();
      final t = sp.getString('access_token') ?? '';
      _items = await _svc.previousPrescriptions(t, _national.text.trim());
    } catch (e) {
      AppSnack.show(context, 'خطا: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  void initState() { super.initState(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('نسخه‌های قبلی')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _national,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'کد ملی'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('دریافت'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
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
            ],
          ),
        ),
      ),
    );
  }
}
