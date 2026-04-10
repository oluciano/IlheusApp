import 'package:ilheus_app/features/agua/domain/models/casa.dart';

abstract class CasaRepository {
  Future<void> salvarCasa(Casa casa);
  Future<List<Casa>> buscarTodas();
  Future<Casa?> buscarPorNumero(int numero);
  Future<List<Casa>> buscarAtivas();
  Future<void> atualizarIsencao({
    required String casaId,
    required bool isento,
  });
  Future<void> atualizarAdministrador({
    required String casaId,
    required bool ehAdministrador,
  });
}
