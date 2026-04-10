/// Casa residencial do condomínio (1-22) ou quiiosque (23).
class Casa {
  final String id;
  final int numero;
  final bool ativa;

  /// Isenção simplificada: paga somente condomínio.
  final bool isento;

  /// Papel de administrador — não afeta cálculo financeiro.
  final bool ehAdministrador;

  const Casa({
    required this.id,
    required this.numero,
    this.ativa = true,
    this.isento = false,
    this.ehAdministrador = false,
  });

  bool get isQuiosque => numero == 23;

  Casa copyWith({
    String? id,
    int? numero,
    bool? ativa,
    bool? isento,
    bool? ehAdministrador,
  }) {
    return Casa(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      ativa: ativa ?? this.ativa,
      isento: isento ?? this.isento,
      ehAdministrador: ehAdministrador ?? this.ehAdministrador,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'ativa': ativa ? 1 : 0,
      'isento': isento ? 1 : 0,
      'eh_administrador': ehAdministrador ? 1 : 0,
    };
  }

  factory Casa.fromMap(Map<String, dynamic> map) {
    return Casa(
      id: map['id'] as String,
      numero: map['numero'] as int,
      ativa: (map['ativa'] as int) == 1,
      isento: (map['isento'] as int?) == 1,
      ehAdministrador: (map['eh_administrador'] as int?) == 1,
    );
  }
}
