import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';

abstract class FaturaCalculadaRepository {
  Future<void> salvarFatura(FaturaCalculada fatura);
  Future<FaturaCalculada?> buscarPorMes(String mesAno);
  Future<void> atualizarStatus(String faturaId, StatusFatura status);
  Future<List<FaturaCalculada>> listarTodas();
}
