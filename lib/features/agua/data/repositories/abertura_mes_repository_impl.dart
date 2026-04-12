import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:ilheus_app/features/agua/data/datasources/abertura_mes_datasource.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';

class AberturaMesRepositoryImpl implements AberturaMesRepository {
  final AberturaMesDataSource dataSource;
  final _uuid = const Uuid();

  AberturaMesRepositoryImpl(this.dataSource);

  @override
  Future<ContaCorsan?> getContaCorsan(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'conta_corsan',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    if (result.isEmpty) return null;
    return ContaCorsan.fromMap(result.first);
  }

  @override
  Future<void> saveContaCorsan(ContaCorsan conta) async {
    final db = dataSource.db;
    final entity = conta.id != null ? conta : conta.copyWith(id: _uuid.v4());
    await db.insert(
      'conta_corsan',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<ContaLuz?> getContaLuz(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'conta_luz',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    if (result.isEmpty) return null;
    return ContaLuz.fromMap(result.first);
  }

  @override
  Future<void> saveContaLuz(ContaLuz conta) async {
    final db = dataSource.db;
    final entity = conta.id != null ? conta : conta.copyWith(id: _uuid.v4());
    await db.insert(
      'conta_luz',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<ConfiguracaoMes?> getConfiguracaoMes(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'configuracao_mes',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    if (result.isEmpty) return null;
    return ConfiguracaoMes.fromMap(result.first);
  }

  @override
  Future<void> saveConfiguracaoMes(ConfiguracaoMes config) async {
    final db = dataSource.db;
    final entity = config.id != null ? config : config.copyWith(id: _uuid.v4());
    await db.insert(
      'configuracao_mes',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DespesaExtra>> getDespesasExtras(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'despesas_extras',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    return result.map(DespesaExtra.fromMap).toList();
  }

  @override
  Future<void> saveDespesaExtra(DespesaExtra despesa) async {
    final db = dataSource.db;
    final entity =
        despesa.id != null ? despesa : despesa.copyWith(id: _uuid.v4());
    await db.insert(
      'despesas_extras',
      entity.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteDespesaExtra(String id) async {
    final db = dataSource.db;
    await db.delete(
      'despesas_extras',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<bool> mesSalvo(String mesAno) async {
    final db = dataSource.db;
    final result = await db.query(
      'configuracao_mes',
      where: 'mes_ano = ?',
      whereArgs: [mesAno],
    );
    return result.isNotEmpty;
  }

  @override
  Future<List<String>> listarTodosMeses() async {
    final db = dataSource.db;
    // Ordena por ano/mês corretamente: converte MM/AAAA → AAAAMM para comparação
    final result = await db.rawQuery(
      '''
      SELECT mes_ano FROM configuracao_mes
      ORDER BY SUBSTR(mes_ano, 4, 4) DESC, SUBSTR(mes_ano, 1, 2) DESC
      ''',
    );
    return result.map((row) => row['mes_ano'] as String).toList();
  }

  @override
  Future<T> runInTransaction<T>(Future<T> Function() body) async {
    // Retorna a execução direta do corpo, sem o wrapper de transação do sqflite,
    // para evitar deadlocks causados pelo uso concorrente do objeto Database
    // sem passar o handle de transação (txn) para os repositórios internos.
    return await body();
  }
}
