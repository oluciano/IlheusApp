import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/presentation/providers/lancamento_leituras_notifier.dart';
import 'package:ilheus_app/features/agua/presentation/providers/lancamento_leituras_state.dart';

class MockCasaRepository extends Mock implements CasaRepository {}
class MockLeituraRepository extends Mock implements LeituraRepository {}
class MockRef extends Mock implements StateNotifierProviderRef {}

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
    late MockRef mockRef;
    late LancamentoLeiturasNotifier notifier;

    setUp(() {
      casaRepo = MockCasaRepository();
      leituraRepo = MockLeituraRepository();
      mockRef = MockRef();
      notifier = LancamentoLeiturasNotifier(
        ref: mockRef,
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
      when(() => leituraRepo.buscarLeituraCasa(any(), any()))
          .thenAnswer((_) async => null);
      when(() => leituraRepo.buscarUltimaLeitura(any()))
          .thenAnswer((_) async => null);

      await notifier.carregarDados();

      final state = notifier.state;
      expect(state.isLoading, false);
      expect(state.casas.length, 22);
      expect(state.leiturasSalvas, isEmpty);
      expect(state.leiturasMesAnterior, isEmpty);
    });

    test('carregarDados — exclui quiiosque (numero 23)', () async {
      final casas = List.generate(
        23,
        (i) => Casa(id: 'casa-$i', numero: i + 1, ativa: true),
      );
      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes(any())).thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeituraCasa(any(), any()))
          .thenAnswer((_) async => null);
      when(() => leituraRepo.buscarUltimaLeitura(any()))
          .thenAnswer((_) async => null);

      await notifier.carregarDados();

      expect(notifier.state.casas.length, 22);
    });

    test('salvarLeitura — leitura nova (não existe ainda)', () async {
      final casas = [Casa(id: 'casa-1', numero: 1, ativa: true)];
      final casaId = 'casa-1';

      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => []);
      when(() => leituraRepo.buscarLeituraCasa(any(), '03/2026'))
          .thenAnswer((_) async => null);
      when(() => leituraRepo.buscarUltimaLeitura(any()))
          .thenAnswer((_) async => null);
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

    test('carregarDados — preenche anterior de mês não imediato', () async {
      final casaId = 'casa-1';
      final casas = [Casa(id: casaId, numero: 1, ativa: true)];
      
      // Simula que em 03/2026 não houve leitura, mas em 02/2026 sim (atual = 140)
      final leituraFevereiro = Leitura(
        id: 'l-feb',
        mesAno: '02/2026',
        casaId: casaId,
        leituraAnteriorM3: 130,
        leituraAtualM3: 140,
      );

      when(() => casaRepo.buscarAtivas()).thenAnswer((_) async => casas);
      when(() => leituraRepo.buscarLeiturasPorMes('04/2026'))
          .thenAnswer((_) async => []);
      // Mês imediatamente anterior (03/2026) retorna null
      when(() => leituraRepo.buscarLeituraCasa(casaId, '03/2026'))
          .thenAnswer((_) async => null);
      // buscarUltimaLeitura retorna a de fevereiro
      when(() => leituraRepo.buscarUltimaLeitura(casaId))
          .thenAnswer((_) async => leituraFevereiro);

      await notifier.carregarDados();

      final state = notifier.state;
      expect(state.getLeituraAnterior(casaId), 140);
    });

    test('limparErro remove mensagem de erro', () async {
      notifier = LancamentoLeiturasNotifier(
        ref: mockRef,
        casaRepository: casaRepo,
        leituraRepository: leituraRepo,
        mesAno: '04/2026',
      );

      notifier.limparErro();
      expect(notifier.state.errorMessage, isNull);
    });

    test('web mode — repos null retorna false e mostra mensagem', () async {
      final webNotifier = LancamentoLeiturasNotifier(
        ref: mockRef,
        casaRepository: null,
        leituraRepository: null,
        mesAno: '04/2026',
      );

      await webNotifier.carregarDados();
      expect(webNotifier.state.isLoading, false);
      expect(webNotifier.state.errorMessage, contains('sqflite'));
    });
  });
}
