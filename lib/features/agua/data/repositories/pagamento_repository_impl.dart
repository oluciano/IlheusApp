import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/domain/models/pagamento.dart';
import 'package:ilheus_app/features/agua/domain/repositories/pagamento_repository.dart';

class PagamentoDataSource {
  final Database db;
  PagamentoDataSource(this.db);
}

class PagamentoRepositoryImpl implements PagamentoRepository {
  final PagamentoDataSource dataSource;

  PagamentoRepositoryImpl(this.dataSource);

  @override
  Future<void> registrarPagamento(Pagamento pagamento) async {
    final db = dataSource.db;
    await db.insert(
      'pagamentos',
      pagamento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Pagamento>> buscarPagamentosPorCobranca(
    String cobrancaId,
  ) async {
    final db = dataSource.db;
    final result = await db.query(
      'pagamentos',
      where: 'cobranca_id = ?',
      whereArgs: [cobrancaId],
      orderBy: 'data_pagamento ASC',
    );
    return result.map(Pagamento.fromMap).toList();
  }
}
