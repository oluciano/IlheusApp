# Ilheus App — AI Foundation (Extended)

**Carregue junto com o minimal apenas para tarefas complexas.**
**Tarefas simples: minimal é suficiente.**

> **Arquitetura de camadas e stack decisions → nas skills @flutter e @flutter-architecting-apps**
> Este arquivo contém apenas regras de domínio do Ilheus App.

---

## Módulos do App

```
agua/         → leitura, cálculo, cobrança, pagamento (módulo atual)
avisos/       → quadro de avisos do condomínio (futuro)
reservas/     → reserva do quiosque (futuro)
```

**Regra:** Módulos não se importam diretamente. Comunicação via eventos ou shared domain.

---

## Regras de Negócio Detalhadas

### Cálculo
- Só executa se todas as 22 casas ativas tiverem leitura do mês
- Casa inativa (vazia) → metros = 0, mas paga fixos ativos
- Quiosque (casa 23) → entra no denominador, rateado entre todas as casas
- Resultado sempre em `rascunho` até administrador publicar explicitamente

### Débitos
- Débito é criado automaticamente quando cobrança passa do vencimento sem pagamento
- Débito carrega para o mês seguinte somado na linha `debitos_anteriores`
- Débito quitado não some — fica no histórico com status `quitado` e data

### Isento
- Isento é por componente, não binário
- Casa 08 (leiturista) tem configuração própria definida pelo administrador
- Isenção pode mudar a cada mês — é configuração da cobrança, não da casa

### Juros
- Juros são repasse da CORSAN — não invenção interna
- Quando a fatura CORSAN vem com juros/multa, o administrador lança o valor
- Esse valor é distribuído proporcionalmente entre os inadimplentes do mês anterior

---

## Regras de UI

### Visão Morador
- Vê apenas sua própria cobrança
- Vê breakdown completo: proporcional + fixos + débitos
- Vê dashboard geral: "X de 22 casas pagaram" — sem identificar inadimplentes
- NÃO vê cobranças de outras casas

### Visão Administrador
- Vê todas as casas e status
- Lança leituras, configura fórmula, publica cálculo
- Registra pagamentos
- Gera PDF mensal (substituto do panfleto manuscrito)
- Vê histórico completo de débitos por casa

---

## Edge Cases Conhecidos

- **Leitura zero em casa ativa** — não é permitido, administrador deve confirmar se casa ficou vazia
- **Soma hidrômetros ≠ total CORSAN** — normal, diferença é perda/quiosque, não é erro
- **Mês sem fatura CORSAN** — bloqueia cálculo, não permite rascunho
- **Débito de casa que ficou inativa** — débito permanece, casa inativa não zera dívida
- **Administrador publica e morador já pagou** — pagamento registrado antes da publicação é válido

---

## Restrições de Implementação

- **Sem servidor na v1** — toda persistência é local no device do administrador
- **Android only na v1** — iOS só após validação com moradores
- **APK direto na v1** — Play Store só na v2
- **OCR é v3** — não antecipar, não criar abstrações para isso agora
- **Notificações são v2** — WhatsApp ainda resolve na v1
