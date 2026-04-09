# Ilheus App — AI Operating Model v2

**Diferença do v1:** Este método te ensina a dispensar o método.

---

## O que mudou do NexJob v1

| v1 (NexJob) | v2 (Ilheus App) |
|-------------|-----------------|
| Invariants de storage/dispatcher | Invariants de domínio financeiro |
| Roteamento feito pelo Claude.ai | Roteamento feito por você via ROUTING.md |
| Método estático | Método que evolui com o projeto |
| StyleCop + .NET | Dart lint + Flutter |
| `dotnet build --release` | `flutter build apk --release` |

---

## Start Rápido

**Tenho uma tarefa nova:**
1. Abre `ROUTING.md` — decide o agente sozinho
2. Se for execução → carrega `core/00-foundation-minimal.md` + workflow adequado
3. Se travar na decisão → Claude.ai primeiro, execução depois

**Regra de ouro:** Decisão arquitetural sempre passa pelo Claude.ai antes de executar.

---

## Estrutura

```
ai-method/
├── README.md                    ← você está aqui
├── ROUTING.md                   ← tabela de roteamento (use sozinho)
├── core/
│   ├── 00-foundation-minimal.md ← invariants + domínio + fórmula (80% das tarefas)
│   └── 00-foundation-extended.md← arquitetura completa + edge cases (tarefas complexas)
├── modes/
│   ├── 01-architect-mode.md     ← design sem código
│   ├── 02-execution-mode.md     ← implementa o que foi especificado
│   ├── 03-validation-mode.md    ← verifica compliance e qualidade
│   └── 04-release-mode.md       ← preparação para produção
├── workflows/
│   ├── feature.md               ← adicionar funcionalidade
│   ├── bugfix.md                ← corrigir problema
│   ├── test.md                  ← adicionar testes
│   ├── refactor.md              ← melhorar estrutura
│   └── reliability.md           ← validar cenários críticos
└── templates/
    ├── task-template.md
    ├── architect-output-template.md
    ├── execution-handoff-template.md
    └── validation-report-template.md
```

---

## Os Agentes

| Agente | Quando usar | Custo |
|--------|------------|-------|
| **Claude.ai** | Decisões, arquitetura, dúvidas de domínio | Médio |
| **Bruxo** (Claude Code) | Multi-arquivo, risco arquitetural | Alto |
| **Estagiário** (Gemini) | 1-2 arquivos, docs, CSS, baixo risco | Baixo |
| **Rainha** (Gemini adversarial) | Revisão arquitetural, contestação | Baixo |

**Para roteamento detalhado → ROUTING.md**

---

## Princípio Central

> **"Simplificar é edge para ficar gerúndio."**
> O que parece simples hoje vira problema incompleto amanhã.

---

## Protocolo de Evolução

Este método está incompleto. Intencionalmente.

Quando encontrar um caso que o método não cobre:
1. Não improvisa — anota
2. Traz para o Claude.ai
3. Atualiza o arquivo correto
4. Commita como `docs: evolui ai-method — [caso encontrado]`

**Em 3 meses, se você não tiver feito nenhum commit no ai-method, o método virou estante.**

---

## Versão

**Ilheus App AI Operating Model v2.0**
Data: 2026-04-09
Baseado em: NexJob AI Operating Model v1.0
