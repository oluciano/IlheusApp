import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';

class FaturaCalculadaDataSource {
  final Database db;
  FaturaCalculadaDataSource(this.db);
}

class FaturaCalculadaRepositoryImpl
    implements FaturaCalculadaRepository {
  final FaturaCalculadaDataSource dataSource;
  final _uuid = const Uuid();

  FaturaCalculadaRepositoryImpl(this.dataSource);

  @override
  Future<void> salvarFatura(FaturaCalculada fatura) async {
    final db = dataSource.db;
    final entity = fatura.id.isNotEmpty
        ? fatura
        : fatura.copyWith(id: _uuid.v4());
    await db.insert(
      'fatura_calculada',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<FaturaCalculada?> buscarPorMes(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'fatura_calculada',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    if (result.isEmpty) return null;
    return FaturaCalculada.fromMap(result.first);
  }

  @override
  Future<void> atualizarStatus(
    String faturaId,
    StatusFatura status,
  ) async {
    final db = dataSource.db;
    await db.update(
      'fatura_calculada',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [faturaId],
    );
  }

  @override
  Future<List<FaturaCalculada>> listarTodas() async {
    final db = dataSource.db;
    final result = await db.query(
      'fatura_calculada',
      orderBy: 'mes_ano DESC',
    );
    return result.map(FaturaCalculada.fromMap).toList();
  }
}
