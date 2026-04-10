import 'package:sqflite/sqflite.dart';

import 'package:ilheus_app/features/agua/data/datasources/schema_v2.sql.dart'
    as schema_v2;

class AberturaMesDataSource {
  final Database db;

  AberturaMesDataSource(this.db);

  Future<void> createTables() async {
    await db.execute(schema_v2.casas);
    await db.execute(schema_v2.contaCorsan);
    await db.execute(schema_v2.contaLuz);
    await db.execute(schema_v2.configuracaoMes);
    await db.execute(schema_v2.leituras);
    await db.execute(schema_v2.eventoUsoQuiosque);
    await db.execute(schema_v2.faturaCalculada);
    await db.execute(schema_v2.cobrancas);
    await db.execute(schema_v2.pagamentos);
    await db.execute(schema_v2.debitos);
    await db.execute(schema_v2.faturaUpdatedAtTrigger);
  }

  Future<void> upgradeFromV1() async {
    await db.execute(schema_v2.casas);
    await db.execute(schema_v2.leituras);
    await db.execute(schema_v2.eventoUsoQuiosque);
    await db.execute(schema_v2.faturaCalculada);
    await db.execute(schema_v2.cobrancas);
    await db.execute(schema_v2.pagamentos);
    await db.execute(schema_v2.debitos);
    await db.execute(schema_v2.faturaUpdatedAtTrigger);
  }
}
