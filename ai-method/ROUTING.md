# Ilheus App — Tabela de Roteamento de Agentes

**Você aplica isso sozinho. Sem perguntar pro Claude.ai.**
**Quando a tabela não cobrir o caso → aí você vem perguntar.**

---

## Os Agentes

| Agente | Ferramenta | Papel | Custo |
|--------|-----------|-------|-------|
| **Claude.ai** | claude.ai | Arquiteto / Tech Lead / Psicólogo kkk | Médio |
| **Bruxo** | Claude Code CLI | Executor sênior — multi-arquivo, alto risco | Alto |
| **Estagiário** | Gemini CLI | Executor júnior — baixo risco, docs, CSS | Baixo |
| **Rainha** | Gemini CLI (modo adversarial) | Revisora arquitetural — bate de frente | Baixo |

---

## Tabela de Roteamento

### Pergunta 1: É uma decisão ou é execução?

```
Decisão arquitetural, dúvida de domínio, 
escolha de abordagem, revisão de design
        → SEMPRE Claude.ai primeiro
        → Só depois roteia execução
```

---

### Pergunta 2: Quantos arquivos modifica?

```
0 arquivos (só leitura, review, docs)  → Estagiário
1-2 arquivos                           → Estagiário
3-5 arquivos                           → Avalia risco (Pergunta 3)
6+ arquivos                            → Bruxo
```

---

### Pergunta 3: Tem risco arquitetural?

```
Risco arquitetural = qualquer uma dessas:
  - Modifica cálculo de cobrança
  - Modifica modelo de dados (Casa, Leitura, Cobrança, Débito)
  - Modifica fluxo de estados (rascunho → publicado → pago)
  - Cria nova camada ou novo módulo
  - Integra dependência externa nova

SIM → Bruxo (independente do número de arquivos)
NÃO → Estagiário se ≤ 2 arquivos, Bruxo se 3+
```

---

### Pergunta 4: O Bruxo está com budget baixo?

```
Budget baixo = você está economizando tokens do Claude Code

SIM + tarefa é 3-5 arquivos SEM risco arquitetural
    → Tenta Estagiário com prompt cirúrgico
    → Se Estagiário travar ou errar → Bruxo (sem culpa)

SIM + tarefa TEM risco arquitetural
    → Bruxo mesmo assim (errar aqui sai mais caro)

NÃO → segue tabela normal
```

---

## Fluxo Visual

```
TAREFA NOVA
    │
    ├─ É decisão/dúvida? ──────────────────→ Claude.ai
    │
    ├─ É review/docs/CSS? ────────────────→ Estagiário
    │
    ├─ Tem risco arquitetural? ───────────→ Bruxo
    │
    ├─ 6+ arquivos? ──────────────────────→ Bruxo
    │
    ├─ 3-5 arquivos sem risco?
    │       ├─ Budget OK ────────────────→ Bruxo
    │       └─ Budget baixo ────────────→ Estagiário (tenta)
    │
    └─ 1-2 arquivos sem risco? ───────────→ Estagiário
```

---

## Quando Acionar a Rainha

A Rainha não é acionada por tarefa — é acionada por **momento do projeto**:

- Antes de fechar o modelo de domínio inicial
- Antes de publicar uma versão para os moradores
- Quando uma decisão arquitetural parecer certa demais (desconfie)
- Quando o Bruxo e o Estagiário concordarem em algo importante (peça contestação)

**Prompt padrão para a Rainha:**
```
Leia [arquivo de arquitetura ou decisão].
Você é uma arquiteta sênior cética.
Encontre os 3 maiores problemas desta decisão.
Não valide — questione.
```

---

## Restrições Permanentes do Estagiário

O Estagiário **nunca** toca em:
- Fórmula de cálculo de cobrança
- Modelos de dados core (Casa, Leitura, Cobrança, Débito, Configuração)
- Fluxo de estados de cobrança
- Lógica de débitos anteriores
- Qualquer operação de escrita no SQLite que não seja CRUD simples

**Se a tarefa tocar nesses pontos → Bruxo, sem negociação.**

---

## Protocolo de Evolução desta Tabela

Esta tabela está errada em algum ponto que ainda não descobrimos.

Quando você travar numa decisão de roteamento:
1. Anota o caso que a tabela não cobriu
2. Traz para o Claude.ai
3. A gente atualiza a tabela juntos

**Meta:** Em 3 meses você deve conseguir apontar 2 erros nesta tabela.
Se não apontar nenhum, é porque não está usando — não porque está perfeita.

---

## Versão

**v2.0 — Ilheus App**
Data: 2026-04-09
