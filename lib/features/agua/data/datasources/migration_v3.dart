/// Migration v3: simplifica modelo de isenção da tabela casas.
///
/// Remove 5 colunas de isenção por componente:
///   isento_agua, isento_esgoto, isento_servico_basico, isento_luz, isento_cond
///
/// Adiciona 2 colunas simplificadas:
///   isento INTEGER NOT NULL DEFAULT 0
///   eh_administrador INTEGER NOT NULL DEFAULT 0
///
/// Regra de migração de dados:
///   - Se TODAS as 5 flags antigas eram 1 → isento = 1
///   - Caso contrário → isento = 0
///   - eh_administrador = 0 para todos (configurar manualmente depois)
const String migrationV3 = '''
-- Adiciona novas colunas
ALTER TABLE casas ADD COLUMN isento INTEGER NOT NULL DEFAULT 0;
ALTER TABLE casas ADD COLUMN eh_administrador INTEGER NOT NULL DEFAULT 0;

-- Migra dados: se todas as 5 flags eram 1, marca como isento
UPDATE casas
SET isento = 1
WHERE isento_agua = 1
  AND isento_esgoto = 1
  AND isento_servico_basico = 1
  AND isento_luz = 1
  AND isento_cond = 1;

-- Remove colunas antigas (SQLite 3.35+ suporta DROP COLUMN)
ALTER TABLE casas DROP COLUMN isento_agua;
ALTER TABLE casas DROP COLUMN isento_esgoto;
ALTER TABLE casas DROP COLUMN isento_servico_basico;
ALTER TABLE casas DROP COLUMN isento_luz;
ALTER TABLE casas DROP COLUMN isento_cond;
''';
