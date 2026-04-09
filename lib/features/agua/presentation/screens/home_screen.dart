import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';

final mesesSalvosProvider = FutureProvider<List<String>>((ref) async {
  final repository = ref.watch(aberturaMesRepositoryProvider);
  if (repository == null) return [];
  return repository.listarTodosMeses();
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mesesAsync = ref.watch(mesesSalvosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ilhéus App'),
      ),
      body: mesesAsync.when(
        data: (meses) {
          if (meses.isEmpty) {
            return const _EmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: meses.length,
            itemBuilder: (_, i) {
              final mesAno = meses[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(_nomeMesFormatado(mesAno)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref
                        .read(aberturaMesFormProvider.notifier)
                        .abrirMesExistente(mesAno);
                    context.go('/abertura-mes');
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erro: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ref.invalidate(aberturaMesFormProvider);
          context.go('/abertura-mes');
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo Mês'),
      ),
    );
  }

  String _nomeMesFormatado(String mesAno) {
    const meses = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro',
    ];
    final parts = mesAno.split('/');
    if (parts.length != 2) return mesAno;
    final mes = int.tryParse(parts[0]);
    if (mes == null || mes < 1 || mes > 12) return mesAno;
    return '${meses[mes - 1]} de ${parts[1]}';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum mês cadastrado',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque em "Novo Mês" para começar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }
}
