import 'package:ilheus_app/features/agua/domain/models/leitura.dart';

abstract class LeituraRepository {
  Future<void> salvarLeitura(Leitura leitura);
  Future<List<Leitura>> buscarLeiturasPorMes(String mesAno);
  Future<Leitura?> buscarLeituraCasa(String casaId, String mesAno);
  Future<bool> verificarLeituraCompleta(String mesAno);
}
