import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';

class LeituraDataSource {
  final Database db;
  LeituraDataSource(this.db);
}

class LeituraRepositoryImpl implements LeituraRepository {
  final LeituraDataSource dataSource;
  final _uuid = const Uuid();

  LeituraRepositoryImpl(this.dataSource);

  @override
  Future<void> salvarLeitura(Leitura leitura) async {
    final db = dataSource.db;
    await db.insert(
      'leituras',
      leitura.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Leitura>> buscarLeiturasPorMes(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'leituras',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
      orderBy: 'casa_id ASC',
    );
    return result.map(Leitura.fromMap).toList();
  }

  @override
  Future<Leitura?> buscarLeituraCasa(String casaId, String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'leituras',
      where: 'casa_id = ? AND mes_ano = ?',
      whereArgs: [casaId, mesAno],
    );
    if (result.isEmpty) return null;
    return Leitura.fromMap(result.first);
  }

  @override
  Future<bool> verificarLeituraCompleta(String mesAno) async {
    final db = dataSource.db;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(DISTINCT l.casa_id) as total
      FROM leituras l
      INNER JOIN casas c ON c.id = l.casa_id
      WHERE l.mes_ano = ? AND c.ativa = 1
      ''',
      [mesAno],
    );
    final totalLidas = result.first['total'] as int;
    return totalLidas >= 22;
  }

  @override
  Future<Leitura?> buscarUltimaLeitura(String casaId) async {
    final db = dataSource.db;
    final result = await db.query(
      'leituras',
      where: 'casa_id = ?',
      whereArgs: [casaId],
      orderBy: 'SUBSTR(mes_ano, 4, 4) DESC, SUBSTR(mes_ano, 1, 2) DESC',
      limit: 1,
    );
    if (result.isEmpty) return null;
    return Leitura.fromMap(result.first);
  }
}
