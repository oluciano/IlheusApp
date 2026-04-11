import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

// Importando o esquema oficial (simulado aqui para o script rodar isolado)
const List<String> schema = [
  '''CREATE TABLE IF NOT EXISTS casas (
    id TEXT PRIMARY KEY,
    numero INTEGER NOT NULL CHECK (numero >= 1 AND numero <= 23),
    ativa INTEGER NOT NULL DEFAULT 1,
    isento INTEGER NOT NULL DEFAULT 0,
    eh_administrador INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )''',
  '''CREATE TABLE IF NOT EXISTS conta_corsan (
    id TEXT PRIMARY KEY,
    mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
    leitura_anterior_m3 INTEGER NOT NULL DEFAULT 0,
    leitura_atual_m3 INTEGER NOT NULL DEFAULT 0,
    valor_agua_centavos INTEGER NOT NULL DEFAULT 0,
    valor_esgoto_centavos INTEGER NOT NULL DEFAULT 0,
    valor_servico_basico_centavos INTEGER NOT NULL DEFAULT 0,
    valor_juros_centavos INTEGER,
    vencimento TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )''',
  '''CREATE TABLE IF NOT EXISTS conta_luz (
    id TEXT PRIMARY KEY,
    mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
    valor_total_centavos INTEGER NOT NULL DEFAULT 0,
    valor_juros_centavos INTEGER,
    vencimento TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )''',
  '''CREATE TABLE IF NOT EXISTS configuracao_mes (
    id TEXT PRIMARY KEY,
    mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
    valor_cond_centavos INTEGER NOT NULL DEFAULT 0,
    modelo_juros TEXT NOT NULL DEFAULT 'igualitario'
      CHECK (modelo_juros IN ('igualitario', 'proporcional_dias')),
    componente_agua_ativo INTEGER NOT NULL DEFAULT 1,
    componente_esgoto_ativo INTEGER NOT NULL DEFAULT 1,
    componente_servico_basico_ativo INTEGER NOT NULL DEFAULT 1,
    componente_luz_ativo INTEGER NOT NULL DEFAULT 1,
    componente_cond_ativo INTEGER NOT NULL DEFAULT 1,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )''',
  '''CREATE TABLE IF NOT EXISTS leituras (
    id TEXT PRIMARY KEY,
    mes_ano TEXT NOT NULL CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
    casa_id TEXT NOT NULL,
    leitura_anterior_m3 INTEGER NOT NULL DEFAULT 0,
    leitura_atual_m3 INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    FOREIGN KEY (casa_id) REFERENCES casas(id) ON DELETE CASCADE
  )''',
  '''CREATE TABLE IF NOT EXISTS evento_uso_quiosque (
    id TEXT PRIMARY KEY,
    mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
    casa_ids TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now'))
  )'''
];

void main() async {
  sqfliteFfiInit();
  var databaseFactory = databaseFactoryFfi;
  final dbPath = p.join(Directory.current.path, '.dart_tool', 'sqflite_common_ffi', 'databases', 'ilheus_app.db');
  
  final db = await databaseFactory.openDatabase(dbPath);
  final uuid = const Uuid();
  const mesAno = '07/2025';

  try {
    // 1. Criar tabelas se não existirem
    for (var sql in schema) {
      await db.execute(sql);
    }

    await db.transaction((txn) async {
      // 2. Garantir que as 22 casas existam
      final countResult = await txn.rawQuery('SELECT COUNT(*) as count FROM casas');
      if (countResult.first['count'] as int == 0) {
        print('Semeando casas...');
        for (int i = 1; i <= 22; i++) {
          await txn.insert('casas', {
            'id': uuid.v4(),
            'numero': i,
            'ativa': 1,
            'isento': 0,
          });
        }
      }

      // 3. Limpar dados antigos de Julho/2025
      await txn.delete('configuracao_mes', where: 'mes_ano = ?', whereArgs: [mesAno]);
      await txn.delete('conta_corsan', where: 'mes_ano = ?', whereArgs: [mesAno]);
      await txn.delete('conta_luz', where: 'mes_ano = ?', whereArgs: [mesAno]);
      await txn.delete('leituras', where: 'mes_ano = ?', whereArgs: [mesAno]);
      await txn.delete('evento_uso_quiosque', where: 'mes_ano = ?', whereArgs: [mesAno]);

      // 4. Inserir Configuração
      await txn.insert('configuracao_mes', {
        'id': uuid.v4(),
        'mes_ano': mesAno,
        'valor_cond_centavos': 1500,
        'modelo_juros': 'igualitario',
      });

      // 5. Inserir Contas
      await txn.insert('conta_corsan', {
        'id': uuid.v4(),
        'mes_ano': mesAno,
        'leitura_anterior_m3': 1000,
        'leitura_atual_m3': 1300,
        'valor_agua_centavos': 150000,
        'valor_esgoto_centavos': 114400,
        'valor_servico_basico_centavos': 81400,
        'vencimento': '2025-08-10',
      });

      await txn.insert('conta_luz', {
        'id': uuid.v4(),
        'mes_ano': mesAno,
        'valor_total_centavos': 10000,
        'vencimento': '2025-08-15',
      });

      // 6. Inserir Leituras e Quiosque
      final casas = await txn.query('casas', orderBy: 'numero ASC');
      final List<String> casaIdsParaQuiosque = [];

      for (var casa in casas) {
        final numero = casa['numero'] as int;
        if (numero > 22) continue;

        final casaId = casa['id'] as String;
        final consumo = 10 + (numero % 10); 

        await txn.insert('leituras', {
          'id': uuid.v4(),
          'mes_ano': mesAno,
          'casa_id': casaId,
          'leitura_anterior_m3': 100 * numero,
          'leitura_atual_m3': (100 * numero) + consumo,
        });

        if (numero == 5 || numero == 10) casaIdsParaQuiosque.add(casaId);
      }

      await txn.insert('evento_uso_quiosque', {
        'id': uuid.v4(),
        'mes_ano': mesAno,
        'casa_ids': casaIdsParaQuiosque.join(','),
      });

      print('Julho de 2025 pronto para cálculo! 🚀');
    });
  } catch (e) {
    print('Erro: $e');
  } finally {
    await db.close();
  }
}
