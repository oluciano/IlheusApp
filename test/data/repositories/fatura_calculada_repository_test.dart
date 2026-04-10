import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/fatura_calculada_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakeFaturaCalculadaDataSource
    implements FaturaCalculadaDataSource {
  @override
  final Database db;
  FakeFaturaCalculadaDataSource(this.db);
}

void main() {
  group('FaturaCalculadaRepository', () {
    late FaturaCalculadaRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = FaturaCalculadaRepositoryImpl(
          FakeFaturaCalculadaDataSource(db));
    });

    group('salvarFatura', () {
      test('insere fatura com ID existente', () async {
        final fatura = FaturaCalculada(
          id: 'fatura-1',
          mesAno: '04/2026',
          status: StatusFatura.rascunho,
        );

        when(() => db.insert('fatura_calculada', fatura.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarFatura(fatura);

        verify(() => db.insert('fatura_calculada', fatura.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });

      test('gera UUID para fatura sem ID', () async {
        final fatura = FaturaCalculada(
          id: '',
          mesAno: '04/2026',
          status: StatusFatura.rascunho,
        );

        late Map<String, dynamic> insertedMap;
        when(() => db.insert('fatura_calculada', any(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((inv) {
          insertedMap = inv.positionalArguments[1] as Map<String, dynamic>;
          return Future.value(1);
        });

        await repository.salvarFatura(fatura);

        expect(insertedMap['id'], isNotNull);
        expect(insertedMap['id'], isNotEmpty);
      });

      test('insere fatura com status publicado', () async {
        final fatura = FaturaCalculada(
          id: 'fatura-2',
          mesAno: '03/2026',
          status: StatusFatura.publicado,
        );

        when(() => db.insert('fatura_calculada', fatura.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarFatura(fatura);

        verify(() => db.insert('fatura_calculada', fatura.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });
    });

    group('buscarPorMes', () {
      test('retorna fatura do mes informado', () async {
        final rows = [
          {
            'id': 'fatura-1',
            'mes_ano': '04/2026',
            'status': 'publicado',
          },
        ];

        when(() => db.query('fatura_calculada',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => rows);

        final fatura = await repository.buscarPorMes('04/2026');

        expect(fatura, isNotNull);
        expect(fatura!.isPublicado, isTrue);
        expect(fatura.isRascunho, isFalse);
      });

      test('retorna fatura em estado rascunho', () async {
        final rows = [
          {
            'id': 'fatura-2',
            'mes_ano': '05/2026',
            'status': 'rascunho',
          },
        ];

        when(() => db.query('fatura_calculada',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => rows);

        final fatura = await repository.buscarPorMes('05/2026');

        expect(fatura, isNotNull);
        expect(fatura!.isRascunho, isTrue);
        expect(fatura.isPublicado, isFalse);
      });

      test('retorna null quando nao ha fatura para o mes', () async {
        when(() => db.query('fatura_calculada',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => []);

        final fatura = await repository.buscarPorMes('04/2026');
        expect(fatura, isNull);
      });
    });

    group('atualizarStatus', () {
      test('altera status de rascunho para publicado', () async {
        when(() => db.update('fatura_calculada', {'status': 'publicado'},
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => 1);

        await repository.atualizarStatus(
            'fatura-1', StatusFatura.publicado);

        verify(() => db.update('fatura_calculada', {'status': 'publicado'},
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'))).called(1);
      });

      test('reverte status de publicado para rascunho', () async {
        when(() => db.update('fatura_calculada', {'status': 'rascunho'},
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => 1);

        await repository.atualizarStatus(
            'fatura-1', StatusFatura.rascunho);

        verify(() => db.update('fatura_calculada', {'status': 'rascunho'},
            where: any(named: 'where'),
            whereArgs: any(named: 'whereArgs'))).called(1);
      });
    });

    group('listarTodas', () {
      test('retorna todas as faturas ordenadas por mes decrescente',
          () async {
        final rows = [
          {
            'id': 'fatura-3',
            'mes_ano': '04/2026',
            'status': 'publicado',
          },
          {
            'id': 'fatura-2',
            'mes_ano': '03/2026',
            'status': 'publicado',
          },
          {
            'id': 'fatura-1',
            'mes_ano': '02/2026',
            'status': 'rascunho',
          },
        ];

        when(() => db.query('fatura_calculada',
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final faturas = await repository.listarTodas();

        expect(faturas.length, 3);
        expect(faturas[0].mesAno, '04/2026');
        expect(faturas[0].isPublicado, isTrue);
        expect(faturas[1].mesAno, '03/2026');
        expect(faturas[2].mesAno, '02/2026');
        expect(faturas[2].isRascunho, isTrue);
      });

      test('retorna lista vazia quando nao ha faturas', () async {
        when(() => db.query('fatura_calculada',
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final faturas = await repository.listarTodas();
        expect(faturas, isEmpty);
      });
    });
  });
}
