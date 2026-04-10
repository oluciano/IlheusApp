import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';
import 'package:ilheus_app/features/agua/domain/repositories/evento_uso_quiosque_repository.dart';

class EventoUsoQuiosqueDataSource {
  final Database db;
  EventoUsoQuiosqueDataSource(this.db);
}

class EventoUsoQuiosqueRepositoryImpl
    implements EventoUsoQuiosqueRepository {
  final EventoUsoQuiosqueDataSource dataSource;

  EventoUsoQuiosqueRepositoryImpl(this.dataSource);

  @override
  Future<void> salvarEvento(EventoUsoQuiosque evento) async {
    final db = dataSource.db;
    await db.insert(
      'evento_uso_quiosque',
      evento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<EventoUsoQuiosque?> buscarPorMes(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'evento_uso_quiosque',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    if (result.isEmpty) return null;
    return EventoUsoQuiosque.fromMap(result.first);
  }
}
