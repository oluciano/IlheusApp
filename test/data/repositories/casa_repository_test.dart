import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/data/datasources/abertura_mes_datasource.dart';
import 'package:ilheus_app/features/agua/data/repositories/casa_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  group('CasaRepository', () {
    late CasaRepositoryImpl repository;
    late MockDatabase db;

    setUpAll(() {
      registerFallbackValue(
        <String, dynamic>{},
      );
    });

    setUp(() {
      db = MockDatabase();
      final dataSource = CasaDataSource(db);
      repository = CasaRepositoryImpl(dataSource);
    });

    group('salvarCasa', () {
      test('insere casa no banco com sucesso', () async {
        when(() => db.insert(
              'casas',
              any(),
              conflictAlgorithm: any(named: 'conflictAlgorithm'),
            )).thenAnswer((_) async => 1);

        await repository.salvarCasa(Casa(
          id: 'casa-1',
          numero: 1,
          ativa: true,
          isento: false,
          ehAdministrador: false,
        ));

        verify(() => db.insert(
              'casas',
              any(that: containsPair('numero', 1)),
              conflictAlgorithm: any(named: 'conflictAlgorithm'),
            )).called(1);
      });

      test('insere casa quiiosque (numero 23)', () async {
        when(() => db.insert(
              'casas',
              any(),
              conflictAlgorithm: any(named: 'conflictAlgorithm'),
            )).thenAnswer((_) async => 1);

        await repository.salvarCasa(Casa(
          id: 'casa-23',
          numero: 23,
        ));

        verify(() => db.insert(
              'casas',
              any(that: containsPair('numero', 23)),
              conflictAlgorithm: any(named: 'conflictAlgorithm'),
            )).called(1);
      });
    });

    group('buscarTodas', () {
      test('retorna todas as casas ordenadas por numero', () async {
        final rows = [
          {
            'id': 'casa-1',
            'numero': 1,
            'ativa': 1,
            'isento': 0,
            'eh_administrador': 0,
          },
          {
            'id': 'casa-2',
            'numero': 2,
            'ativa': 1,
            'isento': 0,
            'eh_administrador': 1,
          },
          {
            'id': 'casa-23',
            'numero': 23,
            'ativa': 1,
            'isento': 0,
            'eh_administrador': 0,
          },
        ];

        when(() => db.query('casas', orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final casas = await repository.buscarTodas();

        expect(casas.length, 3);
        expect(casas[0].numero, 1);
        expect(casas[1].numero, 2);
        expect(casas[1].ehAdministrador, isTrue);
        expect(casas[2].isQuiosque, isTrue);
      });

      test('retorna lista vazia quando nao ha casas', () async {
        when(() => db.query('casas', orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final casas = await repository.buscarTodas();
        expect(casas, isEmpty);
      });
    });

    group('buscarPorNumero', () {
      test('retorna casa com numero especifico', () async {
        final rows = [
          {
            'id': 'casa-7',
            'numero': 7,
            'ativa': 1,
            'isento': 0,
            'eh_administrador': 0,
          },
        ];

        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => rows);

        final casa = await repository.buscarPorNumero(7);

        expect(casa, isNotNull);
        expect(casa!.numero, 7);
        expect(casa.isento, isFalse);
      });

      test('retorna null quando casa nao existe', () async {
        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => []);

        final casa = await repository.buscarPorNumero(99);
        expect(casa, isNull);
      });
    });

    group('buscarAtivas', () {
      test('retorna somente casas ativas', () async {
        final rows = [
          {
            'id': 'casa-1',
            'numero': 1,
            'ativa': 1,
            'isento': 0,
            'eh_administrador': 0,
          },
          {
            'id': 'casa-3',
            'numero': 3,
            'ativa': 1,
            'isento': 1,
            'eh_administrador': 0,
          },
        ];

        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final casas = await repository.buscarAtivas();

        expect(casas.length, 2);
        expect(casas.every((c) => c.ativa), isTrue);
        expect(casas[1].isento, isTrue);
      });

      test('retorna lista vazia quando nao ha casas ativas', () async {
        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final casas = await repository.buscarAtivas();
        expect(casas, isEmpty);
      });
    });

    group('atualizarIsencao', () {
      test('atualiza flag isento para true', () async {
        when(() => db.update(
              'casas',
              any(),
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenAnswer((_) async => 1);

        await repository.atualizarIsencao(
          casaId: 'casa-8',
          isento: true,
        );

        verify(() => db.update(
              'casas',
              any(that: containsPair('isento', 1)),
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).called(1);
      });

      test('remove isencao (false)', () async {
        when(() => db.update(
              'casas',
              any(),
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenAnswer((_) async => 1);

        await repository.atualizarIsencao(
          casaId: 'casa-8',
          isento: false,
        );

        verify(() => db.update(
              'casas',
              any(that: containsPair('isento', 0)),
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).called(1);
      });
    });

    group('atualizarAdministrador', () {
      test('atualiza flag eh_administrador para true', () async {
        when(() => db.update(
              'casas',
              any(),
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).thenAnswer((_) async => 1);

        await repository.atualizarAdministrador(
          casaId: 'casa-2',
          ehAdministrador: true,
        );

        verify(() => db.update(
              'casas',
              any(that: containsPair('eh_administrador', 1)),
              where: any(named: 'where'),
              whereArgs: any(named: 'whereArgs'),
            )).called(1);
      });
    });
  });
}
