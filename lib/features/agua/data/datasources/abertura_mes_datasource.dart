import 'package:sqflite/sqflite.dart';

class AberturaMesDataSource {
  final Database db;

  AberturaMesDataSource(this.db);

  Future<void> createTables() async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS conta_corsan (
        id TEXT PRIMARY KEY,
        mes_ano TEXT NOT NULL UNIQUE,
        leitura_anterior_m3 INTEGER NOT NULL DEFAULT 0,
        leitura_atual_m3 INTEGER NOT NULL DEFAULT 0,
        valor_agua_centavos INTEGER NOT NULL DEFAULT 0,
        valor_esgoto_centavos INTEGER NOT NULL DEFAULT 0,
        valor_servico_basico_centavos INTEGER NOT NULL DEFAULT 0,
        valor_juros_centavos INTEGER,
        vencimento TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS conta_luz (
        id TEXT PRIMARY KEY,
        mes_ano TEXT NOT NULL UNIQUE,
        valor_total_centavos INTEGER NOT NULL DEFAULT 0,
        valor_juros_centavos INTEGER,
        vencimento TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS configuracao_mes (
        id TEXT PRIMARY KEY,
        mes_ano TEXT NOT NULL UNIQUE,
        valor_cond_centavos INTEGER NOT NULL DEFAULT 0,
        modelo_juros TEXT NOT NULL DEFAULT 'igualitario',
        componente_agua_ativo INTEGER NOT NULL DEFAULT 1,
        componente_esgoto_ativo INTEGER NOT NULL DEFAULT 1,
        componente_servico_basico_ativo INTEGER NOT NULL DEFAULT 1,
        componente_luz_ativo INTEGER NOT NULL DEFAULT 1,
        componente_cond_ativo INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS despesas_extras (
        id TEXT PRIMARY KEY,
        mes_ano TEXT NOT NULL,
        descricao TEXT NOT NULL,
        valor_total_centavos INTEGER NOT NULL
      )
    ''');
  }
}
