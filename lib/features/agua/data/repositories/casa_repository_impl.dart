import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';

class CasaDataSource {
  final Database db;
  CasaDataSource(this.db);
}

class CasaRepositoryImpl implements CasaRepository {
  final CasaDataSource dataSource;

  CasaRepositoryImpl(this.dataSource);

  @override
  Future<void> salvarCasa(Casa casa) async {
    final db = dataSource.db;
    await db.insert(
      'casas',
      casa.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Casa>> buscarTodas() async {
    final db = dataSource.db;
    final result = await db.query(
      'casas',
      orderBy: 'numero ASC',
    );
    return result.map(Casa.fromMap).toList();
  }

  @override
  Future<Casa?> buscarPorNumero(int numero) async {
    final db = dataSource.db;
    final result = await db.query(
      'casas',
      where: 'numero = ?',
      whereArgs: [numero],
    );
    if (result.isEmpty) return null;
    return Casa.fromMap(result.first);
  }

  @override
  Future<List<Casa>> buscarAtivas() async {
    final db = dataSource.db;
    final result = await db.query(
      'casas',
      where: 'ativa = ?',
      whereArgs: [1],
      orderBy: 'numero ASC',
    );
    return result.map(Casa.fromMap).toList();
  }

  @override
  Future<void> atualizarIsencao({
    required String casaId,
    required bool isento,
  }) async {
    final db = dataSource.db;
    await db.update(
      'casas',
      {'isento': isento ? 1 : 0},
      where: 'id = ?',
      whereArgs: [casaId],
    );
  }

  @override
  Future<void> atualizarAdministrador({
    required String casaId,
    required bool ehAdministrador,
  }) async {
    final db = dataSource.db;
    await db.update(
      'casas',
      {'eh_administrador': ehAdministrador ? 1 : 0},
      where: 'id = ?',
      whereArgs: [casaId],
    );
  }
}
