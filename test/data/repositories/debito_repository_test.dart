import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/debito_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/status_debito.dart';
import 'package:ilheus_app/features/agua/domain/repositories/debito_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakeDebitoDataSource implements DebitoDataSource {
  @override
  final Database db;
  FakeDebitoDataSource(this.db);
}

void main() {
  group('DebitoRepository', () {
    late DebitoRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = DebitoRepositoryImpl(FakeDebitoDataSource(db));
    });

    final casaId = 'casa-1';

    group('salvarDebito', () {
      test('insere débito no banco', () async {
        final debito = Debito(
          id: const Uuid().v4(),
          cobrancaId: 'cob-1',
          casaId: casaId,
          mesAnoOrigem: '03/2026',
          valorCentavos: 17654,
        );

        when(() => db.insert('debitos', debito.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarDebito(debito);

        verify(() => db.insert('debitos', debito.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });
    });

    group('buscarDebitosAbertos', () {
      test('retorna só débitos abertos', () async {
        final rows = [
          {
            'id': 'deb-1',
            'cobranca_id': 'cob-1',
            'casa_id': casaId,
            'mes_ano_origem': '02/2026',
            'valor_centavos': 17000,
            'status': 'aberto',
            'data_quitacao': null,
          },
        ];

        when(() => db.query('debitos',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final abertos = await repository.buscarDebitosAbertos(casaId);

        expect(abertos.length, 1);
        expect(abertos.first.valorCentavos, 17000);
        expect(abertos.first.isAberto, isTrue);
        expect(abertos.first.isQuitado, isFalse);
      });

      test('retorna lista vazia sem débitos', () async {
        when(() => db.query('debitos',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final abertos = await repository.buscarDebitosAbertos(casaId);
        expect(abertos, isEmpty);
      });
    });

    group('quitar', () {
      test('atualiza status e registra data de quitação', () async {
        final debitoId = 'deb-1';
        final dataQuitacao = DateTime(2026, 5, 20);

        late Map<String, dynamic> updateMap;
        when(() => db.update('debitos', any(),
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((inv) {
          updateMap = inv.positionalArguments[1] as Map<String, dynamic>;
          return Future.value(1);
        });

        await repository.quitar(debitoId, dataQuitacao);

        expect(updateMap['status'], StatusDebito.quitado.name);
        expect(updateMap['data_quitacao'], isNotNull);
      });
    });
  });
}
