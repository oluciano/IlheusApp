import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilheus_app/features/agua/domain/models/home_month_overview.dart';
import 'package:ilheus_app/features/agua/presentation/providers/database_providers.dart';

final mesesSalvosProvider = FutureProvider<List<HomeMonthOverview>>((ref) async {
  final aberturaRepo = ref.watch(aberturaMesRepositoryProvider);
  final leituraRepo = ref.watch(leituraRepositoryProvider);
  final faturaRepo = ref.watch(faturaCalculadaRepositoryProvider);
  
  if (aberturaRepo == null || leituraRepo == null || faturaRepo == null) return [];
  
  final meses = await aberturaRepo.listarTodosMeses();
  final overviews = <HomeMonthOverview>[];
  
  for (final mesAno in meses) {
    final leituras = await leituraRepo.buscarLeiturasPorMes(mesAno);
    final fatura = await faturaRepo.buscarPorMes(mesAno);
    final isCompleto = await leituraRepo.verificarLeituraCompleta(mesAno);
    
    overviews.add(HomeMonthOverview(
      mesAno: mesAno,
      statusFatura: fatura?.status,
      casasLidas: leituras.length,
      isCompleto: isCompleto,
    ));
  }
  
  // Ordenar por data (assumindo MM/YYYY)
  overviews.sort((a, b) {
    try {
      final partA = a.mesAno.split('/');
      final partB = b.mesAno.split('/');
      final dateA = DateTime(int.parse(partA[1]), int.parse(partA[0]));
      final dateB = DateTime(int.parse(partB[1]), int.parse(partB[0]));
      return dateB.compareTo(dateA); // Recentes primeiro
    } catch (_) {
      return 0;
    }
  });
  
  return overviews;
});
