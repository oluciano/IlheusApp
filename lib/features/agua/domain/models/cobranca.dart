import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';

/// Cobrança detalhada de uma casa para uma fatura.
class Cobranca {
  final String id;
  final String faturaId;
  final String casaId;

  // Breakdown por componente (centavos)
  final int valorAgua;
  final int valorEsgoto;
  final int valorServicoBasico;
  final int valorLuz;
  final int valorCond;
  final int valorQuiosque;
  final int valorJuros;
  final int valorDebitos;

  // Total consolidado (centavos)
  final int valorTotal;

  final StatusCobranca status;

  const Cobranca({
    required this.id,
    required this.faturaId,
    required this.casaId,
    this.valorAgua = 0,
    this.valorEsgoto = 0,
    this.valorServicoBasico = 0,
    this.valorLuz = 0,
    this.valorCond = 0,
    this.valorQuiosque = 0,
    this.valorJuros = 0,
    this.valorDebitos = 0,
    required this.valorTotal,
    this.status = StatusCobranca.pendente,
  });

  Cobranca copyWith({
    String? id,
    String? faturaId,
    String? casaId,
    int? valorAgua,
    int? valorEsgoto,
    int? valorServicoBasico,
    int? valorLuz,
    int? valorCond,
    int? valorQuiosque,
    int? valorJuros,
    int? valorDebitos,
    int? valorTotal,
    StatusCobranca? status,
  }) {
    return Cobranca(
      id: id ?? this.id,
      faturaId: faturaId ?? this.faturaId,
      casaId: casaId ?? this.casaId,
      valorAgua: valorAgua ?? this.valorAgua,
      valorEsgoto: valorEsgoto ?? this.valorEsgoto,
      valorServicoBasico: valorServicoBasico ?? this.valorServicoBasico,
      valorLuz: valorLuz ?? this.valorLuz,
      valorCond: valorCond ?? this.valorCond,
      valorQuiosque: valorQuiosque ?? this.valorQuiosque,
      valorJuros: valorJuros ?? this.valorJuros,
      valorDebitos: valorDebitos ?? this.valorDebitos,
      valorTotal: valorTotal ?? this.valorTotal,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fatura_id': faturaId,
      'casa_id': casaId,
      'valor_agua_centavos': valorAgua,
      'valor_esgoto_centavos': valorEsgoto,
      'valor_servico_basico_centavos': valorServicoBasico,
      'valor_luz_centavos': valorLuz,
      'valor_cond_centavos': valorCond,
      'valor_quiosque_centavos': valorQuiosque,
      'valor_juros_centavos': valorJuros,
      'valor_debitos_centavos': valorDebitos,
      'valor_total_centavos': valorTotal,
      'status': status.name,
    };
  }

  factory Cobranca.fromMap(Map<String, dynamic> map) {
    return Cobranca(
      id: map['id'] as String,
      faturaId: map['fatura_id'] as String,
      casaId: map['casa_id'] as String,
      valorAgua: map['valor_agua_centavos'] as int,
      valorEsgoto: map['valor_esgoto_centavos'] as int,
      valorServicoBasico:
          map['valor_servico_basico_centavos'] as int,
      valorLuz: map['valor_luz_centavos'] as int,
      valorCond: map['valor_cond_centavos'] as int,
      valorQuiosque: map['valor_quiosque_centavos'] as int,
      valorJuros: map['valor_juros_centavos'] as int,
      valorDebitos: map['valor_debitos_centavos'] as int,
      valorTotal: map['valor_total_centavos'] as int,
      status: StatusCobranca.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusCobranca.pendente,
      ),
    );
  }
}
