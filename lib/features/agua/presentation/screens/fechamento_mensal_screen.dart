import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/usecases/gerar_pdf_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/presentation/providers/providers.dart';
import 'package:ilheus_app/features/agua/presentation/providers/fechamento_mensal_notifier.dart';
import 'package:ilheus_app/features/agua/presentation/providers/fechamento_mensal_provider.dart';
import 'package:ilheus_app/features/agua/presentation/providers/fechamento_mensal_state.dart';
import 'package:ilheus_app/shared/widgets/main_layout.dart';

class FechamentoMensalScreen extends ConsumerWidget {
  final String mesAno;

  const FechamentoMensalScreen({super.key, required this.mesAno});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(fechamentoMensalProvider(mesAno));
    final notifier = ref.read(fechamentoMensalProvider(mesAno).notifier);

    // Escuta mudanças de status para navegação ou mensagens
    ref.listen(fechamentoMensalProvider(mesAno), (previous, next) {
      if (next.status == FechamentoMensalStatus.success) {
        ref.invalidate(mesesSalvosProvider);
        _exibirDialogoSucesso(context, next.pdfGerado);
      } else if (next.status == FechamentoMensalStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: ${next.errorMessage}')),
        );
      }
    });

    if (!state.leituraCompleta && state.status != FechamentoMensalStatus.loading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            tooltip: 'Voltar',
          ),
          title: const Text('Fechamento do Mês'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text(
                'Leituras incompletas!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('É necessário registrar a leitura de todas as 22 casas antes de fechar o mês.'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/home');
                  }
                },
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
          tooltip: 'Voltar',
        ),
        title: const Text('Fechamento do Mês'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(fechamentoMensalProvider(mesAno)),
            tooltip: 'Atualizar Dados',
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Text(mesAno, style: const TextStyle(fontSize: 14)),
        ),
      ),
      body: state.status == FechamentoMensalStatus.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSumarioTopo(state),
                  const SizedBox(height: 24),
                  _buildBloco1ResumoContas(state),
                  const SizedBox(height: 16),
                  _buildBloco2StatusLeituras(state),
                  const SizedBox(height: 16),
                  _buildBloco3AuditoriaPrevia(state),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final mesAnoEncoded = Uri.encodeComponent(mesAno);
                      ref.invalidate(fechamentoMensalProvider(mesAno));
                      context.push('/lancamento-leituras/$mesAnoEncoded');
                    },
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Editar Lançamentos'),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
      bottomNavigationBar: state.status == FechamentoMensalStatus.loading
          ? null
          : _buildBarraAcaoFixa(context, state, notifier),
    );
  }

  Widget _buildSumarioTopo(FechamentoMensalState state) {
    final totalArrecadado = state.cobrancas.fold<int>(0, (sum, c) => sum + c.valorTotal);
    final totalM3 = state.leituras.fold<int>(0, (sum, l) => sum + l.consumoM3);

    return Row(
      children: [
        Expanded(
          child: _cardMetrica(
            'Total Previsto',
            'R\$ ${_formatarCentavos(totalArrecadado)}',
            Icons.account_balance_wallet,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _cardMetrica(
            'Consumo Total',
            '$totalM3 m³',
            Icons.water_drop,
            Colors.cyan,
          ),
        ),
      ],
    );
  }

  Widget _cardMetrica(String label, String valor, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(valor, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildBarraAcaoFixa(
    BuildContext context,
    FechamentoMensalState state,
    FechamentoMensalNotifier notifier,
  ) {
    final temErro = state.auditoria?.temErro ?? false;
    final temAlerta = state.auditoria?.temAlerta ?? false;

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
          ElevatedButton.icon(
            onPressed: (temErro || !state.leituraCompleta)
                ? null
                : () => _confirmarFechamento(
                      context,
                      notifier,
                      temAlerta,
                      state.auditoria?.diferencaMetros ?? 0,
                    ),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Fechar Mês e Gerar PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
          if (temErro)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Corrija os erros de auditoria para fechar.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmarFechamento(BuildContext context, FechamentoMensalNotifier notifier, bool temAlerta, int diferenca) {
    if (temAlerta) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmar Fechamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Há uma diferença de $diferenca m³ na auditoria.'),
              const SizedBox(height: 8),
              const Text(
                'Isso pode indicar um vazamento ou uso de quiosque não registrado. Deseja fechar o mês mesmo assim?',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                notifier.fecharMes();
              },
              child: const Text('Sim, Fechar'),
            ),
          ],
        ),
      );
    } else {
      notifier.fecharMes();
    }
  }

  void _exibirDialogoSucesso(BuildContext context, ResultadoPdf? pdf) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 64, color: Colors.green),
        title: const Text('Mês Fechado!'),
        content: const Text(
          'Os cálculos foram concluídos e o PDF foi gerado com sucesso.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (pdf != null) ...[
                FilledButton.icon(
                  onPressed: () => Printing.layoutPdf(
                    onLayout: (_) => Uint8List.fromList(pdf.pdfBytes),
                    name: 'Relatorio_Ilheus',
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Visualizar e Imprimir'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Printing.sharePdf(
                    bytes: Uint8List.fromList(pdf.pdfBytes),
                    filename: 'ilheus_relatorio.pdf',
                  ),
                  icon: const Icon(Icons.share),
                  label: const Text('Compartilhar PDF'),
                ),
              ],
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fecha dialog
                  context.go('/home'); // Volta para home
                },
                child: const Text('Voltar para o Início'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBloco1ResumoContas(FechamentoMensalState state) {
    final corsan = state.contaCorsan;
    final luz = state.contaLuz;
    final config = state.configuracao;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resumo das Contas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            if (corsan != null) ...[
              _buildRow('Consumo CORSAN', '${corsan.consumoM3} m³'),
              _buildRow('Valor Água', 'R\$ ${_formatarCentavos(corsan.valorAgua.centavos)}'),
              _buildRow('Valor Esgoto', 'R\$ ${_formatarCentavos(corsan.valorEsgoto.centavos)}'),
              _buildRow('Serviço Básico', 'R\$ ${_formatarCentavos(corsan.valorServicoBasico.centavos)}'),
              if (corsan.valorJuros != null && corsan.valorJuros!.centavos > 0)
                _buildRow('Juros CORSAN', 'R\$ ${_formatarCentavos(corsan.valorJuros!.centavos)}'),
            ],
            const SizedBox(height: 8),
            if (luz != null)
              _buildRow('Conta Luz Total', 'R\$ ${_formatarCentavos(luz.valorTotal.centavos)}'),
            if (config != null)
              _buildRow('Condomínio (Fixo)', 'R\$ ${_formatarCentavos(config.valorCond.centavos)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildBloco2StatusLeituras(FechamentoMensalState state) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Status das Leituras', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (state.leituraCompleta)
                  const Text('22/22 ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                else
                  Text('${state.leituras.length}/22 ⚠️', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            SizedBox(
              height: 250, 
              child: ListView.builder(
                itemCount: state.leituras.length,
                itemBuilder: (context, index) {
                  final leitura = state.leituras[index];
                  final casa = state.casas.firstWhere(
                    (c) => c.id == leitura.casaId,
                    orElse: () => Casa(id: leitura.casaId, numero: 0),
                  );
                  final casaNumero = casa.numero.toString().padLeft(2, '0');
                  
                  // Busca cobrança correspondente
                  final cobranca = state.cobrancas.firstWhere(
                    (c) => c.casaId == casa.id,
                    orElse: () => Cobranca(
                      id: '', 
                      faturaId: '', 
                      casaId: casa.id, 
                      valorTotal: 0
                    ),
                  );
                  
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Text('Casa $casaNumero', style: const TextStyle(fontWeight: FontWeight.w500)),
                        if (casa.isento)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(Icons.star_outline, size: 14, color: Colors.amber.shade700),
                          ),
                        const Spacer(),
                        Text('${leitura.consumoM3} m³', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                        const SizedBox(width: 12),
                        Text(
                          'R\$ ${_formatarCentavos(cobranca.valorTotal)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                      ],
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

  Widget _buildBloco3AuditoriaPrevia(FechamentoMensalState state) {
    final auditoria = state.auditoria;
    if (auditoria == null) return const SizedBox.shrink();

    Color statusColor = Colors.green;
    IconData statusIcon = Icons.check_circle;
    String statusText = 'OK';

    if (auditoria.temErro) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'ERRO';
    } else if (auditoria.temAlerta) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'ALERTA';
    }

    return Card(
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: statusColor, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text('Auditoria Prévia: $statusText', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: statusColor)),
              ],
            ),
            const Divider(),
            _buildRow('Hidrômetro Geral', '${auditoria.consumoGeralCorsan} m³'),
            _buildRow('Soma das Casas', '${auditoria.somaMetrosCasas} m³'),
            _buildRow('Diferença', '${auditoria.diferencaMetros} m³', isBold: true),
            if (auditoria.temErro)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Diferença negativa não permitida! Verifique as leituras.', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ),
            if (auditoria.temAlerta)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text('Diferença detectada. Pode ser quiosque ou vazamento.', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  String _formatarCentavos(int centavos) {
    return (centavos / 100).toStringAsFixed(2).replaceAll('.', ',');
  }

  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
