import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';

class ContaCorsan {
  final String? id;
  final String mesAno;
  final int leituraAnteriorM3;
  final int leituraAtualM3;
  final ValorMonetario valorAgua;
  final ValorMonetario valorEsgoto;
  final ValorMonetario valorServicoBasico;
  final ValorMonetario? valorJuros;
  final DateTime? vencimento;

  const ContaCorsan({
    this.id,
    required this.mesAno,
    this.leituraAnteriorM3 = 0,
    this.leituraAtualM3 = 0,
    this.valorAgua = const ValorMonetario.zero(),
    this.valorEsgoto = const ValorMonetario.zero(),
    this.valorServicoBasico = const ValorMonetario.zero(),
    this.valorJuros,
    this.vencimento,
  });

  int get consumoM3 => leituraAtualM3 - leituraAnteriorM3;

  ContaCorsan copyWith({
    String? id,
    String? mesAno,
    int? leituraAnteriorM3,
    int? leituraAtualM3,
    ValorMonetario? valorAgua,
    ValorMonetario? valorEsgoto,
    ValorMonetario? valorServicoBasico,
    ValorMonetario? valorJuros,
    DateTime? vencimento,
  }) {
    return ContaCorsan(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      leituraAnteriorM3: leituraAnteriorM3 ?? this.leituraAnteriorM3,
      leituraAtualM3: leituraAtualM3 ?? this.leituraAtualM3,
      valorAgua: valorAgua ?? this.valorAgua,
      valorEsgoto: valorEsgoto ?? this.valorEsgoto,
      valorServicoBasico: valorServicoBasico ?? this.valorServicoBasico,
      valorJuros: valorJuros ?? this.valorJuros,
      vencimento: vencimento ?? this.vencimento,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mes_ano': mesAno,
      'leitura_anterior_m3': leituraAnteriorM3,
      'leitura_atual_m3': leituraAtualM3,
      'valor_agua_centavos': valorAgua.centavos,
      'valor_esgoto_centavos': valorEsgoto.centavos,
      'valor_servico_basico_centavos': valorServicoBasico.centavos,
      'valor_juros_centavos': valorJuros?.centavos,
      'vencimento': vencimento?.toIso8601String(),
    };
  }

  factory ContaCorsan.fromMap(Map<String, dynamic> map) {
    return ContaCorsan(
      id: map['id'] as String?,
      mesAno: map['mes_ano'] as String,
      leituraAnteriorM3: map['leitura_anterior_m3'] as int,
      leituraAtualM3: map['leitura_atual_m3'] as int,
      valorAgua: ValorMonetario.fromCentavos(map['valor_agua_centavos'] as int),
      valorEsgoto: ValorMonetario.fromCentavos(map['valor_esgoto_centavos'] as int),
      valorServicoBasico:
          ValorMonetario.fromCentavos(map['valor_servico_basico_centavos'] as int),
      valorJuros: map['valor_juros_centavos'] != null
          ? ValorMonetario.fromCentavos(map['valor_juros_centavos'] as int)
          : null,
      vencimento: map['vencimento'] != null
          ? DateTime.parse(map['vencimento'] as String)
          : null,
    );
  }
}
