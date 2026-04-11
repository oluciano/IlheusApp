// Schema v2 — gerado a partir de schema_v2.sql
// Cada constante contém o DDL de uma tabela.

const String casas = '''
CREATE TABLE IF NOT EXISTS casas (
  id TEXT PRIMARY KEY,
  numero INTEGER NOT NULL CHECK (numero >= 1 AND numero <= 23),
  ativa INTEGER NOT NULL DEFAULT 1,
  isento INTEGER NOT NULL DEFAULT 0,
  eh_administrador INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
)
''';

const String contaCorsan = '''
CREATE TABLE IF NOT EXISTS conta_corsan (
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
)
''';

const String contaLuz = '''
CREATE TABLE IF NOT EXISTS conta_luz (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  valor_total_centavos INTEGER NOT NULL DEFAULT 0,
  valor_juros_centavos INTEGER,
  vencimento TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
)
''';

const String configuracaoMes = '''
CREATE TABLE IF NOT EXISTS configuracao_mes (
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
)
''';

const String leituras = '''
CREATE TABLE IF NOT EXISTS leituras (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  casa_id TEXT NOT NULL,
  leitura_anterior_m3 INTEGER NOT NULL DEFAULT 0,
  leitura_atual_m3 INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (casa_id) REFERENCES casas(id) ON DELETE CASCADE
)
''';

const String eventoUsoQuiosque = '''
CREATE TABLE IF NOT EXISTS evento_uso_quiosque (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  casa_ids TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
)
''';

const String faturaCalculada = '''
CREATE TABLE IF NOT EXISTS fatura_calculada (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  status TEXT NOT NULL DEFAULT 'rascunho'
    CHECK (status IN ('rascunho', 'publicado')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
)
''';

const String cobrancas = '''
CREATE TABLE IF NOT EXISTS cobrancas (
  id TEXT PRIMARY KEY,
  fatura_id TEXT NOT NULL,
  casa_id TEXT NOT NULL,
  valor_agua_centavos INTEGER NOT NULL DEFAULT 0,
  valor_esgoto_centavos INTEGER NOT NULL DEFAULT 0,
  valor_servico_basico_centavos INTEGER NOT NULL DEFAULT 0,
  valor_luz_centavos INTEGER NOT NULL DEFAULT 0,
  valor_cond_centavos INTEGER NOT NULL DEFAULT 0,
  valor_quiosque_centavos INTEGER NOT NULL DEFAULT 0,
  valor_juros_centavos INTEGER NOT NULL DEFAULT 0,
  valor_debitos_centavos INTEGER NOT NULL DEFAULT 0,
  valor_total_centavos INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'pendente'
    CHECK (status IN ('pendente', 'pago', 'inadimplente')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (fatura_id) REFERENCES fatura_calculada(id) ON DELETE CASCADE,
  FOREIGN KEY (casa_id) REFERENCES casas(id) ON DELETE CASCADE
)
''';

const String pagamentos = '''
CREATE TABLE IF NOT EXISTS pagamentos (
  id TEXT PRIMARY KEY,
  cobranca_id TEXT NOT NULL,
  data_pagamento TEXT NOT NULL,
  valor_pago_centavos INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (cobranca_id) REFERENCES cobrancas(id) ON DELETE CASCADE
)
''';

const String debitos = '''
CREATE TABLE IF NOT EXISTS debitos (
  id TEXT PRIMARY KEY,
  cobranca_id TEXT NOT NULL,
  casa_id TEXT NOT NULL,
  mes_ano_origem TEXT NOT NULL CHECK (mes_ano_origem GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  valor_centavos INTEGER NOT NULL,
  status TEXT NOT NULL DEFAULT 'aberto'
    CHECK (status IN ('aberto', 'quitado')),
  data_quitacao TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (cobranca_id) REFERENCES cobrancas(id) ON DELETE CASCADE,
  FOREIGN KEY (casa_id) REFERENCES casas(id) ON DELETE CASCADE
)
''';

const String faturaUpdatedAtTrigger = '''
CREATE TRIGGER IF NOT EXISTS fatura_updated_at
AFTER UPDATE ON fatura_calculada
FOR EACH ROW
BEGIN
  UPDATE fatura_calculada SET updated_at = datetime('now') WHERE id = OLD.id;
END
''';

const String despesasExtras = '''
CREATE TABLE IF NOT EXISTS despesas_extras (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  descricao TEXT NOT NULL,
  valor_total_centavos INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
)
''';
