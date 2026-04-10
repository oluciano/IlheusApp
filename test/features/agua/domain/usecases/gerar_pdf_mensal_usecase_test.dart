import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/configuracao_mes.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/domain/usecases/gerar_pdf_mensal_usecase.dart';

class MockCasaRepository extends Mock implements CasaRepository {}

class MockLeituraRepository extends Mock implements LeituraRepository {}

class MockAberturaMesRepository extends Mock
    implements AberturaMesRepository {}

class MockFaturaRepository extends Mock implements FaturaCalculadaRepository {}

class MockCobrancaRepository extends Mock implements CobrancaRepository {}

class MockDiretorioProvider extends Mock implements DiretorioProvider {}

void main() {
  group('GerarPdfMensalUseCase', () {
    late GerarPdfMensalUseCase useCase;
    late MockCasaRepository casaRepository;
    late MockLeituraRepository leituraRepository;
    late MockAberturaMesRepository aberturaMesRepository;
    late MockFaturaRepository faturaRepository;
    late MockCobrancaRepository cobrancaRepository;
    late MockDiretorioProvider diretorioProvider;

    const mesAno = '2026-04';
    final tempDir = Directory.systemTemp.createTempSync('ilheu_pdf_test_');

    setUpAll(() {
      registerFallbackValue(
        Casa(id: 'dummy', numero: 1),
      );
      registerFallbackValue(
        Leitura(
          id: 'dummy',
          mesAno: '2026-04',
          casaId: 'dummy',
          leituraAnteriorM3: 0,
          leituraAtualM3: 0,
        ),
      );
      registerFallbackValue(
        Cobranca(
          id: 'dummy',
          faturaId: 'dummy',
          casaId: 'dummy',
          valorTotal: 0,
        ),
      );
      registerFallbackValue(
        ContaCorsan(mesAno: '2026-04'),
      );
      registerFallbackValue(
        ContaLuz(mesAno: '2026-04'),
      );
      registerFallbackValue(
        ConfiguracaoMes(mesAno: '2026-04'),
      );
      registerFallbackValue(
        FaturaCalculada(
          id: 'dummy',
          mesAno: '2026-04',
          status: StatusFatura.publicado,
        ),
      );
    });

    setUp(() {
      casaRepository = MockCasaRepository();
      leituraRepository = MockLeituraRepository();
      aberturaMesRepository = MockAberturaMesRepository();
      faturaRepository = MockFaturaRepository();
      cobrancaRepository = MockCobrancaRepository();
      diretorioProvider = MockDiretorioProvider();

      when(() => diretorioProvider.getDiretorioDownloads()).thenAnswer(
        (_) async => tempDir,
      );

      useCase = GerarPdfMensalUseCase(
        casaRepository: casaRepository,
        leituraRepository: leituraRepository,
        aberturaMesRepository: aberturaMesRepository,
        faturaRepository: faturaRepository,
        cobrancaRepository: cobrancaRepository,
        diretorioProvider: diretorioProvider,
      );
    });

    tearDown(() {
      // Limpar arquivos criados no tempDir
      if (tempDir.existsSync()) {
        for (final entity in tempDir.listSync()) {
          entity.deleteSync();
        }
      }
    });

    List<Casa> criar22Casas() {
      return List.generate(
        22,
        (i) => Casa(
          id: 'casa-${i + 1}',
          numero: i + 1,
        ),
      );
    }

    List<Leitura> criar22Leituras({int consumoPorCasaM3 = 5}) {
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

    List<Cobranca> criar22Cobrancas({String faturaId = 'fatura-2026-04'}) {
      return List.generate(
        22,
        (i) => Cobranca(
          id: 'cobranca-${i + 1}',
          faturaId: faturaId,
          casaId: 'casa-${i + 1}',
          valorAgua: 5000,
          valorEsgoto: 5200,
          valorServicoBasico: 3700,
          valorLuz: 454,
          valorCond: 1500,
          valorQuiosque: 0,
          valorJuros: 0,
          valorDebitos: 0,
          valorTotal: 15854,
          status: StatusCobranca.pendente,
        ),
      );
    }

    test('gera PDF com sucesso e salva no diretório configurado', () async {
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

      final config = const ConfiguracaoMes(
        mesAno: mesAno,
        valorCond: ValorMonetario(1500),
      );

      final fatura = FaturaCalculada(
        id: 'fatura-$mesAno',
        mesAno: mesAno,
        status: StatusFatura.publicado,
      );

      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => contaCorsan,
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => contaLuz,
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => config,
      );
      when(() => casaRepository.buscarAtivas()).thenAnswer(
        (_) async => casas,
      );
      when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
        (_) async => leituras,
      );
      when(() => faturaRepository.buscarPorMes(mesAno)).thenAnswer(
        (_) async => fatura,
      );
      when(
        () => cobrancaRepository.buscarCobrancasPorFatura(fatura.id),
      ).thenAnswer((_) async => cobrancas);

      // Act
      final resultado = await useCase.execute(mesAno: mesAno);

      // Assert
      expect(resultado.caminhoArquivo, contains('ilheus_04_2026.pdf'));
      expect(resultado.tamanhoBytes, greaterThan(0));
      expect(File(resultado.caminhoArquivo).existsSync(), isTrue);
    });

    test('lança exceção quando ContaCORSAN está ausente', () async {
      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => null,
      );

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('ContaCORSAN'),
          ),
        ),
      );
    });

    test('lança exceção quando ContaLuz está ausente', () async {
      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => ContaCorsan(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => null,
      );

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('ContaLuz'),
          ),
        ),
      );
    });

    test('lança exceção quando configuração do mês está ausente', () async {
      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => ContaCorsan(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => ContaLuz(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => null,
      );

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Configuração'),
          ),
        ),
      );
    });

    test('lança exceção quando não há casas ativas', () async {
      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => ContaCorsan(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => ContaLuz(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => const ConfiguracaoMes(mesAno: mesAno),
      );
      when(() => casaRepository.buscarAtivas()).thenAnswer(
        (_) async => [],
      );

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('casa ativa'),
          ),
        ),
      );
    });

    test('lança exceção quando não há leituras', () async {
      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => ContaCorsan(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => ContaLuz(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => const ConfiguracaoMes(mesAno: mesAno),
      );
      when(() => casaRepository.buscarAtivas()).thenAnswer(
        (_) async => criar22Casas(),
      );
      when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
        (_) async => [],
      );

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('leitura'),
          ),
        ),
      );
    });

    test('lança exceção quando fatura não existe', () async {
      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => ContaCorsan(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => ContaLuz(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => const ConfiguracaoMes(mesAno: mesAno),
      );
      when(() => casaRepository.buscarAtivas()).thenAnswer(
        (_) async => criar22Casas(),
      );
      when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
        (_) async => criar22Leituras(),
      );
      when(() => faturaRepository.buscarPorMes(mesAno)).thenAnswer(
        (_) async => null,
      );

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('Fatura'),
          ),
        ),
      );
    });

    test('lança exceção quando não há cobranças', () async {
      final fatura = FaturaCalculada(
        id: 'fatura-$mesAno',
        mesAno: mesAno,
        status: StatusFatura.publicado,
      );

      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => ContaCorsan(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => ContaLuz(mesAno: mesAno),
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => const ConfiguracaoMes(mesAno: mesAno),
      );
      when(() => casaRepository.buscarAtivas()).thenAnswer(
        (_) async => criar22Casas(),
      );
      when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
        (_) async => criar22Leituras(),
      );
      when(() => faturaRepository.buscarPorMes(mesAno)).thenAnswer(
        (_) async => fatura,
      );
      when(
        () => cobrancaRepository.buscarCobrancasPorFatura(fatura.id),
      ).thenAnswer((_) async => []);

      expect(
        () => useCase.execute(mesAno: mesAno),
        throwsA(
          isA<GerarPdfException>().having(
            (e) => e.mensagem,
            'mensagem',
            contains('cobrança'),
          ),
        ),
      );
    });

    test('PDF gerado contém dados das 22 casas', () async {
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

      final config = const ConfiguracaoMes(
        mesAno: mesAno,
        valorCond: ValorMonetario(1500),
      );

      final fatura = FaturaCalculada(
        id: 'fatura-$mesAno',
        mesAno: mesAno,
        status: StatusFatura.publicado,
      );

      when(() => aberturaMesRepository.getContaCorsan(mesAno)).thenAnswer(
        (_) async => contaCorsan,
      );
      when(() => aberturaMesRepository.getContaLuz(mesAno)).thenAnswer(
        (_) async => contaLuz,
      );
      when(() => aberturaMesRepository.getConfiguracaoMes(mesAno)).thenAnswer(
        (_) async => config,
      );
      when(() => casaRepository.buscarAtivas()).thenAnswer(
        (_) async => casas,
      );
      when(() => leituraRepository.buscarLeiturasPorMes(mesAno)).thenAnswer(
        (_) async => leituras,
      );
      when(() => faturaRepository.buscarPorMes(mesAno)).thenAnswer(
        (_) async => fatura,
      );
      when(
        () => cobrancaRepository.buscarCobrancasPorFatura(fatura.id),
      ).thenAnswer((_) async => cobrancas);

      // Act
      final resultado = await useCase.execute(mesAno: mesAno);

      // Assert: o arquivo existe e tem tamanho razoável (> 1KB para 22 casas)
      final file = File(resultado.caminhoArquivo);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(1024));
    });
  });
}
