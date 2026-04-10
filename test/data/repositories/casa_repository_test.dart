import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/casa_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakeCasaDataSource implements CasaDataSource {
  @override
  final Database db;
  FakeCasaDataSource(this.db);
}

void main() {
  group('CasaRepository', () {
    late CasaRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = CasaRepositoryImpl(FakeCasaDataSource(db));
    });

    group('salvarCasa', () {
      test('insere casa no banco com sucesso', () async {
        final casa = Casa(
          id: const Uuid().v4(),
          numero: 5,
        );

        when(() => db.insert('casas', casa.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarCasa(casa);

        verify(() => db.insert('casas', casa.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });

      test('insere casa quiiosque (numero 23)', () async {
        final casa = Casa(
          id: const Uuid().v4(),
          numero: 23,
        );

        when(() => db.insert('casas', casa.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarCasa(casa);

        verify(() => db.insert('casas', casa.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });
    });

    group('buscarTodas', () {
      test('retorna todas as casas ordenadas por numero', () async {
        final rows = [
          {
            'id': 'casa-1',
            'numero': 1,
            'ativa': 1,
            'isento_agua': 0,
            'isento_esgoto': 0,
            'isento_servico_basico': 0,
            'isento_luz': 0,
            'isento_cond': 0,
          },
          {
            'id': 'casa-2',
            'numero': 2,
            'ativa': 1,
            'isento_agua': 0,
            'isento_esgoto': 1,
            'isento_servico_basico': 0,
            'isento_luz': 0,
            'isento_cond': 0,
          },
          {
            'id': 'casa-3',
            'numero': 23,
            'ativa': 1,
            'isento_agua': 0,
            'isento_esgoto': 0,
            'isento_servico_basico': 0,
            'isento_luz': 0,
            'isento_cond': 0,
          },
        ];

        when(() => db.query('casas', orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final casas = await repository.buscarTodas();

        expect(casas.length, 3);
        expect(casas[0].numero, 1);
        expect(casas[1].numero, 2);
        expect(casas[1].isentoEsgoto, isTrue);
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
            'isento_agua': 0,
            'isento_esgoto': 0,
            'isento_servico_basico': 0,
            'isento_luz': 1,
            'isento_cond': 0,
          },
        ];

        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => rows);

        final casa = await repository.buscarPorNumero(7);

        expect(casa, isNotNull);
        expect(casa!.numero, 7);
        expect(casa.isentoLuz, isTrue);
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
            'isento_agua': 0,
            'isento_esgoto': 0,
            'isento_servico_basico': 0,
            'isento_luz': 0,
            'isento_cond': 0,
          },
          {
            'id': 'casa-3',
            'numero': 3,
            'ativa': 1,
            'isento_agua': 1,
            'isento_esgoto': 0,
            'isento_servico_basico': 0,
            'isento_luz': 0,
            'isento_cond': 0,
          },
        ];

        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => rows);

        final ativas = await repository.buscarAtivas();

        expect(ativas.length, 2);
        expect(ativas.every((c) => c.ativa), isTrue);
      });

      test('retorna lista vazia quando nao ha casas ativas', () async {
        when(() => db.query('casas',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs'),
                orderBy: any(named: 'orderBy')))
            .thenAnswer((_) async => []);

        final ativas = await repository.buscarAtivas();
        expect(ativas, isEmpty);
      });
    });

    group('atualizarIsencoes', () {
      test('atualiza todas as flags de isencao', () async {
        late Map<String, dynamic> updateMap;
        when(() => db.update('casas', any(),
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((inv) {
          updateMap = inv.positionalArguments[1] as Map<String, dynamic>;
          return Future.value(1);
        });

        await repository.atualizarIsencoes(
          casaId: 'casa-5',
          isentoAgua: true,
          isentoEsgoto: false,
          isentoServicoBasico: true,
          isentoLuz: false,
          isentoCond: true,
        );

        expect(updateMap['isento_agua'], 1);
        expect(updateMap['isento_esgoto'], 0);
        expect(updateMap['isento_servico_basico'], 1);
        expect(updateMap['isento_luz'], 0);
        expect(updateMap['isento_cond'], 1);
      });

      test('remove todas as isencoes quando flags sao false', () async {
        late Map<String, dynamic> updateMap;
        when(() => db.update('casas', any(),
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((inv) {
          updateMap = inv.positionalArguments[1] as Map<String, dynamic>;
          return Future.value(1);
        });

        await repository.atualizarIsencoes(
          casaId: 'casa-5',
          isentoAgua: false,
          isentoEsgoto: false,
          isentoServicoBasico: false,
          isentoLuz: false,
          isentoCond: false,
        );

        expect(updateMap['isento_agua'], 0);
        expect(updateMap['isento_esgoto'], 0);
        expect(updateMap['isento_servico_basico'], 0);
        expect(updateMap['isento_luz'], 0);
        expect(updateMap['isento_cond'], 0);
      });
    });
  });
}
