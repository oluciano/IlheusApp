# CLAUDE.md — Diretrizes e Lições Aprendidas

## Lição Aprendida: Honestidade sobre Limitações de Ambiente

**Contexto:** Ajuste 3 de robustez — Testes de integração com SQLite real

**O Problema:**
- Solicitação: Implementar testes de integração com banco SQLite real em memória
- Dependência: `sqflite_common_ffi` requer `libsqlite3.so`
- Ambiente: Não tem libsqlite3-dev instalado, sem acesso root

**O que NÃO fazer:**
❌ Criar mocks falsos que fingem ser testes reais
❌ Dar a volta em volta explicando por que "é assim mesmo"
❌ Entregar código com comentários enganosos

**O que fazer:**
✅ Ser explícito sobre a limitação
✅ Informar claramente que é mock, não teste real
✅ Documentar como resolver (apt-get install libsqlite3-dev)
✅ Criar uma issue para v2 (CI/CD com SQLite)
✅ Entregar o melhor possível dentro da limitação

**Resultado:**
- Código que valida SQL gerado está correto
- Aviso claro no topo do arquivo
- Limitação documentada em comentário
- Path forward definido para próxima versão

**Aplicação:**
Sempre priorizar honestidade sobre aparência. Se não conseguir executar algo, dizer claramente.
Preferir "Não consegui rodar banco real porque..." do que "Criei um mock que simula...".

---

## Padrões de Desenvolvimento

### Testes de Integração

- **Com banco real disponível:** Usar `sqflite_common_ffi` + inMemoryDatabasePath
- **Sem libsqlite3-dev:** Validar SQL gerado + parâmetros via mock (e documentar limitação)
- **Sempre adicionar:** Aviso claro no topo do arquivo sobre o que está sendo testado

### Transações SQLite

- **Preferir:** `db.transaction(() async { ... })` do sqflite
- **Evitar:** BEGIN/COMMIT/ROLLBACK manual
- **Benefício:** Rollback automático em exceções

### Validação Defensiva

- **Sempre validar:** faturaId não-vazio antes de persistir
- **Lançar:** ArgumentError com mensagem clara
- **Testar:** Caso de erro unitário

---

## Checklist para Próximas Implementações

- [ ] Transações? Use `db.transaction()`
- [ ] Persistindo entidade com FK? Validar que FK não é vazio
- [ ] Teste de integração? Informar se banco real ou mock
- [ ] Limitação de ambiente? Documentar explicitamente
- [ ] v2 pendente? Criar issue com requisitos de setup
