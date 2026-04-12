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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
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

      // Débito anterior de R$ 50,00 em aberto
      final debitoAberto = Debito(
        id: 'debito-1',
        cobrancaId: 'cobr-anterior',
        casaId: 'casa-9',
        mesAnoOrigem: '2026-03',
        valorCentavos: 5000,
        status: StatusDebito.aberto,
      );

      final cobranca = useCase.execute(
        casa: casa,
        leitura: leitura,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [debitoAberto],
        inadimplentesAnterior: 0,
        dataPagamento: null,
        allLeituras: [leitura],
        qtdCasasPagantes: 22,
        consumoGeralPagantes: 220,
      );

      // Débito aparece em valorDebitos, não somado no valorTotal (aparece como alerta)
      expect(cobranca.valorDebitos, 5000);
      // valorTotal não inclui débito
      expect(cobranca.valorTotal,
          cobranca.valorAgua +
              cobranca.valorEsgoto +
              cobranca.valorServicoBasico +
              cobranca.valorLuz +
              cobranca.valorCond +
              cobranca.valorJuros);
    });

    /// NOVO TESTE OBRIGATÓRIO: 22 casas, 1 isenta → denominador = 21
    /// Garante que casa isenta não afeta rateio de componentes igualitários
    test('22 casas, 1 isenta — denominador = 21 para igualitários', () {
      // Casa 22 é isenta
      final casaIsenta = Casa(
        id: 'casa-22',
        numero: 22,
        ativa: true,
        isento: true,
      );

      // Casa 1 é normal (pagante)
      final casaPagante = Casa(
        id: 'casa-1',
        numero: 1,
        ativa: true,
        isento: false,
      );

      // Leituras: casa pagante consome 10 m³, casa isenta 5 m³ (mas não paga água proporcional)
      final leituraPagante = Leitura(
        id: 'leitura-1',
        mesAno: '2026-04',
        casaId: 'casa-1',
        leituraAnteriorM3: 0,
        leituraAtualM3: 10,
      );

      final leituraIsenta = Leitura(
        id: 'leitura-22',
        mesAno: '2026-04',
        casaId: 'casa-22',
        leituraAnteriorM3: 0,
        leituraAtualM3: 5,
      );

      // Conta CORSAN: 15 m³ total (10 pagante + 5 isenta)
      // Mas rateio de água usa apenas consumo pagante: 10 m³
      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 15,
        valorAgua: ValorMonetario.fromCentavos(100000), // R$ 1.000,00
        valorEsgoto: ValorMonetario.fromCentavos(210000), // R$ 2.100,00
        valorServicoBasico: ValorMonetario.fromCentavos(84000), // R$ 840,00
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(10500), // R$ 105,00
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000), // R$ 150,00
      );

      // Casa pagante
      final cobrancaPagante = useCase.execute(
        casa: casaPagante,
        leitura: leituraPagante,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: null,
        allLeituras: [leituraPagante, leituraIsenta],
        qtdCasasPagantes: 21, // ← 22 casas - 1 isenta
        consumoGeralPagantes: 10, // ← Só consumo das casas pagantes
      );

      // Casa isenta
      final cobrancaIsenta = useCase.execute(
        casa: casaIsenta,
        leitura: leituraIsenta,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: null,
        allLeituras: [leituraPagante, leituraIsenta],
        qtdCasasPagantes: 21,
        consumoGeralPagantes: 10,
      );

      // VERIFICAÇÕES DA CASA PAGANTE

      // Água: (10 * 100000) / 10 = 100000 centavos (casa consumiu tudo dos pagantes)
      expect(cobrancaPagante.valorAgua, (10 * 100000) ~/ 10);

      // Esgoto: 210000 / 21 = 10000 centavos (dividido entre 21 pagantes, não 22)
      expect(
        cobrancaPagante.valorEsgoto,
        (210000 / 21).floor(),
      );

      // Serviço Básico: 84000 / 21 = 4000 centavos
      expect(
        cobrancaPagante.valorServicoBasico,
        (84000 / 21).floor(),
      );

      // Luz: 10500 / 21 = 500 centavos
      expect(
        cobrancaPagante.valorLuz,
        (10500 / 21).floor(),
      );

      // Condomínio: sempre 15000 (ambas as casas pagam)
      expect(cobrancaPagante.valorCond, 15000);

      // VERIFICAÇÕES DA CASA ISENTA

      // Água: 0 (isento não paga proporcional)
      expect(cobrancaIsenta.valorAgua, 0);

      // Esgoto: 0 (isento não paga igualitário)
      expect(cobrancaIsenta.valorEsgoto, 0);

      // Serviço Básico: 0 (isento não paga igualitário)
      expect(cobrancaIsenta.valorServicoBasico, 0);

      // Luz: 0 (isento não paga igualitário)
      expect(cobrancaIsenta.valorLuz, 0);

      // Condomínio: 15000 (isento PAGA condôminio — regra de negócio)
      expect(cobrancaIsenta.valorCond, 15000);

      // Total da casa isenta deve ser só condomínio
      expect(cobrancaIsenta.valorTotal, 15000);
    });

    /// NOVO TESTE OBRIGATÓRIO: Auditoria — soma dos valores cobrados = total da conta
    /// Com 21 pagantes, garante que componentes igualitários fecham perfeitamente
    test('Auditoria: 21 pagantes — soma dos valores = total da conta', () {
      // Criar 21 casas pagantes e 1 isenta
      final casas = <Casa>[];
      final leituras = <Leitura>[];

      for (int i = 1; i <= 22; i++) {
        casas.add(Casa(
          id: 'casa-$i',
          numero: i,
          ativa: true,
          isento: i == 22, // Casa 22 é isenta
        ));

        leituras.add(Leitura(
          id: 'leitura-$i',
          mesAno: '2026-04',
          casaId: 'casa-$i',
          leituraAnteriorM3: 0,
          leituraAtualM3: 10, // 10 m³ por casa
        ));
      }

      // Consumo total: 21 pagantes x 10 m³ = 210 m³
      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 220, // 220 = 21 * 10 + 1 * 10 (isenta também tem consumo)
        valorAgua: ValorMonetario.fromCentavos(210000), // R$ 2.100,00
        valorEsgoto: ValorMonetario.fromCentavos(210000), // R$ 2.100,00
        valorServicoBasico: ValorMonetario.fromCentavos(210000), // R$ 2.100,00
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(21000), // R$ 210,00
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000), // R$ 150,00
      );

      final cobrancas = <Cobranca>[];
      int sumAguaCalculada = 0;
      int sumEsgotoCalculada = 0;
      int sumServBasicoCalculada = 0;
      int sumLuzCalculada = 0;
      int sumCondCalculada = 0;

      for (final casa in casas) {
        final leitura = leituras.firstWhere((l) => l.casaId == casa.id);

        final cobranca = useCase.execute(
          casa: casa,
          leitura: leitura,
          contaCorsan: contaCorsan,
          contaLuz: contaLuz,
          configuracao: configuracao,
          debitosAbertos: [],
          inadimplentesAnterior: 0,
          dataPagamento: null,
          allLeituras: leituras,
          qtdCasasPagantes: 21,
          consumoGeralPagantes: 210, // 21 casas * 10 m³
        );

        cobrancas.add(cobranca);
        sumAguaCalculada += cobranca.valorAgua;
        sumEsgotoCalculada += cobranca.valorEsgoto;
        sumServBasicoCalculada += cobranca.valorServicoBasico;
        sumLuzCalculada += cobranca.valorLuz;
        sumCondCalculada += cobranca.valorCond;
      }

      // Auditoria: a soma de cada componente deve bater com a conta (ou estar muito próxima)
      // com tolerância para arredondamentos (máximo 21 centavos para 21 casas)
      expect(
        (210000 - sumAguaCalculada).abs(),
        lessThanOrEqualTo(21),
        reason: 'Água: esperado ~210000, somado $sumAguaCalculada',
      );

      expect(
        (210000 - sumEsgotoCalculada).abs(),
        lessThanOrEqualTo(0), // Deve bater perfeitamente com 21 pagantes
        reason: 'Esgoto: esperado 210000, somado $sumEsgotoCalculada',
      );

      expect(
        (210000 - sumServBasicoCalculada).abs(),
        lessThanOrEqualTo(0), // Deve bater perfeitamente com 21 pagantes
        reason: 'Serviço Básico: esperado 210000, somado $sumServBasicoCalculada',
      );

      expect(
        (21000 - sumLuzCalculada).abs(),
        lessThanOrEqualTo(0), // Deve bater perfeitamente com 21 pagantes
        reason: 'Luz: esperado 21000, somado $sumLuzCalculada',
      );

      // Condôminio: 22 casas x 15000 = 330000 (isenta também paga)
      expect(
        sumCondCalculada,
        330000,
        reason: 'Condomínio: esperado 330000, somado $sumCondCalculada',
      );
    });

    /// NOVO TESTE OBRIGATÓRIO: Casa isenta não entra no consumo_geral
    /// Para auditoria de água proporcional
    test('Casa isenta não entra no consumo_geral para água proporcional', () {
      // Casa 1: pagante, consome 10 m³
      final casaPagante = Casa(
        id: 'casa-1',
        numero: 1,
        ativa: true,
        isento: false,
      );

      // Casa 2: isenta, consome 5 m³ (não deve afetar denominador de água)
      final casaIsenta = Casa(
        id: 'casa-2',
        numero: 2,
        ativa: true,
        isento: true,
      );

      final leituraPagante = Leitura(
        id: 'leitura-1',
        mesAno: '2026-04',
        casaId: 'casa-1',
        leituraAnteriorM3: 0,
        leituraAtualM3: 10,
      );

      final leituraIsenta = Leitura(
        id: 'leitura-2',
        mesAno: '2026-04',
        casaId: 'casa-2',
        leituraAnteriorM3: 0,
        leituraAtualM3: 5,
      );

      // Conta CORSAN com 15 m³ (10 pagante + 5 isenta)
      // Mas rateio proporcional de água usa SÓ consumoGeralPagantes = 10 m³
      final contaCorsan = ContaCorsan(
        mesAno: '2026-04',
        leituraAnteriorM3: 0,
        leituraAtualM3: 15,
        valorAgua: ValorMonetario.fromCentavos(100000), // R$ 1.000,00
        valorEsgoto: ValorMonetario.fromCentavos(42000), // R$ 420,00
        valorServicoBasico: ValorMonetario.fromCentavos(42000), // R$ 420,00
      );

      final contaLuz = ContaLuz(
        mesAno: '2026-04',
        valorTotal: ValorMonetario.fromCentavos(2100), // R$ 21,00
      );

      final configuracao = ConfiguracaoMes(
        mesAno: '2026-04',
        valorCond: ValorMonetario.fromCentavos(15000),
      );

      // Casa pagante com consumoGeralPagantes = 10 (só seus próprios 10 m³)
      final cobrancaPagante = useCase.execute(
        casa: casaPagante,
        leitura: leituraPagante,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        debitosAbertos: [],
        inadimplentesAnterior: 0,
        dataPagamento: null,
        allLeituras: [leituraPagante, leituraIsenta],
        qtdCasasPagantes: 1,
        consumoGeralPagantes: 10, // ← Não inclui consumo da casa isenta
      );

      // Água da casa pagante: (10 * 100000) / 10 = 100000 centavos (10000 reais)
      // Se usássemos denominador 15 (incluindo isenta), seria: (10 * 100000) / 15 = 66666 centavos
      expect(
        cobrancaPagante.valorAgua,
        100000,
        reason: 'Água deve usar consumoGeralPagantes (10), não consumo total (15)',
      );
    });
  });
}
