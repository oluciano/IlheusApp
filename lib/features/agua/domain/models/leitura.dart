import 'package:ilheus_app/features/agua/domain/models/casa.dart';

/// Leitura mensal de hidrômetro de uma casa.
class Leitura {
  final String id;
  final String mesAno;
  final String casaId;
  final int leituraAnteriorM3;
  final int leituraAtualM3;

  const Leitura({
    required this.id,
    required this.mesAno,
    required this.casaId,
    required this.leituraAnteriorM3,
    required this.leituraAtualM3,
  });

  int get consumoM3 => leituraAtualM3 - leituraAnteriorM3;

  Leitura copyWith({
    String? id,
    String? mesAno,
    String? casaId,
    int? leituraAnteriorM3,
    int? leituraAtualM3,
  }) {
    return Leitura(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      casaId: casaId ?? this.casaId,
      leituraAnteriorM3: leituraAnteriorM3 ?? this.leituraAnteriorM3,
      leituraAtualM3: leituraAtualM3 ?? this.leituraAtualM3,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mes_ano': mesAno,
      'casa_id': casaId,
      'leitura_anterior_m3': leituraAnteriorM3,
      'leitura_atual_m3': leituraAtualM3,
    };
  }

  factory Leitura.fromMap(Map<String, dynamic> map) {
    return Leitura(
      id: map['id'] as String,
      mesAno: map['mes_ano'] as String,
      casaId: map['casa_id'] as String,
      leituraAnteriorM3: map['leitura_anterior_m3'] as int,
      leituraAtualM3: map['leitura_atual_m3'] as int,
    );
  }
}
