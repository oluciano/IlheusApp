import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';

/// Serviço responsável por gerar o PDF mensal do condomínio.
///
/// Substitui o panfleto manuscrito — contém resumo das contas,
/// tabela de todas as casas e auditoria de fechamento.
class PdfService {
  /// Formata centavos em string monetária brasileira: R$ XX,XX
  static String _formatarMoeda(int centavos) {
    final reais = centavos ~/ 100;
    final cents = centavos.abs() % 100;
    return 'R\$ ${reais.toString().padLeft(2, '0')},${cents.toString().padLeft(2, '0')}';
  }

  /// Extrai mês legível do formato YYYY-MM ou MM/YYYY
  static String _formatarMesAno(String mesAno) {
    // Suporta ambos formatos: '2026-04' ou '04/2026'
    if (mesAno.contains('-')) {
      final partes = mesAno.split('-');
      final ano = partes[0];
      final mes = partes[1];
      return '${_nomeMes(int.parse(mes))}/$ano';
    } else if (mesAno.contains('/')) {
      final partes = mesAno.split('/');
      final mes = int.parse(partes[0]);
      final ano = partes[1];
      return '${_nomeMes(mes)}/$ano';
    }
    return mesAno;
  }

  static String _nomeMes(int mes) {
    const nomes = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    if (mes < 1 || mes > 12) return '??';
    return nomes[mes - 1];
  }

  /// Calcula o dia 10 do mês seguinte como string de vencimento
  static String _vencimentoMensal(String mesAno) {
    int mes;
    int ano;
    if (mesAno.contains('-')) {
      final partes = mesAno.split('-');
      ano = int.parse(partes[0]);
      mes = int.parse(partes[1]);
    } else {
      final partes = mesAno.split('/');
      mes = int.parse(partes[0]);
      ano = int.parse(partes[1]);
    }
    if (mes == 12) {
      mes = 1;
      ano++;
    } else {
      mes++;
    }
    return '10/${mes.toString().padLeft(2, '0')}/$ano';
  }

  /// Gera o PDF mensal completo.
  ///
  /// Parâmetros:
  /// - [mesAno]: Mês de referência (ex: '2026-04' ou '04/2026')
  /// - [contaCorsan]: Conta CORSAN do mês
  /// - [contaLuz]: Conta de luz do mês
  /// - [valorCond]: Valor do condomínio em centavos
  /// - [casas]: Lista de casas (para verificar isenções)
  /// - [leituras]: Leituras de cada casa
  /// - [cobrancas]: Cobranças calculadas de cada casa
  /// - [auditoria]: Resultado da auditoria de fechamento
  /// - [mostrarAuditoria]: Se true, exibe seção de auditoria no PDF (default true)
  ///
  /// Retorna: Bytes do PDF pronto para salvar ou exibir.
  static Future<List<int>> gerarPdf({
    required String mesAno,
    required ContaCorsan contaCorsan,
    required ContaLuz contaLuz,
    required int valorCond,
    required List<Casa> casas,
    required List<Leitura> leituras,
    required List<Cobranca> cobrancas,
    required AuditoriaFatura auditoria,
    bool mostrarAuditoria = true,
  }) async {
    final pdf = pw.Document();

    // Ordena leituras e cobrancas por casa (número)
    final casaPorId = {for (final c in casas) c.id: c};
    final leiturasOrdenadas = List<Leitura>.from(leituras)
      ..sort((a, b) {
        final ca = casaPorId[a.casaId];
        final cb = casaPorId[b.casaId];
        return (ca?.numero ?? 99).compareTo(cb?.numero ?? 99);
      });
    final cobrancasOrdenadas = List<Cobranca>.from(cobrancas)
      ..sort((a, b) {
        final ca = casaPorId[a.casaId];
        final cb = casaPorId[b.casaId];
        return (ca?.numero ?? 99).compareTo(cb?.numero ?? 99);
      });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.only(top: 15, bottom: 10, left: 12, right: 12),
        header: (context) => _cabecalho(mesAno),
        footer: (context) => _rodape(),
        build: (context) => [
          _blocoContas(contaCorsan, contaLuz, valorCond),
          pw.SizedBox(height: 6),
          _tabelaCasas(
            casas,
            leiturasOrdenadas,
            cobrancasOrdenadas,
            casaPorId,
          ),
          pw.SizedBox(height: 6),
          _blocoDebitosAnteriores(cobrancas),
          if (mostrarAuditoria) ...[
            pw.SizedBox(height: 6),
            _blocoAuditoria(auditoria),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _cabecalho(String mesAno) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Condomínio Residencial Ilheus',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Fatura Mensal — ${_formatarMesAno(mesAno)}',
                style: const pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
          pw.Text(
            'Vencimento: ${_vencimentoMensal(mesAno)}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _rodape() {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Text(
        'Gerado por Ilheus App — ${DateTime.now().toString().substring(0, 16)}',
        style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey),
      ),
    );
  }

