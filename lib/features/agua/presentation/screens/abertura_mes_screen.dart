import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';
import 'package:ilheus_app/features/agua/presentation/screens/home_screen.dart';
import 'package:ilheus_app/features/agua/presentation/widgets/form_fields.dart';
import 'package:ilheus_app/features/agua/presentation/widgets/month_year_picker.dart';

class AberturaMesScreen extends ConsumerWidget {
  const AberturaMesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(aberturaMesFormProvider);
    final temMesSelecionado = formState.mesAno != null;

    Future<bool> confirmarSaida() async {
      final hasChanges =
          ref.read(aberturaMesFormProvider.notifier).hasChanges;
      if (!hasChanges) return true;

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Alterações não salvas'),
          content: const Text(
            'Você fez alterações que ainda não foram salvas. '
            'Deseja realmente sair e descartar as mudanças?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continuar Editando'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Sair e Descartar'),
            ),
          ],
        ),
      );
      return result ?? false;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final podeSair = await confirmarSaida();
        if (podeSair) {
          ref.read(aberturaMesFormProvider.notifier).reset();
          if (context.mounted) context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              final podeSair = await confirmarSaida();
              if (podeSair) {
                ref.read(aberturaMesFormProvider.notifier).reset();
                if (context.mounted) context.go('/home');
              }
            },
            tooltip: 'Voltar',
          ),
          title: temMesSelecionado
              ? Text('Abertura do Mês ${formState.mesAno}')
              : const Text('Abertura de Mês'),
          actions: [
            if (temMesSelecionado)
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
              child: !temMesSelecionado
                  ? _buildMesSelecionador(context, ref)
                  : formState.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildDashboardConfiguracao(context, ref, formState),
            ),
          ],
        ),
        bottomNavigationBar: (temMesSelecionado && !formState.isLoading)
            ? _buildAcoesFixas(context, ref, formState)
            : null,
      ),
    );
  }

  Widget _buildAcoesFixas(
    BuildContext context,
    WidgetRef ref,
    AberturaMesFormState state,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isSalvo && state.leituraCompleta)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Leituras concluídas!',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final sucesso =
                        await ref.read(aberturaMesFormProvider.notifier).salvar();
                    if (!context.mounted) return;

                    if (sucesso) {
                      ref.invalidate(mesesSalvosProvider);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
                          title: const Text('Dados Salvos'),
                          content: const Text('As informações financeiras foram atualizadas. Deseja iniciar o lançamento das leituras agora?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Depois'),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.pop(context);
                                final mesAnoEncoded = Uri.encodeComponent(state.mesAno!);
                                context.go('/lancamento-leituras/$mesAnoEncoded');
                              },
                              child: const Text('Sim, Lançar Leituras'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Salvar'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: state.leituraCompleta
                    ? FilledButton.icon(
                        onPressed: () {
                          final mesAnoEncoded =
                              Uri.encodeComponent(state.mesAno!);
                          context.push('/fechamento-mensal/$mesAnoEncoded');
                        },
                        icon: const Icon(Icons.fact_check),
                        label: const Text('Fechar Mês'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: state.isSalvo
                            ? () {
                                final mesAnoEncoded =
                                    Uri.encodeComponent(state.mesAno!);
                                context
                                    .go('/lancamento-leituras/$mesAnoEncoded');
                              }
                            : null,
                        icon: const Icon(Icons.edit_note),
                        label: const Text('Leituras'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
              ),
            ],
          ),
          if (!state.isSalvo)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Salve para habilitar lançamentos.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey),
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
            const Icon(Icons.calendar_month, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Gestão de Condomínio',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Selecione o mês/ano para iniciar a configuração das contas.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () async {
                final mesAno = await MonthYearPickerSheet.show(context);
                if (mesAno == null || !context.mounted) return;

                final jaExiste = await ref
                    .read(aberturaMesFormProvider.notifier)
                    .mesJaCadastrado(mesAno);

                if (!context.mounted) return;

                if (jaExiste) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('O mês $mesAno já está cadastrado.'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                } else {
                  await ref
                      .read(aberturaMesFormProvider.notifier)
                      .abrirNovoMes(mesAno);
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Selecionar Mês/Ano'),
              style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardConfiguracao(
    BuildContext context,
    WidgetRef ref,
    AberturaMesFormState state,
  ) {
    final totalCorsan = state.contaCorsan.valorAgua.centavos + 
                        state.contaCorsan.valorEsgoto.centavos + 
                        state.contaCorsan.valorServicoBasico.centavos +
                        (state.contaCorsan.valorJuros?.centavos ?? 0);
    
    final totalDespesas = state.despesasExtras.fold<int>(0, (sum, d) => sum + d.valorTotal.centavos);

    return GridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.0,
      children: [
        _ConfigTile(
          title: 'CORSAN',
          subtitle: state.contaCorsan.leituraAnteriorM3 == 0 && state.contaCorsan.leituraAtualM3 == 0
              ? 'Pendente'
              : '${state.contaCorsan.leituraAtualM3 - state.contaCorsan.leituraAnteriorM3} m³',
          value: 'R\$ ${_formatarCentavos(totalCorsan)}',
          icon: Icons.water_drop,
          color: Colors.cyan,
          onTap: () => _abrirEditCorsan(context, ref, state),
        ),
        _ConfigTile(
          title: 'Energia Elétrica',
          subtitle: 'Conta de Luz',
          value: 'R\$ ${_formatarCentavos(state.contaLuz.valorTotal.centavos)}',
          icon: Icons.bolt,
          color: Colors.orange,
          onTap: () => _abrirEditLuz(context, ref, state),
        ),
        _ConfigTile(
          title: 'Condomínio',
          subtitle: 'Valor Fixo',
          value: 'R\$ ${_formatarCentavos(state.configuracaoMes.valorCond.centavos)}',
          icon: Icons.home_work,
          color: Colors.blue,
          onTap: () => _abrirEditCond(context, ref, state),
        ),
        _ConfigTile(
          title: 'Despesas Extras',
          subtitle: '${state.despesasExtras.length} itens',
          value: 'R\$ ${_formatarCentavos(totalDespesas)}',
          icon: Icons.add_shopping_cart,
          color: Colors.purple,
          onTap: () => _abrirEditDespesas(context, ref, state),
        ),
      ],
    );
  }

  void _abrirEditCorsan(BuildContext context, WidgetRef ref, AberturaMesFormState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditorBottomSheet(
        title: 'Configurar CORSAN',
        icon: Icons.water_drop,
        color: Colors.cyan,
        child: _CorsanFields(state: state),
      ),
    );
  }

  void _abrirEditLuz(BuildContext context, WidgetRef ref, AberturaMesFormState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditorBottomSheet(
        title: 'Configurar Luz',
        icon: Icons.bolt,
        color: Colors.orange,
        child: _LuzFields(state: state),
      ),
    );
  }

  void _abrirEditCond(BuildContext context, WidgetRef ref, AberturaMesFormState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditorBottomSheet(
        title: 'Configurar Condomínio',
        icon: Icons.home_work,
        color: Colors.blue,
        child: _CondFields(state: state),
      ),
    );
  }

  void _abrirEditDespesas(BuildContext context, WidgetRef ref, AberturaMesFormState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _EditorBottomSheet(
        title: 'Despesas Extras',
        icon: Icons.add_shopping_cart,
        color: Colors.purple,
        child: _DespesasFields(state: state),
      ),
    );
  }

  String _formatarCentavos(int centavos) {
    return (centavos / 100).toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _webBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.amber.shade100,
      child: const Row(
        children: [
          Icon(Icons.info_outline, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Modo demonstração — dados não são salvos no navegador.',
              style: TextStyle(fontSize: 13, color: Colors.brown),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ConfigTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isZero = value == 'R\$ 0,00';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: isZero ? color.withOpacity(0.3) : color.withOpacity(0.5), width: 1.5),
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isZero ? Colors.grey : color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorBottomSheet extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _EditorBottomSheet({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 16),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),
            child,
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CorsanFields extends ConsumerWidget {
  final AberturaMesFormState state;
  const _CorsanFields({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conta = state.contaCorsan;
    final anterior = state.contaCorsanAnterior;
    final consumoCalculado = conta.leituraAtualM3 - conta.leituraAnteriorM3;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: IntInputFormField(
                label: 'Anterior (m³)',
                initialValue: conta.leituraAnteriorM3,
                onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(conta.copyWith(leituraAnteriorM3: v)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: IntInputFormField(
                label: 'Atual (m³)',
                initialValue: conta.leituraAtualM3,
                onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(conta.copyWith(leituraAtualM3: v)),
              ),
            ),
          ],
        ),
        if (consumoCalculado > 0)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('Consumo calculado: $consumoCalculado m³', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
          ),
        const SizedBox(height: 16),
        CurrencyInputFormField(
          label: 'Valor Água',
          initialValue: conta.valorAgua.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(conta.copyWith(valorAgua: ValorMonetario.fromDouble(v))),
        ),
        _labelAnterior(anterior?.valorAgua.toString()),
        const SizedBox(height: 16),
        CurrencyInputFormField(
          label: 'Valor Esgoto',
          initialValue: conta.valorEsgoto.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(conta.copyWith(valorEsgoto: ValorMonetario.fromDouble(v))),
        ),
        _labelAnterior(anterior?.valorEsgoto.toString()),
        const SizedBox(height: 16),
        CurrencyInputFormField(
          label: 'Serviço Básico',
          initialValue: conta.valorServicoBasico.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(conta.copyWith(valorServicoBasico: ValorMonetario.fromDouble(v))),
        ),
        _labelAnterior(anterior?.valorServicoBasico.toString()),
        const SizedBox(height: 16),
        CurrencyInputFormField(
          label: 'Juros CORSAN (opcional)',
          initialValue: conta.valorJuros?.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaCorsan(
                conta.copyWith(valorJuros: v > 0 ? ValorMonetario.fromDouble(v) : null),
              ),
        ),
        _labelAnterior(anterior?.valorJuros?.toString()),
      ],
    );
  }

  Widget _labelAnterior(String? valor) {
    if (valor == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text('Mês anterior: R\$ $valor', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }
}

class _LuzFields extends ConsumerWidget {
  final AberturaMesFormState state;
  const _LuzFields({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conta = state.contaLuz;
    final anterior = state.contaLuzAnterior;

    return Column(
      children: [
        CurrencyInputFormField(
          label: 'Valor Total da Luz',
          initialValue: conta.valorTotal.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaLuz(conta.copyWith(valorTotal: ValorMonetario.fromDouble(v))),
        ),
        if (anterior != null)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text('Mês anterior: R\$ ${anterior.valorTotal}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
            ),
          ),
        const SizedBox(height: 16),
        CurrencyInputFormField(
          label: 'Juros Luz (opcional)',
          initialValue: conta.valorJuros?.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarContaLuz(
                conta.copyWith(valorJuros: v > 0 ? ValorMonetario.fromDouble(v) : null),
              ),
        ),
        _labelAnterior(anterior?.valorJuros?.toString()),
      ],
    );
  }

  Widget _labelAnterior(String? valor) {
    if (valor == null) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(top: 4, left: 4),
        child: Text('Mês anterior: R\$ $valor',
            style: const TextStyle(
                fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
      ),
    );
  }
}

class _CondFields extends ConsumerWidget {
  final AberturaMesFormState state;
  const _CondFields({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = state.configuracaoMes;
    final anterior = state.configuracaoAnterior;

    return Column(
      children: [
        CurrencyInputFormField(
          label: 'Valor do Condomínio',
          initialValue: config.valorCond.toDouble(),
          onChanged: (v) => ref.read(aberturaMesFormProvider.notifier).atualizarConfiguracaoMes(config.copyWith(valorCond: ValorMonetario.fromDouble(v))),
        ),
        if (anterior != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mês anterior: R\$ ${anterior.valorCond}', style: const TextStyle(fontSize: 11, color: Colors.grey, fontStyle: FontStyle.italic)),
              TextButton.icon(
                onPressed: () => ref.read(aberturaMesFormProvider.notifier).atualizarConfiguracaoMes(config.copyWith(valorCond: anterior.valorCond)),
                icon: const Icon(Icons.copy, size: 14),
                label: const Text('Repetir', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
      ],
    );
  }
}

class _DespesasFields extends ConsumerWidget {
  final AberturaMesFormState state;
  const _DespesasFields({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        if (state.despesasExtras.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Nenhuma despesa extra adicionada.',
              style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic, fontSize: 13),
            ),
          ),
        ...state.despesasExtras.map((d) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          shape: RoundedRectangleBorder(
            side: BorderSide(color: Colors.purple.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            onTap: () => _abrirEditorDespesa(context, ref, state.mesAno!, despesa: d),
            leading: CircleAvatar(
              backgroundColor: Colors.purple.withOpacity(0.1),
              child: const Icon(Icons.receipt_long, size: 18, color: Colors.purple),
            ),
            title: Text(d.descricao, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
            subtitle: Text('R\$ ${d.valorTotal}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
              onPressed: () {
                if (d.id != null) {
                  ref.read(aberturaMesFormProvider.notifier).removerDespesaExtra(d.id!);
                }
              },
            ),
          ),
        )),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _abrirEditorDespesa(context, ref, state.mesAno!),
          icon: const Icon(Icons.add),
          label: const Text('Nova Despesa Extra'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.purple,
            side: const BorderSide(color: Colors.purple),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  void _abrirEditorDespesa(BuildContext context, WidgetRef ref, String mesAno, {DespesaExtra? despesa}) {
    final isEdicao = despesa != null;
    final descricaoController = TextEditingController(text: despesa?.descricao ?? '');
    double valorAtual = despesa?.valorTotal.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(isEdicao ? Icons.edit : Icons.add_shopping_cart, color: Colors.purple),
        title: Text(isEdicao ? 'Editar Despesa' : 'Nova Despesa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Informe a descrição e o valor da despesa que será rateada entre as casas.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            TextField(
              controller: descricaoController,
              autofocus: !isEdicao,
              decoration: const InputDecoration(
                label: Text('Descrição (ex: Manutenção Bomba)'),
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description_outlined),
              ),
            ),
            const SizedBox(height: 16),
            CurrencyInputFormField(
              label: 'Valor Total',
              initialValue: isEdicao ? valorAtual : null,
              onChanged: (v) => valorAtual = v,
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
              if (descricao.isNotEmpty && valorAtual > 0) {
                if (isEdicao) {
                  ref.read(aberturaMesFormProvider.notifier).atualizarDespesaExtra(
                    despesa.copyWith(
                      descricao: descricao,
                      valorTotal: ValorMonetario.fromDouble(valorAtual),
                    ),
                  );
                } else {
                  ref.read(aberturaMesFormProvider.notifier).adicionarDespesaExtra(
                    DespesaExtra(
                      mesAno: mesAno,
                      descricao: descricao,
                      valorTotal: ValorMonetario.fromDouble(valorAtual),
                    ),
                  );
                }
                Navigator.pop(context);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.purple),
            child: Text(isEdicao ? 'Salvar Alterações' : 'Adicionar Despesa'),
          ),
        ],
      ),
    );
  }
}
