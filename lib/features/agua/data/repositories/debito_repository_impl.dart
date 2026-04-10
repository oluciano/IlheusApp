import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/status_debito.dart';
import 'package:ilheus_app/features/agua/domain/repositories/debito_repository.dart';

class DebitoDataSource {
  final Database db;
  DebitoDataSource(this.db);
}

class DebitoRepositoryImpl implements DebitoRepository {
  final DebitoDataSource dataSource;

  DebitoRepositoryImpl(this.dataSource);

  @override
  Future<void> salvarDebito(Debito debito) async {
    final db = dataSource.db;
    await db.insert(
      'debitos',
      debito.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Debito>> buscarDebitosAbertos(String casaId) async {
    final db = dataSource.db;
    final result = await db.query(
      'debitos',
      where: 'casa_id = ? AND status = ?',
      whereArgs: [casaId, StatusDebito.aberto.name],
      orderBy: 'mes_ano_origem ASC',
    );
    return result.map(Debito.fromMap).toList();
  }

  @override
  Future<void> quitar(String debitoId, DateTime dataQuitacao) async {
    final db = dataSource.db;
    await db.update(
      'debitos',
      {
        'status': StatusDebito.quitado.name,
        'data_quitacao': dataQuitacao.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debitoId],
    );
  }
}
