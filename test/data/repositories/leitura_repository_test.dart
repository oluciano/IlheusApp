import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/leitura_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakeLeituraDataSource implements LeituraDataSource {
  @override
  final Database db;
  FakeLeituraDataSource(this.db);
}

void main() {
  group('LeituraRepository', () {
    late LeituraRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = LeituraRepositoryImpl(FakeLeituraDataSource(db));
    });

    final casaId = 'casa-1';
    final mesAno = '04/2026';

    group('salvarLeitura', () {
      test('insere leitura no banco', () async {
        final leitura = Leitura(
          id: const Uuid().v4(),
          mesAno: mesAno,
          casaId: casaId,
          leituraAnteriorM3: 100,
          leituraAtualM3: 120,
        );

        when(() => db.insert('leituras', leitura.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarLeitura(leitura);

        verify(() => db.insert('leituras', leitura.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });
    });

    group('buscarLeiturasPorMes', () {
      test('retorna todas as leituras do mês', () async {
        final rows = [
          {
            'id': 'l1',
            'mes_ano': mesAno,
            'casa_id': 'casa-1',
            'leitura_anterior_m3': 100,
            'leitura_atual_m3': 110,
          },
          {
            'id': 'l2',
            'mes_ano': mesAno,
            'casa_id': 'casa-2',
            'leitura_anterior_m3': 200,
            'leitura_atual_m3': 215,
          },
        ];

        when(() => db.query('leituras',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final leituras = await repository.buscarLeiturasPorMes(mesAno);

        expect(leituras.length, 2);
        expect(leituras[0].casaId, 'casa-1');
        expect(leituras[0].consumoM3, 10);
        expect(leituras[1].consumoM3, 15);
      });

      test('retorna lista vazia quando não há leituras', () async {
        when(() => db.query('leituras',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final leituras = await repository.buscarLeiturasPorMes(mesAno);
        expect(leituras, isEmpty);
      });
    });

    group('buscarLeituraCasa', () {
      test('retorna leitura específica', () async {
        final rows = [
          {
            'id': 'l1',
            'mes_ano': mesAno,
            'casa_id': casaId,
            'leitura_anterior_m3': 200,
            'leitura_atual_m3': 235,
          },
        ];

        when(() => db.query('leituras',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => rows);

        final found = await repository.buscarLeituraCasa(casaId, mesAno);

        expect(found, isNotNull);
        expect(found!.leituraAtualM3, 235);
        expect(found.consumoM3, 35);
      });

      test('retorna null quando não existe', () async {
        when(() => db.query('leituras',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => []);

        final result =
            await repository.buscarLeituraCasa(casaId, mesAno);
        expect(result, isNull);
      });
    });

    group('verificarLeituraCompleta', () {
      test('retorna true com 22 casas lidas', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => [{'total': 22}]);

        final completa =
            await repository.verificarLeituraCompleta(mesAno);
        expect(completa, isTrue);
      });

      test('retorna true com mais de 22 casas', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => [{'total': 23}]);

        final completa =
            await repository.verificarLeituraCompleta(mesAno);
        expect(completa, isTrue);
      });

      test('retorna false com menos de 22 casas', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => [{'total': 10}]);

        final completa =
            await repository.verificarLeituraCompleta(mesAno);
        expect(completa, isFalse);
      });

      test('retorna false com zero casas', () async {
        when(() => db.rawQuery(any(), any()))
            .thenAnswer((_) async => [{'total': 0}]);

        final completa =
            await repository.verificarLeituraCompleta(mesAno);
        expect(completa, isFalse);
      });
    });
  });
}
