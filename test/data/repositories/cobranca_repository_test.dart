import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/cobranca_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakeCobrancaDataSource implements CobrancaDataSource {
  @override
  final Database db;
  FakeCobrancaDataSource(this.db);
}

void main() {
  group('CobrancaRepository', () {
    late CobrancaRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = CobrancaRepositoryImpl(FakeCobrancaDataSource(db));
    });

    final faturaId = 'fatura-1';
    final casaId = 'casa-1';
    final mesAno = '04/2026';

    group('salvarCobranca', () {
      test('insere cobrança com ID existente', () async {
        final cobranca = Cobranca(
          id: 'cob-1',
          faturaId: faturaId,
          casaId: casaId,
          valorTotal: 17654,
        );

        when(() => db.insert('cobrancas', cobranca.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarCobranca(cobranca);

        verify(() => db.insert('cobrancas', cobranca.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });

      test('gera UUID para cobrança sem ID', () async {
        final cobranca = Cobranca(
          id: '',
          faturaId: faturaId,
          casaId: casaId,
          valorTotal: 17654,
        );

        late Map<String, dynamic> insertedMap;
        when(() => db.insert('cobrancas', any(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((inv) {
          insertedMap = inv.positionalArguments[1] as Map<String, dynamic>;
          return Future.value(1);
        });

        await repository.salvarCobranca(cobranca);

        expect(insertedMap['id'], isNotNull);
        expect(insertedMap['id'], isNotEmpty);
      });

      test('lança ArgumentError quando faturaId está vazio', () async {
        final cobranca = Cobranca(
          id: 'cob-1',
          faturaId: '',
          casaId: casaId,
          valorTotal: 17654,
        );

        expect(
          () => repository.salvarCobranca(cobranca),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('buscarCobrancasPorFatura', () {
      test('retorna todas as cobranças da fatura', () async {
        final rows = [
          {
            'id': 'cob-1',
            'fatura_id': faturaId,
            'casa_id': 'casa-1',
            'valor_agua_centavos': 6800,
            'valor_esgoto_centavos': 5200,
            'valor_servico_basico_centavos': 3700,
            'valor_luz_centavos': 454,
            'valor_cond_centavos': 1500,
            'valor_quiosque_centavos': 0,
            'valor_juros_centavos': 0,
            'valor_debitos_centavos': 0,
            'valor_total_centavos': 17654,
            'status': 'pendente',
          },
          {
            'id': 'cob-2',
            'fatura_id': faturaId,
            'casa_id': 'casa-2',
            'valor_agua_centavos': 7100,
            'valor_esgoto_centavos': 5200,
            'valor_servico_basico_centavos': 3700,
            'valor_luz_centavos': 454,
            'valor_cond_centavos': 1500,
            'valor_quiosque_centavos': 0,
            'valor_juros_centavos': 0,
            'valor_debitos_centavos': 0,
            'valor_total_centavos': 17954,
            'status': 'pago',
          },
        ];

        when(() => db.query('cobrancas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final cobrancas =
            await repository.buscarCobrancasPorFatura(faturaId);

        expect(cobrancas.length, 2);
        expect(cobrancas[0].status, StatusCobranca.pendente);
        expect(cobrancas[1].status, StatusCobranca.pago);
      });

      test('retorna lista vazia', () async {
        when(() => db.query('cobrancas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final cobrancas =
            await repository.buscarCobrancasPorFatura(faturaId);
        expect(cobrancas, isEmpty);
      });
    });

    group('buscarCobrancaCasa', () {
      test('retorna cobrança específica', () async {
        final rows = [
          {
            'id': 'cob-1',
            'fatura_id': faturaId,
            'casa_id': casaId,
            'valor_agua_centavos': 7100,
            'valor_esgoto_centavos': 5200,
            'valor_servico_basico_centavos': 3700,
            'valor_luz_centavos': 454,
            'valor_cond_centavos': 1500,
            'valor_quiosque_centavos': 0,
            'valor_juros_centavos': 0,
            'valor_debitos_centavos': 0,
            'valor_total_centavos': 17954,
            'status': 'pendente',
          },
        ];

        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => rows);

        final found =
            await repository.buscarCobrancaCasa(casaId, mesAno);

        expect(found, isNotNull);
        expect(found!.valorAgua, 7100);
        expect(found.valorTotal, 17954);
      });

      test('retorna null quando não existe', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => []);

        final result =
            await repository.buscarCobrancaCasa(casaId, mesAno);
        expect(result, isNull);
      });
    });

    group('atualizarStatus', () {
      test('atualiza para pago', () async {
        when(() => db.update('cobrancas', {'status': 'pago'},
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => 1);

        await repository.atualizarStatus(
            'cob-1', StatusCobranca.pago);

        verify(() => db.update('cobrancas', {'status': 'pago'},
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'))).called(1);
      });

      test('atualiza para inadimplente', () async {
        when(() => db.update('cobrancas', {'status': 'inadimplente'},
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => 1);

        await repository.atualizarStatus(
            'cob-1', StatusCobranca.inadimplente);

        verify(() =>
                db.update('cobrancas', {'status': 'inadimplente'},
                    where: any(named: 'where'),
                    whereArgs: any(named: 'whereArgs')))
            .called(1);
      });
    });

    group('buscarInadimplentesAnterior', () {
      test('conta inadimplentes do mês anterior', () async {
        final rows = [
          {'total': 3},
        ];

        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => rows);

        final count = await repository.buscarInadimplentesAnterior('2026-04');
        expect(count, 3);
      });

      test('retorna 0 quando nenhum inadimplente no mês anterior', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => [{'total': 0}]);

        final count = await repository.buscarInadimplentesAnterior('2026-04');
        expect(count, 0);
      });

      test('calcula mês anterior corretamente (virada de ano)', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => [{'total': 2}]);

        // Janeiro 2026 → busca dezembro 2025
        final count = await repository.buscarInadimplentesAnterior('2026-01');
        expect(count, 2);

        // Valida que a query foi chamada com formato correto (2025-12)
        verify(() => db.rawQuery(any(), any())).called(1);
      });
    });

    group('marcarInadimplentesPorVencimento', () {
      test('marca como inadimplente cobranças pendentes com vencimento passado', () async {
        when(() => db.rawUpdate(any(), any()))
            .thenAnswer((_) async => 3); // 3 cobranças atualizadas

        await repository.marcarInadimplentesPorVencimento('2026-04');

        // Valida que rawUpdate foi chamado com a query corrigida
        verify(() => db.rawUpdate(
          any(
            that: contains('conta_corsan'),
          ),
          any(),
        )).called(1);
      });

      test('usa DATE() para comparar apenas a data de vencimento, sem hora', () async {
        when(() => db.rawUpdate(any(), any()))
            .thenAnswer((_) async => 1);

        await repository.marcarInadimplentesPorVencimento('2026-04');

        // Verifica que a query usa DATE para comparação sem hora
        verify(() => db.rawUpdate(
          any(
            that: contains("DATE(cc.vencimento)"),
          ),
          any(),
        )).called(1);
      });

      test('calcula mês anterior corretamente para query de inadimplência', () async {
        when(() => db.rawUpdate(any(), any()))
            .thenAnswer((_) async => 1);

        // Chamada para abril 2026 deve buscar inadimplentes de março 2026
        await repository.marcarInadimplentesPorVencimento('2026-04');

        // Valida que query foi executada e está buscando mês anterior
        verify(() => db.rawUpdate(any(), any())).called(1);
      });

      test('calcula mês anterior corretamente na virada de ano', () async {
        when(() => db.rawUpdate(any(), any()))
            .thenAnswer((_) async => 2);

        // Janeiro 2026 → busca dezembro 2025
        await repository.marcarInadimplentesPorVencimento('2026-01');

        verify(() => db.rawUpdate(any(), any())).called(1);
      });
    });
  });
}