  static pw.Widget _blocoContas(
    ContaCorsan contaCorsan,
    ContaLuz contaLuz,
    int valorCond,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RESUMO DAS CONTAS',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: _tabelaCorsan(contaCorsan),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: _tabelaLuz(contaLuz, valorCond),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _tabelaCorsan(ContaCorsan contaCorsan) {
    final totalCorsan = contaCorsan.valorAgua.centavos +
        contaCorsan.valorEsgoto.centavos +
        contaCorsan.valorServicoBasico.centavos +
        (contaCorsan.valorJuros?.centavos ?? 0);

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        _linhaTabela(
          'CONTA CORSAN',
          '',
          header: true,
        ),
        _linhaTabela(
          'Leitura anterior',
          '${contaCorsan.leituraAnteriorM3} m³',
        ),
        _linhaTabela(
          'Leitura atual',
          '${contaCorsan.leituraAtualM3} m³',
        ),
        _linhaTabela(
          'Consumo',
          '${contaCorsan.consumoM3} m³',
        ),
        _linhaTabela(
          'Água',
          _formatarMoeda(contaCorsan.valorAgua.centavos),
        ),
        _linhaTabela(
          'Esgoto',
          _formatarMoeda(contaCorsan.valorEsgoto.centavos),
        ),
        _linhaTabela(
          'Serviço Básico',
          _formatarMoeda(contaCorsan.valorServicoBasico.centavos),
        ),
        if (contaCorsan.valorJuros != null &&
            contaCorsan.valorJuros!.centavos > 0)
          _linhaTabela(
            'Juros CORSAN',
            _formatarMoeda(contaCorsan.valorJuros!.centavos),
          ),
        _linhaTabela(
          'Total CORSAN',
          _formatarMoeda(totalCorsan),
          bold: true,
        ),
      ],
    );
  }

  static pw.Widget _tabelaLuz(ContaLuz contaLuz, int valorCond) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1),
      },
      children: [
        _linhaTabela('CONTA LUZ', '', header: true),
        _linhaTabela(
          'Valor Total',
          _formatarMoeda(contaLuz.valorTotal.centavos),
        ),
        if (contaLuz.valorJuros != null && contaLuz.valorJuros!.centavos > 0)
          _linhaTabela(
            'Juros Luz',
            _formatarMoeda(contaLuz.valorJuros!.centavos),
          ),
        _linhaTabela(
          'Condomínio',
          _formatarMoeda(valorCond),
        ),
      ],
    );
  }

  static pw.TableRow _linhaTabela(
    String label,
    String valor, {
    bool header = false,
    bool bold = false,
  }) {
    final style = pw.TextStyle(
      fontSize: 9,
      fontWeight: header || bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.TableRow(
      decoration: header
          ? pw.BoxDecoration(color: PdfColors.grey200)
          : null,
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(label, style: style),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(3),
          child: pw.Text(
            valor,
            style: style,
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _tabelaCasas(
    List<Casa> casas,
    List<Leitura> leituras,
    List<Cobranca> cobrancas,
    Map<String, Casa> casaPorId,
  ) {
    final leiturasPorCasa = {for (final l in leituras) l.casaId: l};
    final cobrancasPorCasa = {for (final c in cobrancas) c.casaId: c};

    // Filtra casas ativas ordenadas por número
    final casasOrdenadas = List<Casa>.from(casas)
      ..where((c) => c.ativa)
      ..sort((a, b) => a.numero.compareTo(b.numero));

    int totalAgua = 0;
    int totalEsgoto = 0;
    int totalLuz = 0;
    int totalServBasico = 0;
    int totalCond = 0;
    int totalJuros = 0;
    int totalGeral = 0;

    final linhas = <pw.TableRow>[];

    // Cabeçalho da tabela
    linhas.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey300),
        children: [
          _celula('Casa', bold: true),
          _celula('Ant.', bold: true),
          _celula('Atual', bold: true),
          _celula('m³', bold: true),
          _celula('Água', bold: true),
          _celula('Esgoto', bold: true),
          _celula('Luz', bold: true),
          _celula('Serv.Bás.', bold: true),
          _celula('Cond', bold: true),
          _celula('Juros', bold: true),
          _celula('Total', bold: true),
        ],
      ),
    );

    for (final casa in casasOrdenadas) {
      if (casa.isQuiosque) continue; // quiocosque não é casa residencial

      final leitura = leiturasPorCasa[casa.id];
      final cobranca = cobrancasPorCasa[casa.id];

      if (leitura == null || cobranca == null) continue;

      totalAgua += cobranca.valorAgua;
      totalEsgoto += cobranca.valorEsgoto;
      totalLuz += cobranca.valorLuz;
      totalServBasico += cobranca.valorServicoBasico;
      totalCond += cobranca.valorCond;
      totalJuros += cobranca.valorJuros;
      totalGeral += cobranca.valorTotal;

      // Marca isenções com * (isento = zera água, esgoto, luz, serv. básico)
      // Condomínio sempre aparece com valor (isento ou não)
      final aguaStr = casa.isento
          ? '*'
          : _formatarMoeda(cobranca.valorAgua);
      final esgotoStr = casa.isento
          ? '*'
          : _formatarMoeda(cobranca.valorEsgoto);
      final luzStr = casa.isento ? '*' : _formatarMoeda(cobranca.valorLuz);
      final servBasicoStr = casa.isento
          ? '*'
          : _formatarMoeda(cobranca.valorServicoBasico);
      // Condomínio: nunca mostra * — sempre o valor
      final condStr = _formatarMoeda(cobranca.valorCond);

      linhas.add(
        pw.TableRow(
          children: [
            _celula(casa.numero.toString().padLeft(2, '0')),
            _celula('${leitura.leituraAnteriorM3}'),
            _celula('${leitura.leituraAtualM3}'),
            _celula('${leitura.consumoM3}'),
            _celula(aguaStr),
            _celula(esgotoStr),
            _celula(luzStr),
            _celula(servBasicoStr),
            _celula(condStr),
            _celula(_formatarMoeda(cobranca.valorJuros)),
            _celula(
              _formatarMoeda(cobranca.valorTotal),
              bold: true,
            ),
          ],
        ),
      );
    }

    // Linha de totais
    linhas.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          _celula('TOTAL', bold: true),
          _celula(''),
          _celula(''),
          _celula(''),
          _celula(_formatarMoeda(totalAgua), bold: true),
          _celula(_formatarMoeda(totalEsgoto), bold: true),
          _celula(_formatarMoeda(totalLuz), bold: true),
          _celula(_formatarMoeda(totalServBasico), bold: true),
          _celula(_formatarMoeda(totalCond), bold: true),
          _celula(_formatarMoeda(totalJuros), bold: true),
          _celula(_formatarMoeda(totalGeral), bold: true),
        ],
      ),
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RATEIO POR CASA',
          style: pw.TextStyle(
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          '* = isento (paga somente condomínio)',
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey),
        ),
        pw.SizedBox(height: 4),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          columnWidths: const {
            0: pw.FixedColumnWidth(28),
            1: pw.FixedColumnWidth(26),
            2: pw.FixedColumnWidth(26),
            3: pw.FixedColumnWidth(24),
            4: pw.FixedColumnWidth(48),
            5: pw.FixedColumnWidth(48),
            6: pw.FixedColumnWidth(44),
            7: pw.FixedColumnWidth(50),
            8: pw.FixedColumnWidth(44),
            9: pw.FixedColumnWidth(44),
            10: pw.FixedColumnWidth(52),
          },
          children: linhas,
        ),
      ],
    );
  }

  static pw.Widget _celula(
    String text, {
    bool bold = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _celulaValor(
    String text, {
    required pw.TextStyle style,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(2),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: style,
      ),
    );
  }

  static pw.Widget _blocoDebitosAnteriores(List<Cobranca> cobrancas) {
    final debitosPorMes = <String, int>{};
    for (final cobranca in cobrancas) {
      if (cobranca.valorDebitos > 0) {
        debitosPorMes.update(
          'Mês anterior',
          (v) => v + cobranca.valorDebitos,
          ifAbsent: () => cobranca.valorDebitos,
        );
      }
    }

    final totalDebitos = debitosPorMes.values.fold<int>(0, (s, v) => s + v);
    if (totalDebitos == 0) return pw.SizedBox.shrink();

    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.red200, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
        color: PdfColors.red50,
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Débitos anteriores em aberto:',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.red700,
            ),
          ),
          pw.Text(
            'Total: ${_formatarMoeda(totalDebitos)}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _blocoAuditoria(AuditoriaFatura auditoria) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'AUDITORIA',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 1),
          pw.Text(
            'CORSAN: ${auditoria.consumoGeralCorsan} m³ | Casas: ${auditoria.somaMetrosCasas} m³ | Dif: ${auditoria.diferencaMetros} m³',
            style: const pw.TextStyle(fontSize: 7),
          ),
          if (auditoria.diferencaMetros > 0 && auditoria.mensagem != null) ...[
            pw.SizedBox(height: 1),
            pw.Text(
              'ALERTA: ${auditoria.mensagem}',
              style: pw.TextStyle(
                fontSize: 7,
                color: PdfColors.orange700,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
          pw.SizedBox(height: 1),
          pw.Text(
            'Total cobrado: ${_formatarMoeda(auditoria.totalCobrado)}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
