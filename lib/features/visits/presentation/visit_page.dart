import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc/visits_cubit.dart';

class VisitPage extends StatefulWidget {
  const VisitPage({super.key});
  @override
  State<VisitPage> createState() => _VisitPageState();
}

class _VisitPageState extends State<VisitPage> {
  final _desc = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => context.read<VisitsCubit>().load());
  }

  void _snack(BuildContext context, String m, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(m), backgroundColor: error ? Colors.red.shade700 : null));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ویزیت آنلاین')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Expanded(
                    child: TextField(
                        controller: _desc,
                        minLines: 1,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(hintText: 'شرح مشکل...'))),
                const SizedBox(width: 8),
                BlocBuilder<VisitsCubit, VisitsState>(
                  builder: (context, state) {
                    return FilledButton.icon(
                      onPressed: state.isLoading
                          ? null
                          : () => context
                                  .read<VisitsCubit>()
                                  .requestVisit(_desc.text.trim())
                                  .then((_) {
                                if (_desc.text.trim().isNotEmpty) {
                                  _desc.clear();
                                  _snack(context, 'درخواست ثبت شد.');
                                }
                              }),
                      icon: const Icon(Icons.send),
                      label: const Text('درخواست'),
                    );
                  },
                ),
              ]),
            ),
            const Divider(height: 1),
            Expanded(
              child: BlocConsumer<VisitsCubit, VisitsState>(
                listener: (context, state) {
                  if (state.errorMessage != null &&
                      state.errorMessage!.isNotEmpty) {
                    _snack(context, 'خطا: ${state.errorMessage}', error: true);
                    context.read<VisitsCubit>().clearError();
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
                        title: Text(it['title']?.toString() ?? 'ویزیت'),
                        subtitle: Text(it['status']?.toString() ?? 'نامشخص'),
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
    );
  }
}
