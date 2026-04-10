import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';

/// Resultado do fechamento mensal completo.
class ResultadoFechamento {
  /// Fatura calculada após fechamento (status: publicado ou rascunho)
  final FaturaCalculada fatura;

  /// Cobranças de todas as 22 casas
  final List<Cobranca> cobrancas;

  /// Resultado da auditoria de fatura
  final AuditoriaFatura auditoria;

  /// Alertas não-bloqueantes (ex: diferença de metros por quiosque)
  final List<String> alertas;

  const ResultadoFechamento({
    required this.fatura,
    required this.cobrancas,
    required this.auditoria,
    this.alertas = const [],
  });
}
