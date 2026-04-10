import 'package:ilheus_app/features/agua/domain/models/pagamento.dart';

abstract class PagamentoRepository {
  Future<void> registrarPagamento(Pagamento pagamento);
  Future<List<Pagamento>> buscarPagamentosPorCobranca(String cobrancaId);
}
