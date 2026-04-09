import 'package:ilheus_app/features/agua/domain/models/valor_monetario.dart';

class DespesaExtra {
  final String? id;
  final String mesAno;
  final String descricao;
  final ValorMonetario valorTotal;

  const DespesaExtra({
    this.id,
    required this.mesAno,
    required this.descricao,
    required this.valorTotal,
  });

  DespesaExtra copyWith({
    String? id,
    String? mesAno,
    String? descricao,
    ValorMonetario? valorTotal,
  }) {
    return DespesaExtra(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      descricao: descricao ?? this.descricao,
      valorTotal: valorTotal ?? this.valorTotal,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'mes_ano': mesAno,
      'descricao': descricao,
      'valor_total_centavos': valorTotal.centavos,
    };
  }

  factory DespesaExtra.fromMap(Map<String, dynamic> map) {
    return DespesaExtra(
      id: map['id'] as String?,
      mesAno: map['mes_ano'] as String,
      descricao: map['descricao'] as String,
      valorTotal: ValorMonetario.fromCentavos(map['valor_total_centavos'] as int),
    );
  }
}
