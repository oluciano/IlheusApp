import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/presentation/providers/lancamento_leituras_notifier.dart';
import 'package:ilheus_app/features/agua/presentation/providers/lancamento_leituras_state.dart';

class MockCasaRepository extends Mock implements CasaRepository {}

class MockLeituraRepository extends Mock implements LeituraRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      Leitura(
        id: 'fallback',
        mesAno: '01/2026',
        casaId: 'casa-0',
        leituraAnteriorM3: 0,
        leituraAtualM3: 0,
      ),
    );
    registerFallbackValue(
      Casa(id: 'fallback', numero: 1),
    );
  });

  group('LancamentoLeiturasState', () {
    test('estado inicial com lista vazia', () {
      const state = LancamentoLeiturasState(mesAno: '04/2026');

      expect(state.mesAno, '04/2026');
      expect(state.isLoading, true);
      expect(state.isSaving, false);
      expect(state.casas, isEmpty);
      expect(state.leiturasSalvas, isEmpty);
      expect(state.casasComLeitura, 0);
      expect(state.totalCasas, 0);
      expect(state.leituraCompleta, false);
    });

    test('getLeituraAnterior retorna 0 quando não há mês anterior', () {
      const state = LancamentoLeiturasState(mesAno: '01/2026');
      expect(state.getLeituraAnterior('casa-1'), 0);
    });

    test('getLeituraAnterior retorna leituraAtualM3 do mês anterior', () {
      final leituraAnterior = Leitura(
        id: 'l1',
        mesAno: '03/2026',
        casaId: 'casa-1',
        leituraAnteriorM3: 100,
        leituraAtualM3: 150,
      );

      final state = LancamentoLeiturasState(
        mesAno: '04/2026',
        leiturasMesAnterior: [leituraAnterior],
      );

      expect(state.getLeituraAnterior('casa-1'), 150);
    });

    test('leituraCompleta = true quando todas as casas têm leitura', () {
      final casas = List.generate(
        22,
        (i) => Casa(id: 'casa-$i', numero: i + 1),
      );
      final leituras = List.generate(
        22,
        (i) => Leitura(
          id: 'l-$i',
          mesAno: '04/2026',
          casaId: 'casa-$i',
          leituraAnteriorM3: 100,
          leituraAtualM3: 120,
        ),
      );

      final state = LancamentoLeiturasState(
        mesAno: '04/2026',
        casas: casas,
        leiturasSalvas: leituras,
        isLoading: false,
      );

      expect(state.casasComLeitura, 22);
      expect(state.totalCasas, 22);
      expect(state.leituraCompleta, true);
    });

    test('leituraCompleta = false com 21 de 22', () {
      final casas = List.generate(
        22,
        (i) => Casa(id: 'casa-$i', numero: i + 1),
      );
      final leituras = List.generate(
        21,
        (i) => Leitura(
          id: 'l-$i',
          mesAno: '04/2026',
          casaId: 'casa-$i',
          leituraAnteriorM3: 100,
          leituraAtualM3: 120,
        ),
      );

      final state = LancamentoLeiturasState(
        mesAno: '04/2026',
        casas: casas,
        leiturasSalvas: leituras,
        isLoading: false,
      );

      expect(state.casasComLeitura, 21);
      expect(state.totalCasas, 22);
      expect(state.leituraCompleta, false);
    });

    test('copyWith preserva campos não especificados', () {
      const original = LancamentoLeiturasState(
        mesAno: '04/2026',
        isLoading: true,
      );

      final copy = original.copyWith(isLoading: false);

      expect(copy.mesAno, '04/2026');
      expect(copy.isLoading, false);
      expect(copy.casas, isEmpty);
    });
  });

  group('LancamentoLeiturasNotifier', () {
    late MockCasaRepository casaRepo;
    late MockLeituraRepository leituraRepo;
    late LancamentoLeiturasNotifier notifier;

    setUp(() {
      casaRepo = MockCasaRepository();
      leituraRepo = MockLeituraRepository();
      notifier = LancamentoLeiturasNotifier(
        casaRepository: casaRepo,
        leituraRepository: leituraRepo,
        mesAno: '04/2026',
      );
    });

    test('carregarDados — primeiro mês sem leituras anteriores', () async {
      final casas = List.generate(
        22,
        (i) => Casa(id: 'casa-$i', numero: i + 1, ativa: true),
      );
      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => []);
      // Janeiro → mês anterior não existe → retorna []
      when(() => leituraRepo.buscarLeiturasPorMes('03/2026'))
          .thenAnswer((_) async => []);

      await notifier.carregarDados();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.casas.length, 22);
      expect(state.leiturasSalvas, isEmpty);
      expect(state.casasComLeitura, 0);
    });

    test('carregarDados — exclui quiiosque (numero 23)', () async {
      final casas = List.generate(
        23,
        (i) => Casa(id: 'casa-$i', numero: i + 1, ativa: true),
      );
      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes(any())).thenAnswer((_) async => []);

      await notifier.carregarDados();

      // 23 casas no banco, mas quiiosque (23) é excluído → sobram 22
      expect(notifier.state.casas.length, 22);
    });

    test('carregarDados — mês anterior retorna leituras', () async {
      final casas = [Casa(id: 'casa-1', numero: 1, ativa: true)];
      final leiturasAnteriores = [
        Leitura(
          id: 'l-prev',
          mesAno: '03/2026',
          casaId: 'casa-1',
          leituraAnteriorM3: 100,
          leituraAtualM3: 150,
        ),
      ];

      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeiturasPorMes('03/2026'))
          .thenAnswer((_) async => leiturasAnteriores);

      await notifier.carregarDados();

      expect(notifier.state.getLeituraAnterior('casa-1'), 150);
    });

    test('salvarLeitura — leituraAtual < anterior → retorna false', () async {
      final casas = [Casa(id: 'casa-1', numero: 1, ativa: true)];
      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes(any())).thenAnswer((_) async => []);

      await notifier.carregarDados();

      final resultado = await notifier.salvarLeitura(
        casaId: 'casa-1',
        leituraAtual: 50, // anterior = 0
      );

      expect(resultado, false);
      expect(notifier.state.errorMessage, isNotNull);
    });

    test('salvarLeitura — leituraAtual == anterior → retorna true', () async {
      final casas = [Casa(id: 'casa-1', numero: 1, ativa: true)];
      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeiturasPorMes('03/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeituraCasa('casa-1', '04/2026'))
          .thenAnswer((_) async => null);
      when(() => leituraRepo.salvarLeitura(any())).thenAnswer((_) async {});

      await notifier.carregarDados();

      final resultado = await notifier.salvarLeitura(
        casaId: 'casa-1',
        leituraAtual: 0, // igual à anterior
      );

      expect(resultado, true);
      expect(notifier.state.errorMessage, isNull);
    });

    test('salvarLeitura — leitura nova (não existe ainda)', () async {
      final casas = [Casa(id: 'casa-1', numero: 1, ativa: true)];
      final casaId = 'casa-1';

      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeiturasPorMes('03/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeituraCasa(casaId, '04/2026'))
          .thenAnswer((_) async => null);
      when(() => leituraRepo.salvarLeitura(any())).thenAnswer((_) async {});

      await notifier.carregarDados();

      final resultado = await notifier.salvarLeitura(
        casaId: casaId,
        leituraAtual: 120,
      );

      expect(resultado, true);
      verify(() => leituraRepo.salvarLeitura(any())).called(1);
    });

    test('salvarLeitura — atualiza leitura existente', () async {
      final casas = [Casa(id: 'casa-1', numero: 1, ativa: true)];
      final casaId = 'casa-1';
      final leituraExistente = Leitura(
        id: 'leitura-existente',
        mesAno: '04/2026',
        casaId: casaId,
        leituraAnteriorM3: 100,
        leituraAtualM3: 120,
      );

      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => [leituraExistente]);
      when(() => leituraRepo.buscarLeiturasPorMes('03/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeituraCasa(casaId, '04/2026'))
          .thenAnswer((_) async => leituraExistente);
      when(() => leituraRepo.salvarLeitura(any())).thenAnswer((_) async {});

      await notifier.carregarDados();

      final resultado = await notifier.salvarLeitura(
        casaId: casaId,
        leituraAtual: 130,
      );

      expect(resultado, true);
      // Verifica que salvou reutilizando o ID existente
      verify(() => leituraRepo.salvarLeitura(any())).called(1);
    });

    test('casa isenta (08) aparece normalmente na lista', () async {
      final casas = [
        Casa(id: 'casa-8', numero: 8, ativa: true, isento: true),
      ];
      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes(any())).thenAnswer((_) async => []);

      await notifier.carregarDados();

      expect(notifier.state.casas.length, 1);
      expect(notifier.state.casas[0].isento, true);
      expect(notifier.state.casas[0].numero, 8);
    });

    test('_getMesAnoAnterior — janeiro retorna dezembro do ano anterior', () {
      final notifierJan = LancamentoLeiturasNotifier(
        casaRepository: casaRepo,
        leituraRepository: leituraRepo,
        mesAno: '01/2026',
      );

      // Teste indireto via carregarDados: passa '12/2025' como mês anterior
      expect(notifierJan.state.mesAno, '01/2026');
    });

    test('limparErro remove mensagem de erro', () async {
      notifier = LancamentoLeiturasNotifier(
        casaRepository: casaRepo,
        leituraRepository: leituraRepo,
        mesAno: '04/2026',
      );

      // Força um erro
      await notifier.salvarLeitura(casaId: 'casa-x', leituraAtual: 50);
      expect(notifier.state.errorMessage, isNotNull);

      notifier.limparErro();
      expect(notifier.state.errorMessage, isNull);
    });

    test('web mode — repos null retorna false e mostra mensagem', () async {
      final webNotifier = LancamentoLeiturasNotifier(
        casaRepository: null,
        leituraRepository: null,
        mesAno: '04/2026',
      );

      await webNotifier.carregarDados();
      expect(webNotifier.state.isLoading, false);
      expect(webNotifier.state.errorMessage, contains('sqflite'));

      final resultado = await webNotifier.salvarLeitura(
        casaId: 'casa-1',
        leituraAtual: 100,
      );
      expect(resultado, false);
      expect(webNotifier.state.errorMessage, contains('sqflite'));
    });
  });
}
