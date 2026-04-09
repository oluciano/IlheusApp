import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';

class ContaLuz {
  final String? id;
  final String mesAno;
  final ValorMonetario valorTotal;
  final ValorMonetario? valorJuros;
  final DateTime? vencimento;

  const ContaLuz({
    this.id,
    required this.mesAno,
    this.valorTotal = const ValorMonetario.zero(),
    this.valorJuros,
    this.vencimento,
  });

  ContaLuz copyWith({
    String? id,
    String? mesAno,
    ValorMonetario? valorTotal,
    ValorMonetario? valorJuros,
    DateTime? vencimento,
  }) {
    return ContaLuz(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      valorTotal: valorTotal ?? this.valorTotal,
      valorJuros: valorJuros ?? this.valorJuros,
      vencimento: vencimento ?? this.vencimento,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mes_ano': mesAno,
      'valor_total_centavos': valorTotal.centavos,
      'valor_juros_centavos': valorJuros?.centavos,
      'vencimento': vencimento?.toIso8601String(),
    };
  }

  factory ContaLuz.fromMap(Map<String, dynamic> map) {
    return ContaLuz(
      id: map['id'] as String?,
      mesAno: map['mes_ano'] as String,
      valorTotal: ValorMonetario.fromCentavos(map['valor_total_centavos'] as int),
      valorJuros: map['valor_juros_centavos'] != null
          ? ValorMonetario.fromCentavos(map['valor_juros_centavos'] as int)
          : null,
      vencimento: map['vencimento'] != null
          ? DateTime.parse(map['vencimento'] as String)
          : null,
    );
  }
}
