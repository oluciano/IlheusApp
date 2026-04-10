/// Pagamento de uma cobrança.
class Pagamento {
  final String id;
  final String cobrancaId;
  final DateTime dataPagamento;
  final int valorPagoCentavos;

  const Pagamento({
    required this.id,
    required this.cobrancaId,
    required this.dataPagamento,
    required this.valorPagoCentavos,
  });

  Pagamento copyWith({
    String? id,
    String? cobrancaId,
    DateTime? dataPagamento,
    int? valorPagoCentavos,
  }) {
    return Pagamento(
      id: id ?? this.id,
      cobrancaId: cobrancaId ?? this.cobrancaId,
      dataPagamento: dataPagamento ?? this.dataPagamento,
      valorPagoCentavos: valorPagoCentavos ?? this.valorPagoCentavos,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cobranca_id': cobrancaId,
      'data_pagamento': dataPagamento.toIso8601String(),
      'valor_pago_centavos': valorPagoCentavos,
    };
  }

  factory Pagamento.fromMap(Map<String, dynamic> map) {
    return Pagamento(
      id: map['id'] as String,
      cobrancaId: map['cobranca_id'] as String,
      dataPagamento: DateTime.parse(map['data_pagamento'] as String),
      valorPagoCentavos: map['valor_pago_centavos'] as int,
    );
  }
}
