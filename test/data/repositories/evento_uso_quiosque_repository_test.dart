import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/repositories/evento_uso_quiosque_repository_impl.dart';
import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';
import 'package:ilheus_app/features/agua/domain/repositories/evento_uso_quiosque_repository.dart';

class MockDatabase extends Mock implements Database {}

class FakeEventoUsoQuiosqueDataSource
    implements EventoUsoQuiosqueDataSource {
  @override
  final Database db;
  FakeEventoUsoQuiosqueDataSource(this.db);
}

void main() {
  group('EventoUsoQuiosqueRepository', () {
    late EventoUsoQuiosqueRepository repository;
    late MockDatabase db;

    setUp(() {
      db = MockDatabase();
      repository = EventoUsoQuiosqueRepositoryImpl(
          FakeEventoUsoQuiosqueDataSource(db));
    });

    final mesAno = '04/2026';

    group('salvarEvento', () {
      test('insere evento de uso do quiosque com casas', () async {
        final evento = EventoUsoQuiosque(
          id: const Uuid().v4(),
          mesAno: mesAno,
          casaIds: ['casa-1', 'casa-5', 'casa-12'],
        );

        when(() => db.insert('evento_uso_quiosque', evento.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarEvento(evento);

        verify(() => db.insert('evento_uso_quiosque', evento.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });

      test('insere evento sem casas (lista vazia)', () async {
        final evento = EventoUsoQuiosque(
          id: const Uuid().v4(),
          mesAno: mesAno,
          casaIds: [],
        );

        when(() => db.insert('evento_uso_quiosque', evento.toMap(),
                conflictAlgorithm: any(named: 'conflictAlgorithm')))
            .thenAnswer((_) async => 1);

        await repository.salvarEvento(evento);

        verify(() => db.insert('evento_uso_quiosque', evento.toMap(),
            conflictAlgorithm: any(named: 'conflictAlgorithm'))).called(1);
      });
    });

    group('buscarPorMes', () {
      test('retorna evento do mes informado', () async {
        final rows = [
          {
            'id': 'evt-1',
            'mes_ano': mesAno,
            'casa_ids': '["casa-1","casa-3","casa-7"]',
          },
        ];

        when(() => db.query('evento_uso_quiosque',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => rows);

        final evento = await repository.buscarPorMes(mesAno);

        expect(evento, isNotNull);
        expect(evento!.mesAno, mesAno);
        expect(evento.casaIds.length, 3);
        expect(evento.casaIds, contains('casa-3'));
        expect(evento.qtdCasasQueUsaram, 3);
      });

      test('retorna null quando nao ha evento para o mes', () async {
        when(() => db.query('evento_uso_quiosque',
                where: any(named: 'where'),
                whereArgs: any(named: 'whereArgs')))
            .thenAnswer((_) async => []);

        final evento = await repository.buscarPorMes(mesAno);
        expect(evento, isNull);
      });
    });
  });
}
