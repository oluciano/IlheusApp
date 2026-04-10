import 'package:ilheus_app/features/agua/domain/models/status_debito.dart';

/// Débito em aberto de mês anterior — aparece como alerta separado.
class Debito {
  final String id;
  final String cobrancaId;
  final String casaId;
  final String mesAnoOrigem;
  final int valorCentavos;
  final StatusDebito status;
  final DateTime? dataQuitacao;

  const Debito({
    required this.id,
    required this.cobrancaId,
    required this.casaId,
    required this.mesAnoOrigem,
    required this.valorCentavos,
    this.status = StatusDebito.aberto,
    this.dataQuitacao,
  });

  bool get isAberto => status == StatusDebito.aberto;
  bool get isQuitado => status == StatusDebito.quitado;

  Debito copyWith({
    String? id,
    String? cobrancaId,
    String? casaId,
    String? mesAnoOrigem,
    int? valorCentavos,
    StatusDebito? status,
    DateTime? dataQuitacao,
  }) {
    return Debito(
      id: id ?? this.id,
      cobrancaId: cobrancaId ?? this.cobrancaId,
      casaId: casaId ?? this.casaId,
      mesAnoOrigem: mesAnoOrigem ?? this.mesAnoOrigem,
      valorCentavos: valorCentavos ?? this.valorCentavos,
      status: status ?? this.status,
      dataQuitacao: dataQuitacao ?? this.dataQuitacao,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cobranca_id': cobrancaId,
      'casa_id': casaId,
      'mes_ano_origem': mesAnoOrigem,
      'valor_centavos': valorCentavos,
      'status': status.name,
      'data_quitacao': dataQuitacao?.toIso8601String(),
    };
  }

  factory Debito.fromMap(Map<String, dynamic> map) {
    return Debito(
      id: map['id'] as String,
      cobrancaId: map['cobranca_id'] as String,
      casaId: map['casa_id'] as String,
      mesAnoOrigem: map['mes_ano_origem'] as String,
      valorCentavos: map['valor_centavos'] as int,
      status: StatusDebito.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusDebito.aberto,
      ),
      dataQuitacao: map['data_quitacao'] != null
          ? DateTime.parse(map['data_quitacao'] as String)
          : null,
    );
  }
}
