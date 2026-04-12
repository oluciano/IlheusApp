import 'dart:convert';

/// Registro de quais casas usaram o quiosque em um determinado mês.
class EventoUsoQuiosque {
  final String id;
  final String mesAno;
  final List<String> casaIds;

  const EventoUsoQuiosque({
    required this.id,
    required this.mesAno,
    required this.casaIds,
  });

  int get qtdCasasQueUsaram => casaIds.length;

  EventoUsoQuiosque copyWith({
    String? id,
    String? mesAno,
    List<String>? casaIds,
  }) {
    return EventoUsoQuiosque(
      id: id ?? this.id,
      mesAno: mesAno ?? this.mesAno,
      casaIds: casaIds ?? this.casaIds,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'mes_ano': mesAno,
      'casa_ids': jsonEncode(casaIds),
    };
  }

  factory EventoUsoQuiosque.fromMap(Map<String, dynamic> map) {
    final rawCasaIds = map['casa_ids'] as String?;
    List<String> casaIds = [];
    
    if (rawCasaIds != null && rawCasaIds.isNotEmpty) {
      if (rawCasaIds.startsWith('[') && rawCasaIds.endsWith(']')) {
        // Formato JSON
        try {
          final decoded = jsonDecode(rawCasaIds) as List;
          casaIds = decoded.cast<String>();
        } catch (_) {
          // Fallback se falhar o parse JSON
          casaIds = rawCasaIds.split(',').where((s) => s.isNotEmpty).toList();
        }
      } else {
        // Formato CSV (usado no seed Julho/2025)
        casaIds = rawCasaIds.split(',').where((s) => s.isNotEmpty).toList();
      }
    }
    
    return EventoUsoQuiosque(
      id: map['id'] as String,
      mesAno: map['mes_ano'] as String,
      casaIds: casaIds,
    );
  }
}
