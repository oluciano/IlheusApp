import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/pagamento_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/pagamento.dart';
import 'package:ilheus_app/features/agua/domain/repositories/pagamento_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakePagamentoDataSource implements PagamentoDataSource {
  @override
  final Database db;
  FakePagamentoDataSource(this.db);
}

void main() {
  group('PagamentoRepository', () {
    late PagamentoRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = PagamentoRepositoryImpl(FakePagamentoDataSource(db));
    });

    final cobrancaId = 'cob-1';

    group('registrarPagamento', () {
      test('insere pagamento no banco', () async {
        final pagamento = Pagamento(
          id: const Uuid().v4(),
          cobrancaId: cobrancaId,
          dataPagamento: DateTime(2026, 4, 10),
          valorPagoCentavos: 17654,
        );

        when(() => db.insert('pagamentos', pagamento.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.registrarPagamento(pagamento);

        verify(() => db.insert('pagamentos', pagamento.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });
    });

    group('buscarPagamentosPorCobranca', () {
      test('retorna múltiplos pagamentos ordenados por data', () async {
        final rows = [
          {
            'id': 'pag-1',
            'cobranca_id': cobrancaId,
            'data_pagamento': '2026-04-05T10:00:00.000',
            'valor_pago_centavos': 10000,
          },
          {
            'id': 'pag-2',
            'cobranca_id': cobrancaId,
            'data_pagamento': '2026-04-10T14:30:00.000',
            'valor_pago_centavos': 7654,
          },
        ];

        when(() => db.query('pagamentos',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final pagamentos =
            await repository.buscarPagamentosPorCobranca(cobrancaId);

        expect(pagamentos.length, 2);
        expect(pagamentos[0].valorPagoCentavos, 10000);
        expect(pagamentos[1].valorPagoCentavos, 7654);
        expect(pagamentos[0].dataPagamento.day, 5);
        expect(pagamentos[1].dataPagamento.day, 10);
      });

      test('retorna lista vazia', () async {
        when(() => db.query('pagamentos',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final pagamentos =
            await repository.buscarPagamentosPorCobranca(cobrancaId);
        expect(pagamentos, isEmpty);
      });
    });
  });
}
