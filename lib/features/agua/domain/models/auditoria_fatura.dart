/// Status da auditoria de fechamento mensal.
enum StatusAuditoria {
  ok,
  alerta,
  erro,
}

/// Auditoria de fechamento mensal — validação de somas.
class AuditoriaFatura {
  final String faturaId;

  // Leituras de água (m³)
  final int somaMetrosCasas;
  final int consumoGeralCorsan;
  final int diferencaMetros; // consumoGeralCorsan - somaMetrosCasas

  // Somas de esgoto (centavos)
  final int somaEsgotoCasas;
  final int valorEsgotoCorsan;

  // Somas de luz (centavos)
  final int somaLuzCasas;
  final int valorLuzCorsan;

  // Total cobrado (centavos)
  final int totalCobrado;

  // Status da auditoria
  final StatusAuditoria status;

  // Descrição de problemas encontrados (se houver)
  final String? mensagem;

  const AuditoriaFatura({
    required this.faturaId,
    required this.somaMetrosCasas,
    required this.consumoGeralCorsan,
    required this.diferencaMetros,
    required this.somaEsgotoCasas,
    required this.valorEsgotoCorsan,
    required this.somaLuzCasas,
    required this.valorLuzCorsan,
    required this.totalCobrado,
    required this.status,
    this.mensagem,
  });

  /// Auditoria passou OK — somas batem.
  bool get isOk => status == StatusAuditoria.ok;

  /// Há discrepâncias, mas administrador pode publicar com confirmação.
  bool get temAlerta => status == StatusAuditoria.alerta;

  /// Erro crítico — impossível publicar.
  bool get temErro => status == StatusAuditoria.erro;

  AuditoriaFatura copyWith({
    String? faturaId,
    int? somaMetrosCasas,
    int? consumoGeralCorsan,
    int? diferencaMetros,
    int? somaEsgotoCasas,
    int? valorEsgotoCorsan,
    int? somaLuzCasas,
    int? valorLuzCorsan,
    int? totalCobrado,
    StatusAuditoria? status,
    String? mensagem,
  }) {
    return AuditoriaFatura(
      faturaId: faturaId ?? this.faturaId,
      somaMetrosCasas: somaMetrosCasas ?? this.somaMetrosCasas,
      consumoGeralCorsan: consumoGeralCorsan ?? this.consumoGeralCorsan,
      diferencaMetros: diferencaMetros ?? this.diferencaMetros,
      somaEsgotoCasas: somaEsgotoCasas ?? this.somaEsgotoCasas,
      valorEsgotoCorsan: valorEsgotoCorsan ?? this.valorEsgotoCorsan,
      somaLuzCasas: somaLuzCasas ?? this.somaLuzCasas,
      valorLuzCorsan: valorLuzCorsan ?? this.valorLuzCorsan,
      totalCobrado: totalCobrado ?? this.totalCobrado,
      status: status ?? this.status,
      mensagem: mensagem ?? this.mensagem,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fatura_id': faturaId,
      'soma_metros_casas': somaMetrosCasas,
      'consumo_geral_corsan': consumoGeralCorsan,
      'diferenca_metros': diferencaMetros,
      'soma_esgoto_casas': somaEsgotoCasas,
      'valor_esgoto_corsan': valorEsgotoCorsan,
      'soma_luz_casas': somaLuzCasas,
      'valor_luz_corsan': valorLuzCorsan,
      'total_cobrado': totalCobrado,
      'status': status.name,
      if (mensagem != null) 'mensagem': mensagem,
    };
  }

  factory AuditoriaFatura.fromMap(Map<String, dynamic> map) {
    return AuditoriaFatura(
      faturaId: map['fatura_id'] as String,
      somaMetrosCasas: map['soma_metros_casas'] as int,
      consumoGeralCorsan: map['consumo_geral_corsan'] as int,
      diferencaMetros: map['diferenca_metros'] as int,
      somaEsgotoCasas: map['soma_esgoto_casas'] as int,
      valorEsgotoCorsan: map['valor_esgoto_corsan'] as int,
      somaLuzCasas: map['soma_luz_casas'] as int,
      valorLuzCorsan: map['valor_luz_corsan'] as int,
      totalCobrado: map['total_cobrado'] as int,
      status: StatusAuditoria.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusAuditoria.ok,
      ),
      mensagem: map['mensagem'] as String?,
    );
  }
}
