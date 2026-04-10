import 'package:ilheus_app/features/agua/domain/models/casa.dart';

abstract class CasaRepository {
  Future<void> salvarCasa(Casa casa);
  Future<List<Casa>> buscarTodas();
  Future<Casa?> buscarPorNumero(int numero);
  Future<List<Casa>> buscarAtivas();
  Future<void> atualizarIsencoes({
    required String casaId,
    required bool isentoAgua,
    required bool isentoEsgoto,
    required bool isentoServicoBasico,
    required bool isentoLuz,
    required bool isentoCond,
  });
}
