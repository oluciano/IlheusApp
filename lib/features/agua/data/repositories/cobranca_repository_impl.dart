import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';

class CobrancaDataSource {
  final Database db;
  CobrancaDataSource(this.db);
}

class CobrancaRepositoryImpl implements CobrancaRepository {
  final CobrancaDataSource dataSource;
  final _uuid = const Uuid();

  CobrancaRepositoryImpl(this.dataSource);

  @override
  Future<void> salvarCobranca(Cobranca cobranca) async {
    final db = dataSource.db;
    final entity = cobranca.id.isNotEmpty
        ? cobranca
        : cobranca.copyWith(id: _uuid.v4());
    await db.insert(
      'cobrancas',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Cobranca>> buscarCobrancasPorFatura(String faturaId) async {
    final db = dataSource.db;
    final result = await db.query(
      'cobrancas',
      where: 'fatura_id = ?',
      whereArgs: [faturaId],
      orderBy: 'casa_id ASC',
    );
    return result.map(Cobranca.fromMap).toList();
  }

  @override
  Future<Cobranca?> buscarCobrancaCasa(String casaId, String mesAno) async {
    final db = dataSource.db;
    final result = await db.rawQuery(
      '''
      SELECT c.* FROM cobrancas c
      INNER JOIN fatura_calculada f ON f.id = c.fatura_id
      WHERE c.casa_id = ? AND f.mes_ano = ?
      ''',
      [casaId, mesAno],
    );
    if (result.isEmpty) return null;
    return Cobranca.fromMap(result.first);
  }

  @override
  Future<void> atualizarStatus(
    String cobrancaId,
    StatusCobranca status,
  ) async {
    final db = dataSource.db;
    await db.update(
      'cobrancas',
      {'status': status.name},
      where: 'id = ?',
      whereArgs: [cobrancaId],
    );
  }

  @override
  Future<int> buscarInadimplentesAnterior(String mesAtual) async {
    final db = dataSource.db;

    // Calcula o mês anterior (YYYY-MM)
    final partes = mesAtual.split('-');
    int ano = int.parse(partes[0]);
    int mes = int.parse(partes[1]);

    if (mes == 1) {
      mes = 12;
      ano--;
    } else {
      mes--;
    }

    final mesAnterior = '$ano-${mes.toString().padLeft(2, '0')}';

    // Conta quantas casas ficaram inadimplentes no mês anterior
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as total
      FROM cobrancas c
      INNER JOIN fatura_calculada f ON f.id = c.fatura_id
      WHERE f.mes_ano = ? AND c.status = ?
      ''',
      [mesAnterior, StatusCobranca.inadimplente.name],
    );

    if (result.isEmpty) return 0;
    return result.first['total'] as int? ?? 0;
  }
}
