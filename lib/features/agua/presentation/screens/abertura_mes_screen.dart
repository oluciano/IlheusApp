import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';
import 'package:ilheus_app/features/agua/presentation/widgets/form_fields.dart';
import 'package:ilheus_app/features/agua/presentation/widgets/month_year_picker.dart';

class AberturaMesScreen extends ConsumerWidget {
  const AberturaMesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(aberturaMesFormProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Abertura de Mês'),
        actions: [
          if (formState.mesAno != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Chip(label: Text(formState.mesAno!)),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (kIsWeb) _webBanner(context),
          Expanded(
            child: formState.mesAno == null
                ? _buildMesSelecionador(context, ref)
                : formState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _buildFormulario(context, ref, formState),
          ),
        ],
      ),
    );
  }

  Widget _webBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade100,
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo demonstração — dados não são salvos no navegador.',
              style: TextStyle(fontSize: 13, color: Colors.brown.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMesSelecionador(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_month, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Selecione o mês/ano para iniciar',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () async {
                final mesAno =
                    await MonthYearPickerSheet.show(context);
                if (mesAno != null && context.mounted) {
                  ref
                      .read(aberturaMesFormProvider.notifier)
                      .selecionarMes(mesAno);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Selecionar Mês/Ano'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulario(
    BuildContext context,
    WidgetRef ref,
    AberturaMesFormState state,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _secaoTitulo(context, 'Conta CORSAN'),
        _buildCorsanForm(context, ref, state.contaCorsan),
        const SizedBox(height: 24),
        _secaoTitulo(context, 'Conta de Luz'),
        _buildLuzForm(context, ref, state.contaLuz),
        const SizedBox(height: 24),
        _secaoTitulo(context, 'Condomínio'),
        _buildCondForm(context, ref, state.configuracaoMes),
        const SizedBox(height: 24),
        _secaoTitulo(context, 'Despesas Extras'),
        _buildDespesasExtras(context, ref, state),
        const SizedBox(height: 24),
        _buildBotoesAcao(context, ref, state),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildCorsanForm(
    BuildContext context,
    WidgetRef ref,
    ContaCorsan conta,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: IntInputFormField(
                    label: 'Leitura Anterior (m³)',
                    initialValue: conta.leituraAnteriorM3,
                    onChanged: (v) {
                      ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                            conta.copyWith(leituraAnteriorM3: v),
                          );
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: IntInputFormField(
                    label: 'Leitura Atual (m³)',
                    initialValue: conta.leituraAtualM3,
                    onChanged: (v) {
                      ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                            conta.copyWith(leituraAtualM3: v),
                          );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CurrencyInputFormField(
              label: 'Valor Água',
              initialValue: conta.valorAgua.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                      conta.copyWith(valorAgua: ValorMonetario.fromDouble(v)),
                    );
              },
            ),
            const SizedBox(height: 16),
            CurrencyInputFormField(
              label: 'Valor Esgoto',
              initialValue: conta.valorEsgoto.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                      conta.copyWith(valorEsgoto: ValorMonetario.fromDouble(v)),
                    );
              },
            ),
            const SizedBox(height: 16),
            CurrencyInputFormField(
              label: 'Serviço Básico',
              initialValue: conta.valorServicoBasico.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                      conta.copyWith(
                          valorServicoBasico: ValorMonetario.fromDouble(v)),
                    );
              },
            ),
            const SizedBox(height: 16),
            CurrencyInputFormField(
              label: 'Juros (opcional)',
              initialValue: conta.valorJuros?.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                      conta.copyWith(
                          valorJuros: v > 0
                              ? ValorMonetario.fromDouble(v)
                              : null),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLuzForm(
    BuildContext context,
    WidgetRef ref,
    ContaLuz conta,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CurrencyInputFormField(
              label: 'Valor Total',
              initialValue: conta.valorTotal.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarContaLuz(
                      conta.copyWith(valorTotal: ValorMonetario.fromDouble(v)),
                    );
              },
            ),
            const SizedBox(height: 16),
            CurrencyInputFormField(
              label: 'Juros (opcional)',
              initialValue: conta.valorJuros?.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarContaLuz(
                      conta.copyWith(
                          valorJuros: v > 0
                              ? ValorMonetario.fromDouble(v)
                              : null),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCondForm(
    BuildContext context,
    WidgetRef ref,
    ConfiguracaoMes config,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CurrencyInputFormField(
              label: 'Valor do Condomínio',
              initialValue: config.valorCond.toDouble(),
              onChanged: (v) {
                ref.read(aberturaMesFormProvider.notifier).atualizarConfiguracaoMes(
                      config.copyWith(valorCond: ValorMonetario.fromDouble(v)),
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDespesasExtras(
    BuildContext context,
    WidgetRef ref,
    AberturaMesFormState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ...state.despesasExtras.map((d) => _despesaExtraItem(context, ref, d)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _adicionarDespesa(context, ref, state.mesAno!),
          icon: const Icon(Icons.add),
          label: const Text('Adicionar Despesa Extra'),
        ),
      ],
    );
  }

  Widget _despesaExtraItem(
    BuildContext context,
    WidgetRef ref,
    DespesaExtra despesa,
  ) {
    return Card(
      child: ListTile(
        title: Text(despesa.descricao),
        subtitle: Text('R\$ ${despesa.valorTotal}'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {
            if (despesa.id != null) {
              ref
                  .read(aberturaMesFormProvider.notifier)
                  .removerDespesaExtra(despesa.id!);
            }
          },
        ),
      ),
    );
  }

  void _adicionarDespesa(
    BuildContext context,
    WidgetRef ref,
    String mesAno,
  ) {
    final descricaoController = TextEditingController();
    double? valor;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Despesa Extra'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: descricaoController,
                decoration: const InputDecoration(
                  label: Text('Descrição'),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CurrencyInputFormField(
                label: 'Valor Total',
                onChanged: (v) => valor = v,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final descricao = descricaoController.text.trim();
                if (descricao.isNotEmpty && valor != null && valor! > 0) {
                  ref
                      .read(aberturaMesFormProvider.notifier)
                      .adicionarDespesaExtra(DespesaExtra(
                        mesAno: mesAno,
                        descricao: descricao,
                        valorTotal: ValorMonetario.fromDouble(valor!),
                      ));
                  Navigator.pop(context);
                }
              },
              child: const Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBotoesAcao(
    BuildContext context,
    WidgetRef ref,
    AberturaMesFormState state,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: () async {
            final sucesso =
                await ref.read(aberturaMesFormProvider.notifier).salvar();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    sucesso ? 'Mês salvo com sucesso!' : 'Erro ao salvar mês.',
                  ),
                  backgroundColor:
                      sucesso ? Colors.green : Colors.red,
                ),
              );
            }
          },
          icon: const Icon(Icons.save),
          label: const Text('Salvar'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: state.isSalvo
              ? () {
                  // Navegar para tela de lançamentos de leituras
                }
              : null,
          icon: const Icon(Icons.fact_check),
          label: const Text('Lançar Leituras'),
        ),
        if (!state.isSalvo) ...[
          const SizedBox(height: 8),
          const Text(
            'Salve o mês para habilitar o lançamento de leituras.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ],
    );
  }

  Widget _secaoTitulo(BuildContext context, String titulo) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        titulo,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
