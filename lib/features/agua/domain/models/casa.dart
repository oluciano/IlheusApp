/// Casa residencial do condomínio (1-22) ou quiosque (23).
class Casa {
  final String id;
  final int numero;
  final bool ativa;

  // Flags de isenção por componente
  final bool isentoAgua;
  final bool isentoEsgoto;
  final bool isentoServicoBasico;
  final bool isentoLuz;
  final bool isentoCond;

  const Casa({
    required this.id,
    required this.numero,
    this.ativa = true,
    this.isentoAgua = false,
    this.isentoEsgoto = false,
    this.isentoServicoBasico = false,
    this.isentoLuz = false,
    this.isentoCond = false,
  });

  bool get isQuiosque => numero == 23;

  Casa copyWith({
    String? id,
    int? numero,
    bool? ativa,
    bool? isentoAgua,
    bool? isentoEsgoto,
    bool? isentoServicoBasico,
    bool? isentoLuz,
    bool? isentoCond,
  }) {
    return Casa(
      id: id ?? this.id,
      numero: numero ?? this.numero,
      ativa: ativa ?? this.ativa,
      isentoAgua: isentoAgua ?? this.isentoAgua,
      isentoEsgoto: isentoEsgoto ?? this.isentoEsgoto,
      isentoServicoBasico:
          isentoServicoBasico ?? this.isentoServicoBasico,
      isentoLuz: isentoLuz ?? this.isentoLuz,
      isentoCond: isentoCond ?? this.isentoCond,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'numero': numero,
      'ativa': ativa ? 1 : 0,
      'isento_agua': isentoAgua ? 1 : 0,
      'isento_esgoto': isentoEsgoto ? 1 : 0,
      'isento_servico_basico': isentoServicoBasico ? 1 : 0,
      'isento_luz': isentoLuz ? 1 : 0,
      'isento_cond': isentoCond ? 1 : 0,
    };
  }

  factory Casa.fromMap(Map<String, dynamic> map) {
    return Casa(
      id: map['id'] as String,
      numero: map['numero'] as int,
      ativa: (map['ativa'] as int) == 1,
      isentoAgua: (map['isento_agua'] as int) == 1,
      isentoEsgoto: (map['isento_esgoto'] as int) == 1,
      isentoServicoBasico:
          (map['isento_servico_basico'] as int) == 1,
      isentoLuz: (map['isento_luz'] as int) == 1,
      isentoCond: (map['isento_cond'] as int) == 1,
    );
  }
}
