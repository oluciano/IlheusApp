import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';

class LancamentoLeiturasScreen extends ConsumerStatefulWidget {
  final String mesAno;

  const LancamentoLeiturasScreen({super.key, required this.mesAno});

  @override
  ConsumerState<LancamentoLeiturasScreen> createState() =>
      _LancamentoLeiturasScreenState();
}

class _LancamentoLeiturasScreenState
    extends ConsumerState<LancamentoLeiturasScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lancamentoLeiturasProvider(widget.mesAno).notifier)
          .carregarDados();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(lancamentoLeiturasProvider(widget.mesAno));
    final progress = state.totalCasas > 0
        ? state.casasComLeitura / state.totalCasas
        : 0.0;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
          tooltip: 'Voltar',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Lançamento de Leituras'),
            Text(
              _formatarMesAno(widget.mesAno),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Hero(
                tag: 'leitura-counter-${widget.mesAno}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Chip(
                    avatar: Icon(
                      state.leituraCompleta
                          ? Icons.check_circle
                          : Icons.pending,
                      size: 18,
                      color: state.leituraCompleta
                          ? Colors.green
                          : Colors.orange,
                    ),
                    label: Text(
                      '${state.casasComLeitura}/${state.totalCasas}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor:
                Theme.of(context).colorScheme.surfaceContainerHighest,
          ),
          if (state.errorMessage != null) _errorBanner(context, ref, state),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: state.isLoading
                  ? const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(),
                    )
                  : state.casas.isEmpty && !state.isLoading
                      ? _emptyState(context)
                      : _buildLista(context, ref, state),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _bottomBar(context, state),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.water_drop_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhuma casa encontrada',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
          ),
        ],
      ),
    );
  }

  Widget _errorBanner(
    BuildContext context,
    WidgetRef ref,
    LancamentoLeiturasState state,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              state.errorMessage!,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              ref.read(lancamentoLeiturasProvider(widget.mesAno).notifier)
                  .limparErro();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLista(
    BuildContext context,
    WidgetRef ref,
    LancamentoLeiturasState state,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(lancamentoLeiturasProvider(widget.mesAno).notifier)
            .carregarDados();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.casas.length,
        itemBuilder: (_, index) {
          final casa = state.casas[index];
          final leituraAtual = state.getLeituraAtual(casa.id);
          final leituraAnterior = state.getLeituraAnterior(casa.id);

          return _CardCasa(
            casa: casa,
            leituraAtual: leituraAtual,
            leituraAnterior: leituraAnterior,
            onTap: () => _abrirBottomSheet(context, ref, casa, state),
          );
        },
      ),
    );
  }

  Widget _bottomBar(BuildContext context, LancamentoLeiturasState state) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: FilledButton.icon(
            onPressed: state.leituraCompleta
                ? () {
                    context.push('/fechamento-mensal/${Uri.encodeComponent(widget.mesAno)}');
                  }
                : null,
            icon: const Icon(Icons.fact_check),
            label: Text(
              state.leituraCompleta
                  ? 'Ir para Fechamento →'
                  : 'Fechamento bloqueado (${state.casasComLeitura}/${state.totalCasas})',
            ),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }

  void _abrirBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Casa casa,
    LancamentoLeiturasState state,
  ) {
    final leituraAnterior = state.getLeituraAnterior(casa.id);
    final leituraExistente = state.getLeituraAtual(casa.id);
    final controller = TextEditingController(
      text: leituraExistente?.leituraAtualM3.toString() ?? '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _LeituraBottomSheet(
        casa: casa,
        leituraAnterior: leituraAnterior,
        controller: controller,
        isUltimaCasa: state.casas.last.id == casa.id,
        onSave: (valor, continuar) async {
          final sucesso = await ref
              .read(lancamentoLeiturasProvider(widget.mesAno).notifier)
              .salvarLeitura(
                casaId: casa.id,
                leituraAtual: valor,
              );

          if (!context.mounted) return;

          if (sucesso) {
            ref.invalidate(mesesSalvosProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Casa ${casa.numero} atualizada'),
                backgroundColor: Colors.green.shade700,
                duration: const Duration(milliseconds: 800),
                behavior: SnackBarBehavior.floating,
                width: 200,
              ),
            );

            if (continuar) {
              final indexAtual = state.casas.indexWhere((c) => c.id == casa.id);
              if (indexAtual < state.casas.length - 1) {
                final proximaCasa = state.casas[indexAtual + 1];
                Navigator.pop(context);
                Future.delayed(const Duration(milliseconds: 100), () {
                  if (context.mounted) {
                    _abrirBottomSheet(context, ref, proximaCasa, ref.read(lancamentoLeiturasProvider(widget.mesAno)));
                  }
                });
              } else {
                Navigator.pop(context);
              }
            } else {
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }

  String _formatarMesAno(String mesAno) {
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

// ─── Card da Casa ────────────────────────────────────────────────────────────

class _CardCasa extends StatelessWidget {
  final Casa casa;
  final Leitura? leituraAtual;
  final int leituraAnterior;
  final VoidCallback onTap;

  const _CardCasa({
    required this.casa,
    required this.leituraAtual,
    required this.leituraAnterior,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final temLeitura = leituraAtual != null;
    final consumo = temLeitura
        ? leituraAtual!.leituraAtualM3 - leituraAtual!.leituraAnteriorM3
        : null;
    final theme = Theme.of(context);

    return Semantics(
      label: 'Casa ${casa.numero}'
          '${casa.isento ? ', isenta' : ''}'
          ', ${temLeitura ? "leitura $consumo" : "sem leitura"}',
      button: true,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: temLeitura
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : null,
        child: ListTile(
          onTap: onTap,
          leading: CircleAvatar(
            backgroundColor: temLeitura
                ? theme.colorScheme.primary
                : Colors.grey.shade400,
            child: Text(
              casa.numero.toString().padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          title: Text(
            'Casa ${casa.numero.toString().padLeft(2, '0')}'
            '${casa.isento ? ' (Isenta)' : ''}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: temLeitura ? null : Colors.grey,
            ),
          ),
          subtitle: Text(
            temLeitura
                ? 'Consumo: $consumo m³'
                : 'Leitura anterior: $leituraAnterior m³',
            style: TextStyle(
              fontSize: 13,
              color: temLeitura ? null : Colors.grey.shade600,
            ),
          ),
          trailing: temLeitura
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${leituraAtual!.leituraAtualM3} m³',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 18,
                    ),
                  ],
                )
              : Text(
                  '\u2014 m³',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet de Leitura ─────────────────────────────────────────────────

class _LeituraBottomSheet extends StatefulWidget {
  final Casa casa;
  final int leituraAnterior;
  final TextEditingController controller;
  final bool isUltimaCasa;
  final Future<void> Function(int valor, bool continuar) onSave;

  const _LeituraBottomSheet({
    required this.casa,
    required this.leituraAnterior,
    required this.controller,
    required this.isUltimaCasa,
    required this.onSave,
  });

  @override
  State<_LeituraBottomSheet> createState() => _LeituraBottomSheetState();
}

class _LeituraBottomSheetState extends State<_LeituraBottomSheet> {
  bool _isSaving = false;
  String? _erroValidacao;

  Future<void> _salvar({required bool continuar}) async {
    final texto = widget.controller.text.trim();
    if (texto.isEmpty) {
      setState(() => _erroValidacao = 'Informe a leitura atual.');
      return;
    }

    final valor = int.tryParse(texto);
    if (valor == null) {
      setState(
        () => _erroValidacao = 'Valor inválido. Digite um número inteiro.',
      );
      return;
    }

    if (valor < widget.leituraAnterior) {
      setState(() {
        _erroValidacao =
            'Leitura atual ($valor) não pode ser menor '
            'que a anterior (${widget.leituraAnterior}).';
      });
      return;
    }

    setState(() {
      _erroValidacao = null;
      _isSaving = true;
    });

    await widget.onSave(valor, continuar);

    if (mounted) {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final keyboardPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardPadding),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancelar',
                  ),
                  Text(
                    'Leitura — Casa ${widget.casa.numero.toString().padLeft(2, '0')}',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 48), 
                ],
              ),
              const SizedBox(height: 16),
              _campoReadonly(
                label: 'Leitura anterior',
                valor: '${widget.leituraAnterior} m³',
              ),
              const SizedBox(height: 16),
              _campoEditavel(),
              if (_erroValidacao != null) ...[
                const SizedBox(height: 8),
                Text(
                  _erroValidacao!,
                  style: TextStyle(color: theme.colorScheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : () => _salvar(continuar: false),
                      child: const Text('Salvar e Sair'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: (_isSaving || widget.isUltimaCasa) ? null : () => _salvar(continuar: true),
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.arrow_forward),
                      label: Text(widget.isUltimaCasa ? 'Finalizar' : 'Salvar e Próxima'),
                    ),
                  ),
                ],
              ),
              if (widget.isUltimaCasa)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton(
                    onPressed: _isSaving ? null : () => _salvar(continuar: false),
                    child: const Text('Salvar e Concluir'),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _campoReadonly({required String label, required String valor}) {
    return TextFormField(
      initialValue: valor,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  Widget _campoEditavel() {
    return TextFormField(
      controller: widget.controller,
      keyboardType: const TextInputType.numberWithOptions(),
      autofocus: true,
      decoration: const InputDecoration(
        label: Text('Leitura atual (m³)'),
        border: OutlineInputBorder(),
        hintText: 'Ex: 150',
        prefixIcon: Icon(Icons.speed),
      ),
      onChanged: (_) {
        if (_erroValidacao != null) {
          setState(() => _erroValidacao = null);
        }
      },
    );
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }
}
