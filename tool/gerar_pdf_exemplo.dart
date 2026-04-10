// ignore_for_file: avoid_print

import 'dart:io';

import 'package:ilheus_app/features/agua/data/services/pdf_service.dart';
import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/configuracao_mes.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';

/// PDF realista — Abril/2026
///
/// Regra de ouro: CORSAN >= soma das casas (ninguém gera água do nada)
///
/// Cenário:
///   CORSAN: 128 m³ (hidrômetro geral)
///   Casas:  110 m³ (soma dos 22 consumos individuais)
///   Diferença: 18 m³ → quiosque (3 casas usaram) + perda natural
///
/// Uso: dart tool/gerar_pdf_exemplo.dart

void main() async {
  const mesAno = '2026-04';

  // ============================================================
  // CONTA CORSAN — hidrômetro GERAL do condomínio
  // ============================================================
  // Leitura anterior: 5420 m³
  // Leitura atual:    5548 m³
  // Consumo geral:    128 m³  ← isto é o que passou pelo hidrômetro GERAL
  final contaCorsan = const ContaCorsan(
    mesAno: mesAno,
    leituraAnteriorM3: 5420,
    leituraAtualM3: 5548,
    valorAgua: ValorMonetario(19200),       // R$ 192,00
    valorEsgoto: ValorMonetario(14520),     // R$ 145,20
    valorServicoBasico: ValorMonetario(10120), // R$ 101,20
    valorJuros: ValorMonetario(440),        // R$ 4,40
    vencimento: null,
  );

  // Conta Luz — iluminação comum
  final contaLuz = const ContaLuz(
    mesAno: mesAno,
    valorTotal: ValorMonetario(1320),       // R$ 13,20
    valorJuros: null,
  );

  const valorCond = 1500; // R$ 15,00 — assembleia

  // ============================================================
  // CASAS — 22 residenciais + 1 quiiosque
  // Casa 08: isenta (leiturista — paga só condomínio)
  // Casa 02: administradora
  // ============================================================
  final casas = <Casa>[
    for (var i = 1; i <= 22; i++)
      Casa(
        id: 'casa-$i',
        numero: i,
        ativa: true,
        isento: i == 8,
        ehAdministrador: i == 2,
      ),
    Casa(id: 'casa-23', numero: 23, ativa: true),
  ];

  // ============================================================
  // LEITURAS individuais — soma DOS CONSUMOS = 110 m³
  // ============================================================
  // Cada casa tem seu próprio par anterior/atual.
  // O consumo individual é (atual - anterior).
  // A soma de TODOS os consumos = 110 m³.
  // Isso é MENOR que o CORSAN (128 m³) → 18 m³ de diferença = quiosque + perda.
  final consumos = [
    5,  // casa 1
    6,  // casa 2
    8,  // casa 3 (usou quiosque)
    4,  // casa 4
    5,  // casa 5
    4,  // casa 6
    7,  // casa 7 (usou quiosque)
    4,  // casa 8 (isenta — leitura existe, mas não cobra)
    5,  // casa 9
    3,  // casa 10
    5,  // casa 11
    4,  // casa 12
    6,  // casa 13
    4,  // casa 14
    7,  // casa 15 (usou quiosque)
    3,  // casa 16
    5,  // casa 17
    3,  // casa 18
    4,  // casa 19
    6,  // casa 20
    3,  // casa 21
    6,  // casa 22
  ];
  // Soma = 5+6+8+4+5+4+7+4+5+3+5+4+6+4+7+3+5+3+4+6+3+6 = 110 ✓
  // CORSAN = 128 → diferença = 18 m³ (quiosque + perda) ✓

  // Para cada casa, gera uma leitura com base em um hidrômetro individual simulado.
  final leituras = <Leitura>[];
  int hidrometroIndividual = 1000; // simula hidrômetro de cada casa
  for (var i = 0; i < 22; i++) {
    final consumo = consumos[i];
    final anterior = hidrometroIndividual;
    final atual = hidrometroIndividual + consumo;
    leituras.add(Leitura(
      id: 'leitura-${i + 1}',
      casaId: 'casa-${i + 1}',
      mesAno: mesAno,
      leituraAnteriorM3: anterior,
      leituraAtualM3: atual,
    ));
    hidrometroIndividual += 50; // cada casa tem hidrômetro diferente
  }

  // ============================================================
  // CÁLCULO DE RATEIO — igual ao CalcularCobrancaCasaUseCase
  // ============================================================
  final consumoGeralCorsan = contaCorsan.consumoM3; // 128 m³

  final cobrancas = <Cobranca>[];

  for (var i = 0; i < 22; i++) {
    final casaNum = i + 1;
    final consumoCasa = consumos[i];
    final isento = casaNum == 8;

    // Água: (consumo_casa / consumo_geral_corsan) × valor_agua
    // Fórmula oficial do foundation: proporcional ao consumo CORSAN
    final valorAgua = (!isento && consumoGeralCorsan > 0)
        ? ((consumoCasa * contaCorsan.valorAgua.centavos) / consumoGeralCorsan).floor()
        : 0;

    // Esgoto: igualitário ÷ 22
    final valorEsgoto = !isento
        ? (contaCorsan.valorEsgoto.centavos / 22).floor()
        : 0;

    // Serviço Básico: igualitário ÷ 22
    final valorServicoBasico = !isento
        ? (contaCorsan.valorServicoBasico.centavos / 22).floor()
        : 0;

    // Luz: igualitário ÷ 22
    final valorLuz = !isento
        ? (contaLuz.valorTotal.centavos / 22).floor()
        : 0;

    // Condomínio: TODOS pagam (isento ou não)
    final valorCondCalc = valorCond;

    // Juros: 4 inadimplentes (casas 4, 9, 13, 19) → R$ 4,40 ÷ 4 = R$ 1,10 cada
    final casasInadimplentes = [4, 9, 13, 19];
    final valorJuros = casasInadimplentes.contains(casaNum) ? 110 : 0;

    // Débitos: casa 11 não pagou mês anterior
    final valorDebitos = casaNum == 11 ? 14755 : 0;

    // Quiosque: casas 3, 7, 15 usaram → cota = (valor_agua / 23) ÷ 3
    final casasQuiosque = [3, 7, 15];
    final valorQuiosque = casasQuiosque.contains(casaNum) && !isento
        ? ((contaCorsan.valorAgua.centavos / 23).floor() / 3).floor()
        : 0;

    // Total = componentes do mês (débito NUNCA entra — aparece como alerta separado)
    final total = valorAgua + valorEsgoto + valorServicoBasico +
        valorLuz + valorCondCalc + valorJuros + valorQuiosque;

    cobrancas.add(Cobranca(
      id: 'cobranca-$casaNum',
      faturaId: 'fatura-$mesAno',
      casaId: 'casa-$casaNum',
      valorAgua: valorAgua,
      valorEsgoto: valorEsgoto,
      valorServicoBasico: valorServicoBasico,
      valorLuz: valorLuz,
      valorCond: valorCondCalc,
      valorQuiosque: valorQuiosque,
      valorJuros: valorJuros,
      valorDebitos: valorDebitos,
      valorTotal: total,
      status: casaNum == 11 ? StatusCobranca.inadimplente : StatusCobranca.pendente,
    ));
  }

  // ============================================================
  // VALIDAÇÃO — imprimir relatório
  // ============================================================
  final somaAgua = cobrancas.fold<int>(0, (s, c) => s + c.valorAgua);
  final somaEsgoto = cobrancas.fold<int>(0, (s, c) => s + c.valorEsgoto);
  final somaSB = cobrancas.fold<int>(0, (s, c) => s + c.valorServicoBasico);
  final somaLuz = cobrancas.fold<int>(0, (s, c) => s + c.valorLuz);
  final somaQuiosque = cobrancas.fold<int>(0, (s, c) => s + c.valorQuiosque);
  final somaJuros = cobrancas.fold<int>(0, (s, c) => s + c.valorJuros);
  final somaDebitos = cobrancas.fold<int>(0, (s, c) => s + c.valorDebitos);
  final somaCond = cobrancas.fold<int>(0, (s, c) => s + c.valorCond);
  final totalGeral = cobrancas.fold<int>(0, (s, c) => s + c.valorTotal);
  final somaMetros = leituras.fold<int>(0, (s, l) => s + l.consumoM3);
  final diferencaMetros = consumoGeralCorsan - somaMetros;

  print('');
  print('╔═══════════════════════════════════════════════════════╗');
  print('║         VALIDAÇÃO DE RATEIO — ABRIL/2026              ║');
  print('╠═══════════════════════════════════════════════════════╣');
  print('║                                                       ║');
  print('║  ÁGUA                                                 ║');
  print('║    CORSAN:       R\$ ${_fmt(contaCorsan.valorAgua.centavos).padLeft(8)}                    ║');
  print('║    Soma casas:   R\$ ${_fmt(somaAgua).padLeft(8)}  (21 casas, 1 isenta)    ║');
  print('║    Quiosque:     R\$ ${_fmt(somaQuiosque).padLeft(8)}  (3 casas usaram)       ║');
  print('║    RESTANTE:     R\$ ${_fmt(contaCorsan.valorAgua.centavos - somaAgua - somaQuiosque).padLeft(8)}  (perda floor + isenta)  ║');
  print('║                                                       ║');
  print('║  ESGOTO                                               ║');
  print('║    CORSAN:       R\$ ${_fmt(contaCorsan.valorEsgoto.centavos).padLeft(8)}                    ║');
  print('║    Soma casas:   R\$ ${_fmt(somaEsgoto).padLeft(8)}  (21 casas)              ║');
  print('║    RESTANTE:     R\$ ${_fmt(contaCorsan.valorEsgoto.centavos - somaEsgoto).padLeft(8)}  (isenta + floor)        ║');
  print('║                                                       ║');
  print('║  SERVIÇO BÁSICO                                       ║');
  print('║    CORSAN:       R\$ ${_fmt(contaCorsan.valorServicoBasico.centavos).padLeft(8)}                    ║');
  print('║    Soma casas:   R\$ ${_fmt(somaSB).padLeft(8)}  (21 casas)              ║');
  print('║    RESTANTE:     R\$ ${_fmt(contaCorsan.valorServicoBasico.centavos - somaSB).padLeft(8)}  (isenta + floor)        ║');
  print('║                                                       ║');
  print('║  LUZ                                                  ║');
  print('║    Total:        R\$ ${_fmt(contaLuz.valorTotal.centavos).padLeft(8)}                     ║');
  print('║    Soma casas:   R\$ ${_fmt(somaLuz).padLeft(8)}  (21 casas)              ║');
  print('║                                                       ║');
  print('║  FIXOS                                                ║');
  print('║    Condomínio:   R\$ ${_fmt(somaCond).padLeft(8)}  (22 casas)              ║');
  final qtdJuros = cobrancas.where((c) => c.valorJuros > 0).length;
  
  print('║    Juros:        R\$ ${_fmt(somaJuros).padLeft(8)}  ($qtdJuros casas)               ║');
  print('║    Débitos:      R\$ ${_fmt(somaDebitos).padLeft(8)}  (1 casa)                ║');
  print('║                                                       ║');
  print('╠═══════════════════════════════════════════════════════╣');
  print('║  TOTAL GERAL COBRADO:  R\$ ${_fmt(totalGeral).padLeft(8)}               ║');
  print('╠═══════════════════════════════════════════════════════╣');
  print('║                                                       ║');
  print('║  AUDITORIA DE METROS                                  ║');
  print('║    Hidrômetro CORSAN:  ${consumoGeralCorsan} m³                       ║');
  print('║    Soma 22 casas:      ${somaMetros} m³                       ║');
  print('║    Diferença:          ${diferencaMetros} m³  (quiosque + perda)   ║');
  print('║    Status:             ${diferencaMetros > 0 ? '✅ ALERTA (OK)' : diferencaMetros == 0 ? '✅ OK' : '❌ ERRO'}                     ║');
  print('║                                                       ║');
  print('╚═══════════════════════════════════════════════════════╝');
  print('');

  // ============================================================
  // AUDITORIA
  // ============================================================
  final auditoria = AuditoriaFatura(
    faturaId: 'fatura-$mesAno',
    somaMetrosCasas: somaMetros,
    consumoGeralCorsan: consumoGeralCorsan,
    diferencaMetros: diferencaMetros,
    somaEsgotoCasas: somaEsgoto,
    valorEsgotoCorsan: contaCorsan.valorEsgoto.centavos,
    somaLuzCasas: somaLuz,
    valorLuzCorsan: contaLuz.valorTotal.centavos,
    totalCobrado: totalGeral,
    status: diferencaMetros > 0 ? StatusAuditoria.alerta : StatusAuditoria.ok,
    mensagem: diferencaMetros > 0
        ? 'Diferença de $diferencaMetros m³ — verificar quiosque/vazamento'
        : null,
  );

  // ============================================================
  // GERAR PDF
  // ============================================================
  final config = ConfiguracaoMes(
    mesAno: mesAno,
    valorCond: ValorMonetario(valorCond),
  );

  final pdfBytes = await PdfService.gerarPdf(
    mesAno: mesAno,
    contaCorsan: contaCorsan,
    contaLuz: contaLuz,
    valorCond: config.valorCond.centavos,
    casas: casas,
    leituras: leituras,
    cobrancas: cobrancas,
    auditoria: auditoria,
  );

  final home = Platform.environment['HOME'] ?? '/tmp';
  final dir = Directory('$home/Downloads');
  if (!await dir.exists()) await dir.create(recursive: true);

  final arquivo = File('${dir.path}/ilheus_${mesAno.replaceAll('-', '_')}.pdf');
  await arquivo.writeAsBytes(pdfBytes);

  print('✅ PDF salvo em: ${arquivo.path}');
  print('📄 Tamanho: ${(pdfBytes.length / 1024).toStringAsFixed(1)} KB');
  print('');

  // Detalhe por casa
  print('');
  print('╔════╦═══════╦═══════╦═══════╦═══════╦═══════╦═══════╦═══════╦════════╦════════╗');
  print('║Casa║  Água ║ Esgoto║ S.Bás ║  Luz  ║  Cond ║ Quiosq║ Juros ║  Total ║ Débito ║');
  print('╠════╬═══════╬═══════╬═══════╬═══════╬═══════╬═══════╬═══════╬════════╬════════╣');
  for (final c in cobrancas) {
    final num = int.parse(c.casaId.split('-')[1]);
    final casa = casas.firstWhere((h) => h.id == c.casaId);
    final marker = casa.isento ? ' *' : casa.ehAdministrador ? ' A' : '  ';
    print('║${num.toString().padLeft(3)}$marker║ ${_fmt(c.valorAgua).padLeft(6)} ║ ${_fmt(c.valorEsgoto).padLeft(6)} ║ ${_fmt(c.valorServicoBasico).padLeft(6)} ║ ${_fmt(c.valorLuz).padLeft(6)} ║ ${_fmt(c.valorCond).padLeft(6)} ║ ${_fmt(c.valorQuiosque).padLeft(6)} ║ ${_fmt(c.valorJuros).padLeft(6)} ║ ${_fmt(c.valorTotal).padLeft(7)} ║ ${_fmt(c.valorDebitos).padLeft(7)} ║');
  }
  print('╚════╩═══════╩═══════╩═══════╩═══════╩═══════╩═══════╩═══════╩════════╩════════╝');
  print('  * = isento  |  A = administrador  |  Débito = alerta separado (NÃO soma no total)');
  print('');
}

String _fmt(int centavos) {
  final reais = centavos ~/ 100;
  final cents = centavos.abs() % 100;
  return '$reais,${cents.toString().padLeft(2, '0')}';
}
