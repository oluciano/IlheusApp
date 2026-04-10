import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';

abstract class CobrancaRepository {
  Future<void> salvarCobranca(Cobranca cobranca);
  Future<List<Cobranca>> buscarCobrancasPorFatura(String faturaId);
  Future<Cobranca?> buscarCobrancaCasa(String casaId, String mesAno);
  Future<void> atualizarStatus(String cobrancaId, StatusCobranca status);
}
