import 'package:ilheus_app/features/agua/domain/models/debito.dart';

abstract class DebitoRepository {
  Future<void> salvarDebito(Debito debito);
  Future<List<Debito>> buscarDebitosAbertos(String casaId);
  Future<void> quitar(String debitoId, DateTime dataQuitacao);
}
