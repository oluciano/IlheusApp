import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/configuracao_mes.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/erro_fechamento.dart';
import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/status_debito.dart';
import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/debito_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/evento_uso_quiosque_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/domain/usecases/calcular_cobranca_casa_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/fechar_fatura_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/orquestrar_fechamento_mensal_usecase.dart';

class MockCasaRepository extends Mock implements CasaRepository {}

class MockLeituraRepository extends Mock implements LeituraRepository {}

class MockAberturaMesRepository extends Mock
    implements AberturaMesRepository {}

class MockFaturaRepository extends Mock implements FaturaCalculadaRepository {}

class MockCobrancaRepository extends Mock implements CobrancaRepository {}

class MockDebitoRepository extends Mock implements DebitoRepository {}

class MockEventoQuiosqueRepository extends Mock
    implements EventoUsoQuiosqueRepository {}

class MockCalcularCobrancaUseCase extends Mock
    implements CalcularCobrancaCasaUseCase {}

class MockFecharFaturaUseCase extends Mock
    implements FecharFaturaMensalUseCase {}

void main() {
  group('OrquestrarFechamentoMensalUseCase', () {
    late OrquestrarFechamentoMensalUseCase useCase;
    late MockCasaRepository casaRepository;
    late MockLeituraRepository leituraRepository;
    late MockAberturaMesRepository aberturaMesRepository;
    late MockFaturaRepository faturaRepository;
    late MockCobrancaRepository cobrancaRepository;
    late MockDebitoRepository debitoRepository;
    late MockEventoQuiosqueRepository eventoQuiosqueRepository;
    late MockCalcularCobrancaUseCase calcularCobrancaUseCase;
    late MockFecharFaturaUseCase fecharFaturaUseCase;

    const mesAno = '2026-04';
    final uuid = const Uuid();

    setUpAll(() {
      registerFallbackValue(
        Cobranca(
          id: 'dummy',
          faturaId: 'dummy',
          casaId: 'dummy',
          valorAgua: 0,
          valorEsgoto: 0,
          valorServicoBasico: 0,
          valorLuz: 0,
          valorCond: 0,
          valorQuiosque: 0,
          valorJuros: 0,
          valorDebitos: 0,
          valorTotal: 0,
          status: StatusCobranca.pendente,
        ),
      );
    });

    setUp(() {
      casaRepository = MockCasaRepository();
      leituraRepository = MockLeituraRepository();
      aberturaMesRepository = MockAberturaMesRepository();
      faturaRepository = MockFaturaRepository();
      cobrancaRepository = MockCobrancaRepository();
      debitoRepository = MockDebitoRepository();
      eventoQuiosqueRepository = MockEventoQuiosqueRepository();
      calcularCobrancaUseCase = MockCalcularCobrancaUseCase();
      fecharFaturaUseCase = MockFecharFaturaUseCase();

      useCase = OrquestrarFechamentoMensalUseCase(
        casaRepository: casaRepository,
        leituraRepository: leituraRepository,
        aberturaMesRepository: aberturaMesRepository,
        faturaRepository: faturaRepository,
        cobrancaRepository: cobrancaRepository,
        debitoRepository: debitoRepository,
        eventoQuiosqueRepository: eventoQuiosqueRepository,
        calcularCobrancaUseCase: calcularCobrancaUseCase,
        fecharFaturaUseCase: fecharFaturaUseCase,
      );
    });

    /// Helper: Cria lista de 22 casas ativas
    List<Casa> criar22Casas() {
      return List.generate(
        22,
        (i) => Casa(
          id: 'casa-${i + 1}',
          numero: i + 1,
        ),
      );
    }

    /// Helper: Cria lista de 22 leituras (uma por casa)
    List<Leitura> criar22Leituras({
      int consumoPorCasaM3 = 5,
    }) {
      return List.generate(
        22,
        (i) => Leitura(
          id: 'leitura-${i + 1}',
          casaId: 'casa-${i + 1}',
          mesAno: mesAno,
          leituraAnteriorM3: 100 + i,
          leituraAtualM3: 100 + i + consumoPorCasaM3,
        ),
      );
    }

    /// Helper: Cria 22 cobranças (uma por casa)
    List<Cobranca> criar22Cobrancas() {
      return List.generate(
        22,
        (i) => Cobranca(
          id: 'cobranca-${i + 1}',
          faturaId: 'fatura-$mesAno',
          casaId: 'casa-${i + 1}',
          valorAgua: 5000, // 50 reais
          valorEsgoto: 5200, // 52 reais
          valorServicoBasico: 3700, // 37 reais
          valorLuz: 454, // 4,54 reais
          valorCond: 1500, // 15 reais
          valorQuiosque: 0,
          valorJuros: 0,
          valorDebitos: 0,
          valorTotal: 15854,
          status: StatusCobranca.pendente,
        ),
      );
    }

    group('validação de pré-condições', () {
      test('falha por casas insuficientes', () async {
        // Arrange: apenas 20 casas ativas
        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => List.generate(
            20,
            (i) => Casa(id: 'casa-${i + 1}', numero: i + 1),
          ),
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );
        final config = const ConfiguracaoMes(mesAno: mesAno);

        // Act & Assert
        expect(
          () => useCase.execute(
            mesAno: mesAno,
            faturaRascunho: fatura,
            configuracao: config,
          ),
          throwsA(isA<FechamentoMensalException>().having(
            (e) => e.erro,
            'erro',
            ErroFechamento.casasInsuficientes,
          )),
        );
      });

      test('falha por ContaCORSAN ausente', () async {
        // Arrange
        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => criar22Casas(),
        );
        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => null,
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );
        final config = const ConfiguracaoMes(mesAno: mesAno);

        // Act & Assert
        expect(
          () => useCase.execute(
            mesAno: mesAno,
            faturaRascunho: fatura,
            configuracao: config,
          ),
          throwsA(isA<FechamentoMensalException>().having(
            (e) => e.erro,
            'erro',
            ErroFechamento.contaCorsanAusente,
          )),
        );
      });

      test('falha por ContaLuz ausente', () async {
        // Arrange
        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => criar22Casas(),
        );

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );
        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => null,
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );
        final config = const ConfiguracaoMes(mesAno: mesAno);

        // Act & Assert
        expect(
          () => useCase.execute(
            mesAno: mesAno,
            faturaRascunho: fatura,
            configuracao: config,
          ),
          throwsA(isA<FechamentoMensalException>().having(
            (e) => e.erro,
            'erro',
            ErroFechamento.contaLuzAusente,
          )),
        );
      });

      test('falha por leituras incompletas', () async {
        // Arrange
        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => criar22Casas(),
        );

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        final contaLuz = ContaLuz(
          mesAno: mesAno,
          valorTotal: ValorMonetario.fromReais(10),
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );

        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => contaLuz,
        );

        when(() => leituraRepository.verificarLeituraCompleta(mesAno))
            .thenAnswer((_) async => false);

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );
        final config = const ConfiguracaoMes(mesAno: mesAno);

        // Act & Assert
        expect(
          () => useCase.execute(
            mesAno: mesAno,
            faturaRascunho: fatura,
            configuracao: config,
          ),
          throwsA(isA<FechamentoMensalException>().having(
            (e) => e.erro,
            'erro',
            ErroFechamento.leiturasIncompletas,
          )),
        );
      });
    });

    group('fechamento completo com sucesso', () {
      test('executa todos os passos e persiste dados', () async {
        // Arrange
        final casas = criar22Casas();
        final leituras = criar22Leituras();
        final cobrancas = criar22Cobrancas();

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        final contaLuz = ContaLuz(
          mesAno: mesAno,
          valorTotal: ValorMonetario.fromReais(10),
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );

        final config = const ConfiguracaoMes(mesAno: mesAno);

        // Mock repositories
        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => casas,
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );

        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => contaLuz,
        );

        when(() => leituraRepository.verificarLeituraCompleta(mesAno))
            .thenAnswer((_) async => true);

        when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
          (_) async => leituras,
        );

        when(() => eventoQuiosqueRepository.buscarPorMes(mesAno)).thenAnswer(
          (_) async => null,
        );

        when(() => debitoRepository.buscarDebitosAbertos(any()))
            .thenAnswer((_) async => []);

        // Mock cálculo de cobrança
        for (var i = 0; i < 22; i++) {
          when(() => calcularCobrancaUseCase.execute(
                casa: casas[i],
                leitura: leituras[i],
                contaCorsan: contaCorsan,
                contaLuz: contaLuz,
                configuracao: config,
                eventoQuiosque: null,
                debitosAbertos: [],
                inadimplentesAnterior: 0,
                dataPagamento: null,
                allLeituras: leituras,
              )).thenReturn(cobrancas[i]);
        }

        // Mock fechamento de fatura (auditoria OK)
        final resultadoFatura = ResultadoFechamentoFatura(
          fatura: fatura.copyWith(status: StatusFatura.publicado),
          auditoria: AuditoriaFatura(
            faturaId: fatura.id,
            somaMetrosCasas: 110,
            consumoGeralCorsan: 110,
            diferencaMetros: 0,
            somaEsgotoCasas: 114,
            valorEsgotoCorsan: 114,
            somaLuzCasas: 10,
            valorLuzCorsan: 10,
            totalCobrado: 349000,
            status: StatusAuditoria.ok,
            mensagem: null,
          ),
        );

        when(() => fecharFaturaUseCase.execute(
              cobrancas: cobrancas,
              contaCorsan: contaCorsan,
              contaLuz: contaLuz,
              faturaRascunho: fatura,
              leituras: leituras,
            )).thenReturn(resultadoFatura);

        when(() => cobrancaRepository.salvarCobranca(any()))
            .thenAnswer((_) async {});

        when(() => faturaRepository.atualizarStatus(
              fatura.id,
              StatusFatura.publicado,
            )).thenAnswer((_) async {});

        // Act
        final resultado = await useCase.execute(
          mesAno: mesAno,
          faturaRascunho: fatura,
          configuracao: config,
        );

        // Assert
        expect(resultado.fatura.isPublicado, isTrue);
        expect(resultado.cobrancas, hasLength(22));
        expect(resultado.auditoria.status.name, 'ok');
        expect(resultado.alertas, isEmpty);

        // Verificar que as operações foram chamadas
        verify(() => casaRepository.buscarAtivas()).called(1);
        verify(() => aberturaMesRepository.getContaCorsan(mesAno)).called(1);
        verify(() => aberturaMesRepository.getContaLuz(mesAno)).called(1);
        verify(
          () => leituraRepository.verificarLeituraCompleta(mesAno),
        ).called(1);
        verify(() => leituraRepository.buscarLeiturasPorMes(mesAno))
            .called(1);

        for (final cobranca in cobrancas) {
          verify(() => cobrancaRepository.salvarCobranca(cobranca))
              .called(1);
        }
      });

      test('persiste com alerta quando auditoria detecta diferença em metros',
          () async {
        // Arrange
        final casas = criar22Casas();
        final leituras = criar22Leituras();
        final cobrancas = criar22Cobrancas();

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        final contaLuz = ContaLuz(
          mesAno: mesAno,
          valorTotal: ValorMonetario.fromReais(10),
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );

        final config = const ConfiguracaoMes(mesAno: mesAno);

        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => casas,
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );

        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => contaLuz,
        );

        when(() => leituraRepository.verificarLeituraCompleta(mesAno))
            .thenAnswer((_) async => true);

        when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
          (_) async => leituras,
        );

        when(() => eventoQuiosqueRepository.buscarPorMes(mesAno)).thenAnswer(
          (_) async => null,
        );

        when(() => debitoRepository.buscarDebitosAbertos(any()))
            .thenAnswer((_) async => []);

        for (var i = 0; i < 22; i++) {
          when(() => calcularCobrancaUseCase.execute(
                casa: casas[i],
                leitura: leituras[i],
                contaCorsan: contaCorsan,
                contaLuz: contaLuz,
                configuracao: config,
                eventoQuiosque: null,
                debitosAbertos: [],
                inadimplentesAnterior: 0,
                dataPagamento: null,
                allLeituras: leituras,
              )).thenReturn(cobrancas[i]);
        }

        // Auditoria com ALERTA (diferença em metros = quiosque/vazamento)
        final resultadoFatura = ResultadoFechamentoFatura(
          fatura: fatura.copyWith(status: StatusFatura.publicado),
          auditoria: AuditoriaFatura(
            faturaId: fatura.id,
            somaMetrosCasas: 100,
            consumoGeralCorsan: 110,
            diferencaMetros: 10,
            somaEsgotoCasas: 114,
            valorEsgotoCorsan: 114,
            somaLuzCasas: 10,
            valorLuzCorsan: 10,
            totalCobrado: 349000,
            status: StatusAuditoria.alerta,
            mensagem: 'ALERTA: Diferença de 10 m³ entre CORSAN e casas.',
          ),
        );

        when(() => fecharFaturaUseCase.execute(
              cobrancas: cobrancas,
              contaCorsan: contaCorsan,
              contaLuz: contaLuz,
              faturaRascunho: fatura,
              leituras: leituras,
            )).thenReturn(resultadoFatura);

        when(() => cobrancaRepository.salvarCobranca(any()))
            .thenAnswer((_) async {});

        when(() => faturaRepository.atualizarStatus(
              fatura.id,
              StatusFatura.publicado,
            )).thenAnswer((_) async {});

        // Act
        final resultado = await useCase.execute(
          mesAno: mesAno,
          faturaRascunho: fatura,
          configuracao: config,
        );

        // Assert
        expect(resultado.fatura.isPublicado, isTrue);
        expect(resultado.alertas, isNotEmpty);
        expect(
          resultado.alertas.first,
          contains('ALERTA: Diferença de 10 m³'),
        );
      });
    });

    group('falha com auditoria', () {
      test('falha quando auditoria retorna erro', () async {
        // Arrange
        final casas = criar22Casas();
        final leituras = criar22Leituras();
        final cobrancas = criar22Cobrancas();

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        final contaLuz = ContaLuz(
          mesAno: mesAno,
          valorTotal: ValorMonetario.fromReais(10),
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );

        final config = const ConfiguracaoMes(mesAno: mesAno);

        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => casas,
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );

        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => contaLuz,
        );

        when(() => leituraRepository.verificarLeituraCompleta(mesAno))
            .thenAnswer((_) async => true);

        when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
          (_) async => leituras,
        );

        when(() => eventoQuiosqueRepository.buscarPorMes(mesAno)).thenAnswer(
          (_) async => null,
        );

        when(() => debitoRepository.buscarDebitosAbertos(any()))
            .thenAnswer((_) async => []);

        for (var i = 0; i < 22; i++) {
          when(() => calcularCobrancaUseCase.execute(
                casa: casas[i],
                leitura: leituras[i],
                contaCorsan: contaCorsan,
                contaLuz: contaLuz,
                configuracao: config,
                eventoQuiosque: null,
                debitosAbertos: [],
                inadimplentesAnterior: 0,
                dataPagamento: null,
                allLeituras: leituras,
              )).thenReturn(cobrancas[i]);
        }

        // Auditoria com ERRO (impossível publicar)
        final resultadoFatura = ResultadoFechamentoFatura(
          fatura: fatura.copyWith(status: StatusFatura.rascunho),
          auditoria: AuditoriaFatura(
            faturaId: fatura.id,
            somaMetrosCasas: 120,
            consumoGeralCorsan: 110,
            diferencaMetros: -10,
            somaEsgotoCasas: 200,
            valorEsgotoCorsan: 114,
            somaLuzCasas: 10,
            valorLuzCorsan: 10,
            totalCobrado: 349000,
            status: StatusAuditoria.erro,
            mensagem:
                'ERRO: Soma de metros das casas (10 m³) maior que consumo CORSAN.',
          ),
        );

        when(() => fecharFaturaUseCase.execute(
              cobrancas: cobrancas,
              contaCorsan: contaCorsan,
              contaLuz: contaLuz,
              faturaRascunho: fatura,
              leituras: leituras,
            )).thenReturn(resultadoFatura);

        // Act & Assert
        expect(
          () => useCase.execute(
            mesAno: mesAno,
            faturaRascunho: fatura,
            configuracao: config,
          ),
          throwsA(isA<FechamentoMensalException>().having(
            (e) => e.erro,
            'erro',
            ErroFechamento.auditoriaFalhou,
          )),
        );

        // Verificar que cobrancas NÃO foram persistidas
        verifyNever(() => cobrancaRepository.salvarCobranca(any()));
      });
    });

    group('integração com EventoUsoQuiosque', () {
      test('calcula cobrança aplicando uso de quiosque', () async {
        // Arrange
        final casas = criar22Casas();
        final leituras = criar22Leituras();
        final cobrancas = criar22Cobrancas();

        final evento = EventoUsoQuiosque(
          id: 'evento-1',
          mesAno: mesAno,
          casaIds: ['casa-1', 'casa-2'],
        );

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        final contaLuz = ContaLuz(
          mesAno: mesAno,
          valorTotal: ValorMonetario.fromReais(10),
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );

        final config = const ConfiguracaoMes(mesAno: mesAno);

        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => casas,
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );

        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => contaLuz,
        );

        when(() => leituraRepository.verificarLeituraCompleta(mesAno))
            .thenAnswer((_) async => true);

        when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
          (_) async => leituras,
        );

        when(() => eventoQuiosqueRepository.buscarPorMes(mesAno)).thenAnswer(
          (_) async => evento,
        );

        when(() => debitoRepository.buscarDebitosAbertos(any()))
            .thenAnswer((_) async => []);

        for (var i = 0; i < 22; i++) {
          when(() => calcularCobrancaUseCase.execute(
                casa: casas[i],
                leitura: leituras[i],
                contaCorsan: contaCorsan,
                contaLuz: contaLuz,
                configuracao: config,
                eventoQuiosque: evento,
                debitosAbertos: [],
                inadimplentesAnterior: 0,
                dataPagamento: null,
                allLeituras: leituras,
              )).thenReturn(cobrancas[i]);
        }

        final resultadoFatura = ResultadoFechamentoFatura(
          fatura: fatura.copyWith(status: StatusFatura.publicado),
          auditoria: AuditoriaFatura(
            faturaId: fatura.id,
            somaMetrosCasas: 110,
            consumoGeralCorsan: 110,
            diferencaMetros: 0,
            somaEsgotoCasas: 114,
            valorEsgotoCorsan: 114,
            somaLuzCasas: 10,
            valorLuzCorsan: 10,
            totalCobrado: 349000,
            status: StatusAuditoria.ok,
            mensagem: null,
          ),
        );

        when(() => fecharFaturaUseCase.execute(
              cobrancas: cobrancas,
              contaCorsan: contaCorsan,
              contaLuz: contaLuz,
              faturaRascunho: fatura,
              leituras: leituras,
            )).thenReturn(resultadoFatura);

        when(() => cobrancaRepository.salvarCobranca(any()))
            .thenAnswer((_) async {});

        when(() => faturaRepository.atualizarStatus(
              fatura.id,
              StatusFatura.publicado,
            )).thenAnswer((_) async {});

        // Act
        final resultado = await useCase.execute(
          mesAno: mesAno,
          faturaRascunho: fatura,
          configuracao: config,
        );

        // Assert
        expect(resultado.cobrancas, hasLength(22));
        expect(resultado.fatura.isPublicado, isTrue);

        // Verificar que calcularCobrancaUseCase foi chamado COM evento
        for (var i = 0; i < 22; i++) {
          verify(() => calcularCobrancaUseCase.execute(
                casa: casas[i],
                leitura: leituras[i],
                contaCorsan: contaCorsan,
                contaLuz: contaLuz,
                configuracao: config,
                eventoQuiosque: evento,
                debitosAbertos: [],
                inadimplentesAnterior: 0,
                dataPagamento: null,
                allLeituras: leituras,
              )).called(1);
        }
      });
    });

    group('integração com débitos', () {
      test('calcula cobrança aplicando débitos abertos', () async {
        // Arrange
        final casas = criar22Casas();
        final leituras = criar22Leituras();

        // Casa 1 tem débito aberto de 1000 centavos (10 reais)
        final debito1 = Debito(
          id: 'debito-1',
          cobrancaId: 'cobranca-anterior',
          casaId: 'casa-1',
          mesAnoOrigem: '2026-03',
          valorCentavos: 1000,
          status: StatusDebito.aberto,
        );

        final cobrancas = criar22Cobrancas();

        final contaCorsan = ContaCorsan(
          mesAno: mesAno,
          leituraAnteriorM3: 100,
          leituraAtualM3: 210,
          valorAgua: ValorMonetario.fromReais(110),
          valorEsgoto: ValorMonetario.fromReais(114),
          valorServicoBasico: ValorMonetario.fromReais(81),
        );

        final contaLuz = ContaLuz(
          mesAno: mesAno,
          valorTotal: ValorMonetario.fromReais(10),
        );

        final fatura = FaturaCalculada(
          id: 'fatura-$mesAno',
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );

        final config = const ConfiguracaoMes(mesAno: mesAno);

        when(() => casaRepository.buscarAtivas()).thenAnswer(
          (_) async => casas,
        );

        when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
          (_) async => contaCorsan,
        );

        when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
          (_) async => contaLuz,
        );

        when(() => leituraRepository.verificarLeituraCompleta(mesAno))
            .thenAnswer((_) async => true);

        when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
          (_) async => leituras,
        );

        when(() => eventoQuiosqueRepository.buscarPorMes(mesAno)).thenAnswer(
          (_) async => null,
        );

        // Casa 1 tem débito, demais não
        when(() => debitoRepository.buscarDebitosAbertos('casa-1'))
            .thenAnswer((_) async => [debito1]);

        for (var i = 1; i < 22; i++) {
          when(() => debitoRepository.buscarDebitosAbertos('casa-${i + 1}'))
              .thenAnswer((_) async => []);
        }

        for (var i = 0; i < 22; i++) {
          final debitosExpected = i == 0 ? [debito1] : <Debito>[];

          when(() => calcularCobrancaUseCase.execute(
                casa: casas[i],
                leitura: leituras[i],
                contaCorsan: contaCorsan,
                contaLuz: contaLuz,
                configuracao: config,
                eventoQuiosque: null,
                debitosAbertos: debitosExpected,
                inadimplentesAnterior: 0,
                dataPagamento: null,
                allLeituras: leituras,
              )).thenReturn(cobrancas[i]);
        }

        final resultadoFatura = ResultadoFechamentoFatura(
          fatura: fatura.copyWith(status: StatusFatura.publicado),
          auditoria: AuditoriaFatura(
            faturaId: fatura.id,
            somaMetrosCasas: 110,
            consumoGeralCorsan: 110,
            diferencaMetros: 0,
            somaEsgotoCasas: 114,
            valorEsgotoCorsan: 114,
            somaLuzCasas: 10,
            valorLuzCorsan: 10,
            totalCobrado: 349000,
            status: StatusAuditoria.ok,
            mensagem: null,
          ),
        );

        when(() => fecharFaturaUseCase.execute(
              cobrancas: cobrancas,
              contaCorsan: contaCorsan,
              contaLuz: contaLuz,
              faturaRascunho: fatura,
              leituras: leituras,
            )).thenReturn(resultadoFatura);

        when(() => cobrancaRepository.salvarCobranca(any()))
            .thenAnswer((_) async {});

        when(() => faturaRepository.atualizarStatus(
              fatura.id,
              StatusFatura.publicado,
            )).thenAnswer((_) async {});

        // Act
        final resultado = await useCase.execute(
          mesAno: mesAno,
          faturaRascunho: fatura,
          configuracao: config,
        );

        // Assert
        expect(resultado.cobrancas, hasLength(22));

        // Verificar que débitos foram passados para calcularCobrancaUseCase
        verify(() => calcularCobrancaUseCase.execute(
              casa: casas[0],
              leitura: leituras[0],
              contaCorsan: contaCorsan,
              contaLuz: contaLuz,
              configuracao: config,
              eventoQuiosque: null,
              debitosAbertos: [debito1],
              inadimplentesAnterior: 0,
              dataPagamento: null,
              allLeituras: leituras,
            )).called(1);
      });
    });
  });
}
