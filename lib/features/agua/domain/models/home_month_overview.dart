import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';

class HomeMonthOverview {
  final String mesAno;
  final StatusFatura? statusFatura;
  final int casasLidas;
  final int totalCasas;
  final bool isCompleto;

  const HomeMonthOverview({
    required this.mesAno,
    this.statusFatura,
    this.casasLidas = 0,
    this.totalCasas = 22,
    this.isCompleto = false,
  });

  bool get isFechado => statusFatura == StatusFatura.publicado;
  double get progresso => totalCasas > 0 ? casasLidas / totalCasas : 0;
}
