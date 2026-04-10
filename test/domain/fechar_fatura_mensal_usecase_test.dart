import 'package:flutter_test/flutter_test.dart';
import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';
import 'package:ilheus_app/features/agua/domain/usecases/fechar_fatura_mensal_usecase.dart';

void main() {
  group('FecharFaturaMensalUseCase', () {
    late FecharFaturaMensalUseCase useCase;

    setUp(() {
      useCase = FecharFaturaMensalUseCase();
    });

    /// Helper: Cria lista com 22 cobranças dummy (uma por casa)
    List<Cobranca> _criar22Cobrancas({
      int valorAguaPorCasa = 6800,
      int valorEsgotoPorCasa = 5200,
      int valorServicoBasicoPorCasa = 3700,
      int valorLuzPorCasa = 454,
      int valorCondPorCasa = 1500,
    }) {
      final cobrancas = <Cobranca>[];
      for (int i = 1; i <= 22; i++) {
        final total = valorAguaPorCasa +
            valorEsgotoPorCasa +
            valorServicoBasicoPorCasa +
            valorLuzPorCasa +
            valorCondPorCasa;

        cobrancas.add(
          Cobranca(
            id: 'cobranca-$i',
            faturaId: 'fatura-1',
            casaId: 'casa-$i',
            valorAgua: valorAguaPorCasa,
            valorEsgoto: valorEsgotoPorCasa,
            valorServicoBasico: valorServicoBasicoPorCasa,
            valorLuz: valorLuzPorCasa,
            valorCond: valorCondPorCasa,
            valorTotal: total,
          ),
        );
      }
      return cobrancas;
    }

    /// Helper: Cria leituras para 22 casas (10 m³ cada = 220 m³ total)
    List<Leitura> _criar22Leituras() {
      final leituras = <Leitura>[];
      for (int i = 1; i <= 22; i++) {
        leituras.add(
          Leitura(
            id: 'leitura-$i',
            mesAno: '2026-04',
            casaId: 'casa-$i',
            leituraAnteriorM3: 100,
            leituraAtualM3: 110, // 10 m³ cada
          ),
        );
      }
      return leituras;
    }

    /// Cenário: Fechamento com metros batendo ✅
    test('Fechamento com metros batendo (status OK)', () {
      final cobrancas = _criar22Cobrancas(
        valorAguaPorCasa: 6800,
        valorEsgotoPorCasa: 5200,
        valorServicoBasicoPorCasa: 3700,
        valorLuzPorCasa: 454,
        valorCondPorCasa: 1500,
      );

      final somaEsgoto = 5200 * 22; // 114.400 centavos
      final somaLuz = 454 * 22; // 9.988 centavos

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(somaEsgoto),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(somaLuz),
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      final leituras = _criar22Leituras();

      final resultado = useCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: leituras,
      );

      expect(resultado.auditoria.status, StatusAuditoria.ok);
      expect(resultado.fatura.status, StatusFatura.publicado);
      expect(resultado.auditoria.mensagem, isNull);
    });

    /// Cenário: Fechamento com diferença positiva de metros → alerta ⚠️
    test('Fechamento com diferença de metros (status ALERTA)', () {
      final cobrancas = _criar22Cobrancas();
      final leituras = _criar22Leituras(); // 220 m³ total

      // CORSAN reportou 250 m³, mas casas somam apenas 220 m³
      // Diferença = 30 m³ (quiosque/vazamento)
      final somaEsgoto = 5200 * 22; // 114.400 centavos
      final somaLuz = 454 * 22; // 9.988 centavos

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 250, // ← CORSAN lê 250 m³
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(somaEsgoto),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(somaLuz),
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      final resultado = useCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: leituras,
      );

      expect(resultado.auditoria.status, StatusAuditoria.alerta);
      expect(resultado.auditoria.diferencaMetros, 30); // 250 - 220
      expect(resultado.auditoria.mensagem, contains('30 m³'));
      // ALERTA permite publicar (com confirmação do admin)
      expect(resultado.fatura.status, StatusFatura.publicado);
    });

    /// Cenário: Fechamento com casa faltando → erro ❌
    test('Fechamento com casa faltando (status ERRO)', () {
      // Apenas 21 casas (falta 1)
      final cobrancas = <Cobranca>[];
      for (int i = 1; i <= 21; i++) {
        cobrancas.add(
          Cobranca(
            id: 'cobranca-$i',
            faturaId: 'fatura-1',
            casaId: 'casa-$i',
            valorAgua: 6800,
            valorEsgoto: 5200,
            valorServicoBasico: 3700,
            valorLuz: 454,
            valorCond: 1500,
            valorTotal: 17454,
          ),
        );
      }

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      expect(
        () => useCase.execute(
          cobrancas: cobrancas,
          contaCorsan: contaCorsan,
          contaLuz: contaLuz,
          faturaRascunho: faturaRascunho,
          leituras: _criar22Leituras(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    /// Cenário: Soma esgoto não bate → erro ❌
    test('Soma esgoto não bate (status ERRO)', () {
      final cobrancas = _criar22Cobrancas(
        valorEsgotoPorCasa: 5200,
      );

      final somaEsgoto = 5200 * 22; // 114.400 centavos
      final somaLuz = 454 * 22;

      // CORSAN reportou valor diferente (diferença > 1 centavo)
      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(somaEsgoto + 100), // ← Diferença de 100
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(somaLuz),
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      final resultado = useCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: _criar22Leituras(),
      );

      expect(resultado.auditoria.status, StatusAuditoria.erro);
      expect(resultado.fatura.status, StatusFatura.rascunho); // Não publica
      expect(resultado.auditoria.mensagem, contains('ERRO'));
    });

    /// Cenário: Soma luz não bate → erro ❌
    test('Soma luz não bate (status ERRO)', () {
      final cobrancas = _criar22Cobrancas(
        valorLuzPorCasa: 454,
      );

      final somaEsgoto = 5200 * 22;
      final somaLuz = 454 * 22;

      // CORSAN reportou valor diferente de luz
      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(somaEsgoto),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(somaLuz + 50), // ← Diferença de 50
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      final resultado = useCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: _criar22Leituras(),
      );

      expect(resultado.auditoria.status, StatusAuditoria.erro);
      expect(resultado.fatura.status, StatusFatura.rascunho);
    });

    /// Validação: Impossível ter soma > consumo
    test('Impossível: soma casas > consumo CORSAN (erro crítico)', () {
      final cobrancas = _criar22Cobrancas(
        valorAguaPorCasa: 10000, // Consumo impossível
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 100, // Consumo total menor que soma das casas
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      final resultado = useCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: _criar22Leituras(), // 220 m³
      );

      expect(resultado.auditoria.status, StatusAuditoria.erro);
      expect(resultado.auditoria.diferencaMetros, lessThan(0)); // 100 - 220 = -120
      expect(resultado.fatura.status, StatusFatura.rascunho);
    });

    /// Auditoria completa: Total cobrado é calculado corretamente
    test('Total cobrado é calculado e validado', () {
      final cobrancas = _criar22Cobrancas(
        valorAguaPorCasa: 6800,
        valorEsgotoPorCasa: 5200,
        valorServicoBasicoPorCasa: 3700,
        valorLuzPorCasa: 454,
        valorCondPorCasa: 1500,
      );

      final totalEsperado = (6800 + 5200 + 3700 + 454 + 1500) * 22;

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final faturaRascunho = FaturaCalculada(
        id: 'fatura-1',
        mesAno: '2026-04',
        status: StatusFatura.rascunho,
      );

      final resultado = useCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: _criar22Leituras(),
      );

      expect(resultado.auditoria.totalCobrado, totalEsperado);
    });
  });
}
