import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/snackbar.dart';
import 'bloc/prescriptions_cubit.dart';

class PreviousPrescriptionsPage extends StatefulWidget {
  const PreviousPrescriptionsPage({super.key});
  @override
  State<PreviousPrescriptionsPage> createState() => _PreviousPrescriptionsPageState();
}

class _PreviousPrescriptionsPageState extends State<PreviousPrescriptionsPage> {
  final _national = TextEditingController();

  void _load(BuildContext context) {
    if (_national.text.trim().isEmpty) {
      AppSnack.show(context, 'کد ملی را وارد کنید');
      return;
    }
    context.read<PrescriptionsCubit>().load(_national.text.trim());
  }

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
                    child: BlocBuilder<PrescriptionsCubit, PrescriptionsState>(
                      builder: (context, state) {
                        return FilledButton(
                          onPressed: state.isLoading ? null : () => _load(context),
                          child: const Text('دریافت'),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: BlocConsumer<PrescriptionsCubit, PrescriptionsState>(
                  listener: (context, state) {
                    if (state.errorMessage != null && state.errorMessage!.isNotEmpty) {
                      AppSnack.show(context, 'خطا: ${state.errorMessage}');
                      context.read<PrescriptionsCubit>().clearError();
                    }
                  },
                  builder: (context, state) {
                    if (state.isLoading && state.items.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return ListView.separated(
                      itemCount: state.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final it = state.items[i];
                        return ListTile(
                          leading: const Icon(Icons.receipt_long),
                          title: Text(it['title']?.toString() ?? 'نسخه'),
                          subtitle: Text(it['summary']?.toString() ?? ''),
                          trailing: Text(it['date']?.toString() ?? ''),
                        );
                      },
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
