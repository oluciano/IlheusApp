-- =============================================================================
-- Ilheus App — Schema Completo v2
-- Valores monetários SEMPRE em centavos (INTEGER) — nunca REAL/FLOAT
-- mes_ano SEMPRE no formato MM/YYYY
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Casas (ordem: deve ser criada primeiro por ser FK de várias tabelas)
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS casas (
  id TEXT PRIMARY KEY,
  numero INTEGER NOT NULL CHECK (numero >= 1 AND numero <= 23),
  ativa INTEGER NOT NULL DEFAULT 1,
  isento_agua INTEGER NOT NULL DEFAULT 0,
  isento_esgoto INTEGER NOT NULL DEFAULT 0,
  isento_servico_basico INTEGER NOT NULL DEFAULT 0,
  isento_luz INTEGER NOT NULL DEFAULT 0,
  isento_cond INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_casas_numero ON casas(numero);
CREATE INDEX IF NOT EXISTS idx_casas_ativa ON casas(ativa);

-- ---------------------------------------------------------------------------
-- 2. Conta CORSAN
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_conta_corsan_mes ON conta_corsan(mes_ano);

-- ---------------------------------------------------------------------------
-- 3. Conta Luz
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS conta_luz (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  valor_total_centavos INTEGER NOT NULL DEFAULT 0,
  valor_juros_centavos INTEGER,
  vencimento TEXT,
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_conta_luz_mes ON conta_luz(mes_ano);

-- ---------------------------------------------------------------------------
-- 4. Configuração do Mês
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_config_mes_ano ON configuracao_mes(mes_ano);

-- ---------------------------------------------------------------------------
-- 5. Leituras
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS leituras (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  casa_id TEXT NOT NULL,
  leitura_anterior_m3 INTEGER NOT NULL DEFAULT 0,
  leitura_atual_m3 INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (casa_id) REFERENCES casas(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_leituras_mes ON leituras(mes_ano);
CREATE INDEX IF NOT EXISTS idx_leituras_casa ON leituras(casa_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_leituras_mes_casa
  ON leituras(mes_ano, casa_id);

-- ---------------------------------------------------------------------------
-- 6. Evento Uso Quiosque
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS evento_uso_quiosque (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  casa_ids TEXT NOT NULL,  -- JSON array de IDs: ["casa-1","casa-5"]
  created_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_evento_quiosque_mes ON evento_uso_quiosque(mes_ano);

-- ---------------------------------------------------------------------------
-- 7. Fatura Calculada
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS fatura_calculada (
  id TEXT PRIMARY KEY,
  mes_ano TEXT NOT NULL UNIQUE CHECK (mes_ano GLOB '[0-9][0-9]/[0-9][0-9][0-9][0-9]'),
  status TEXT NOT NULL DEFAULT 'rascunho'
    CHECK (status IN ('rascunho', 'publicado')),
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  updated_at TEXT NOT NULL DEFAULT (datetime('now'))
);

CREATE INDEX IF NOT EXISTS idx_fatura_mes ON fatura_calculada(mes_ano);
CREATE INDEX IF NOT EXISTS idx_fatura_status ON fatura_calculada(status);

-- ---------------------------------------------------------------------------
-- 8. Cobranças
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_cobrancas_fatura ON cobrancas(fatura_id);
CREATE INDEX IF NOT EXISTS idx_cobrancas_casa ON cobrancas(casa_id);
CREATE INDEX IF NOT EXISTS idx_cobrancas_status ON cobrancas(status);
CREATE UNIQUE INDEX IF NOT EXISTS idx_cobrancas_fatura_casa
  ON cobrancas(fatura_id, casa_id);

-- ---------------------------------------------------------------------------
-- 9. Pagamentos
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pagamentos (
  id TEXT PRIMARY KEY,
  cobranca_id TEXT NOT NULL,
  data_pagamento TEXT NOT NULL,
  valor_pago_centavos INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT (datetime('now')),
  FOREIGN KEY (cobranca_id) REFERENCES cobrancas(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_pagamentos_cobranca ON pagamentos(cobranca_id);
CREATE INDEX IF NOT EXISTS idx_pagamentos_data ON pagamentos(data_pagamento);

-- ---------------------------------------------------------------------------
-- 10. Débitos
-- ---------------------------------------------------------------------------
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
);

CREATE INDEX IF NOT EXISTS idx_debitos_casa ON debitos(casa_id);
CREATE INDEX IF NOT EXISTS idx_debitos_status ON debitos(status);
CREATE INDEX IF NOT EXISTS idx_debitos_origem ON debitos(mes_ano_origem);

-- ---------------------------------------------------------------------------
-- Trigger: atualizar updated_at em fatura_calculada
-- ---------------------------------------------------------------------------
CREATE TRIGGER IF NOT EXISTS fatura_updated_at
AFTER UPDATE ON fatura_calculada
FOR EACH ROW
BEGIN
  UPDATE fatura_calculada SET updated_at = datetime('now') WHERE id = OLD.id;
END;
