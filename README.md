# Ilhéus App

Aplicativo de gestão de condomínio para controle de água, avisos e reservas.

## Stack

- **Flutter** (Android first)
- **Dart**
- **sqflite** (SQLite local)
- **Riverpod** (state management)
- **GoRouter** (navegação)
- **pdf** (geração de PDF)

## Arquitetura

Clean Architecture com módulos independentes:

```
lib/
├── core/           → utilitários, constantes, tema, rotas, database
├── features/       → módulos (agua/, avisos/, reservas/)
└── shared/         → widgets compartilhados
```

## Pré-requisitos

- Flutter SDK >= 3.16.0
- Dart SDK >= 3.2.0
- Android SDK (para build APK)

## Executando

```bash
# Instalar dependências
flutter pub get

# Rodar em device/emulador
flutter run

# Build release
flutter build apk --release
```

## Estrutura de Features

### `agua/` — Módulo principal
Leitura, cálculo, cobrança e pagamento de água.

### `avisos/` — Quadro de avisos (futuro)
Comunicados do condomínio.

### `reservas/` — Reservas (futuro)
Reserva do quiosque.

---

**Regras de domínio:** ver `ai-method/core/00-foundation-minimal.md`
