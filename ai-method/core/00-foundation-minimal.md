# Ilheus App — AI Foundation (Minimal)

**Leia isso para 80% das tarefas. Só adicione o extended se necessário.**

---

## Invariants de Domínio (Não-Negociáveis)

- **SQLite é source of truth** — nenhum estado em memória sobrescreve o banco
- **Cálculo nunca executa sem leitura completa** — todas as casas ativas precisam ter leitura do mês
- **Cada mês é independente** — débito anterior não acumula na fatura nova, fica separado
- **Fórmula é configurável, nunca hardcoded** — componentes ativados/desativados por mês pelo administrador
- **Administrador valida antes de publicar** — cálculo tem estado `rascunho` antes de `publicado`
- **Isento é por componente** — flags individuais: `isento_agua`, `isento_esgoto`, `isento_servico_basico`, `isento_luz`, `isento_cond`
- **Data de pagamento sempre registrada** — dia exato importa para cálculo de juros proporcionais
- **Breakdown sempre visível** — morador vê cada componente, nunca só o total

---

## Modelo de Domínio (Core)

```
Casa
  → numero (1-22)
  → flags isento por componente
  → ativa (casa vazia ainda paga componentes fixos)

Quiosque
  → sem hidrômetro
  → EventoUsoQuiosque por mês (quais casas usaram)
  → só água é cobrada de quem usou (esgoto e serviço básico não)

Leitura
  → mes_ano + casa + leitura_atual_m3
  → leitura_anterior_m3 (do mês anterior, já no banco)
  → consumo_m3 (derivado: atual - anterior)

ContaCORSAN
  → mes_ano
  → leitura_anterior_m3 + leitura_atual_m3
  → consumo_m3 (derivado)
  → valor_agua_reais
  → valor_esgoto_reais
  → valor_servico_basico_reais
  → valor_juros_reais (SC + FA — se houver)
  → vencimento

ContaLuz
  → mes_ano
  → valor_total_reais
  → vencimento

ConfiguracaoMes
  → mes_ano
  → valor_cond (fixo, definido em assembleia)
  → modelo_juros: IGUALITARIO | PROPORCIONAL_DIAS
  → componentes ativos (flags — fórmula nunca hardcoded)

FaturaCalculada
  → mes_ano + status: rascunho | publicado
  → gerada pelo administrador, só publicada após validação

Cobranca
  → fatura + casa + breakdown detalhado
  → status: pendente | pago | inadimplente

Pagamento
  → cobranca + data_pagamento (dia exato) + valor_pago

Debito
  → cobranca em aberto de mês anterior
  → aparece como alerta separado, nunca somado na fatura nova
```

---

## Fórmula Oficial

### Tipos de rateio

| Componente | Tipo | Base |
|------------|------|------|
| Água | Proporcional | `consumo_casa / consumo_geral_corsan` |
| Água quiosque | Proporcional (só quem usou) | cota 23 dividida entre os que usaram |
| Esgoto | Igualitário | `valor_esgoto / 22` |
| Serviço Básico | Igualitário | `valor_servico_basico / 22` |
| Luz | Igualitário | `valor_luz / 22` |
| Condomínio | Fixo | definido em assembleia |
| Juros CORSAN | Configurável | só inadimplentes |

### Cálculo por casa

```
agua_propria     = (consumo_casa / consumo_geral_corsan) * valor_agua
agua_quiosque    = se usou: (valor_agua / 23) / qtd_casas_que_usaram
esgoto           = valor_esgoto / 22
servico_basico   = valor_servico_basico / 22
luz              = valor_luz / 22
cond             = valor fixo do mês
juros            = ver modelo configurado
─────────────────────────────────────────────
total_casa       = soma dos componentes ativos + isento aplicado
```

### Modelo de juros

```
IGUALITARIO (modelo atual):
  juros_casa = total_juros_corsan / qtd_inadimplentes

PROPORCIONAL_DIAS (modelo futuro):
  dias_atraso = data_pagamento - vencimento
              (ou vencimento_proximo se não pagou nada)
  juros_casa  = (dias_atraso / soma_dias_todos_inadimplentes) * total_juros_corsan

Pagou até dia 10 → sem juros (sempre, nos dois modelos)
```

---

## Quiosque — Denominador Dinâmico

```
Nenhuma casa usou:
  denominador água = 22

Uma ou mais casas usaram:
  denominador água = 23
  cota 23 (só água) dividida entre as casas que usaram
  esgoto e serviço básico NÃO são cobrados do quiosque
```

---

## Auditoria Mensal (Administrador)

```
Hidrômetro geral CORSAN:   X m³
Soma leituras 22 casas:    Y m³
Diferença:                 X - Y m³  → alerta ⚠️ se > 0

Possível: quiosque sem lançamento, vazamento, hidrômetro com problema
Decisão: administrador investiga ou rateia — o app não decide
```

---

## Visualização do Morador

```
📋 Fevereiro 2026           📋 Março 2026
─────────────────────        ─────────────────────
Água:          R$ 68,00      Água:          R$ 71,00
Esgoto:        R$ 52,00      Esgoto:        R$ 52,00
Serviço Básico:R$ 37,00      Serviço Básico:R$ 37,00
Luz:           R$  4,54      Luz:           R$  4,54
Condomínio:    R$ 15,00      Condomínio:    R$ 15,00
─────────────────────        ─────────────────────
Total:         R$176,54      Total:         R$179,54
Status: ⚠️ PENDENTE          Status: ✅ PAGO

🚨 Você possui débitos anteriores em aberto!
```

---

## Estados de Cobrança

```
rascunho → publicado → pago
rascunho → publicado → inadimplente (passou vencimento)
inadimplente → Debito (alerta no mês seguinte, nunca somado)
```

---

## Decisões Confirmadas

- **Taxa desconhecida (R$ 3,79 / R$ 9,84)** — origem ainda não confirmada. Componente existe no sistema mas **desativado por default**. Administrador ativa quando souber o que é.
- **Esgoto casa fechada** — ✅ paga igualitário mesmo sem consumo. Casa vazia não isenta do esgoto.
- **Modelo PROPORCIONAL_DIAS** — ✅ administrador configura quando quiser migrar. Flag em `ConfiguracaoMes`.

---

## Qualidade de Código (Flutter/Dart)

- Zero warnings em `flutter build apk --release`
- Zero `TODO` sem issue vinculada
- Nenhum valor magic number — tudo em constantes nomeadas
- `async/await` sempre — nunca `.then()` aninhado
- Null safety respeitado — nunca `!` sem justificativa em comentário

---

## Princípio de Processo

> **"Simplificar é edge para ficar gerúndio."**
> O que parece simples hoje vira problema incompleto amanhã.
> Quando a tentação for remover um campo ou fundir dois conceitos — pergunte antes.

---

## Golden Rule

**Se o comportamento não está explicitamente definido → NÃO IMPLEMENTA → PERGUNTA**
