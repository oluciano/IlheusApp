import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';

/// Fatura calculada pelo administrador para um mês.
class FaturaCalculada {
  final String id;
  final String mesAno;
  final StatusFatura status;

  const FaturaCalculada({
    required this.id,
    required this.mesAno,
    required this.status,
  });

  bool get isPublicado => status == StatusFatura.publicado;
  bool get isRascunho => status == StatusFatura.rascunho;

  FaturaCalculada copyWith({
    String? id,
    String? mesAno,
    StatusFatura? status,
  }) {
    return FaturaCalculada(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mes_ano': mesAno,
      'status': status.name,
    };
  }

  factory FaturaCalculada.fromMap(Map<String, dynamic> map) {
    return FaturaCalculada(
      id: map['id'] as String,
      mesAno: map['mes_ano'] as String,
      status: StatusFatura.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => StatusFatura.rascunho,
      ),
    );
  }
}
