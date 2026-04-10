import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/status_fatura.dart';

/// Resultado do fechamento de fatura.
class ResultadoFechamentoFatura {
  final FaturaCalculada fatura;
  final AuditoriaFatura auditoria;

  const ResultadoFechamentoFatura({
    required this.fatura,
    required this.auditoria,
  });
}

/// UseCase: Valida e publica fatura mensal de cobrança.
///
/// Executa auditoria completa antes de permitir publicação:
/// - Soma de metros (casas vs. CORSAN)
/// - Soma de esgoto (casas vs. CORSAN)
/// - Soma de luz (casas vs. CORSAN)
/// - Verifica se todas as 22 casas têm cobrança
///
/// Status:
/// - OK: somas batem perfeitamente
/// - ALERTA: há discrepâncias (ex: quiosque/vazamento), mas permite publicar
/// - ERRO: impossível publicar (ex: soma > consumo)
class FecharFaturaMensalUseCase {
  /// Número exato de casas residenciais (1-22).
  static const int numCasasEsperado = 22;

  /// Executa fechamento e auditoria de fatura.
  ///
  /// Parâmetros:
  /// - [cobrancas]: Cobranças de todas as 22 casas (deve ter exatamente 22)
  /// - [contaCorsan]: Conta CORSAN (fonte de verdade de metros e esgoto)
  /// - [contaLuz]: Conta de luz (fonte de verdade de luz)
  /// - [faturaRascunho]: Fatura em estado rascunho
  /// - [leituras]: Leituras de água de todas as casas (para validar metros)
  ///
  /// Validações executadas:
  /// 1. Número de casas = 22
  /// 2. Soma metros casas vs. consumo CORSAN (diferença > 0 = alerta)
  /// 3. Soma esgoto casas vs. CORSAN (diferença != 0 = alerta ou erro)
  /// 4. Soma luz casas vs. CORSAN (diferença != 0 = alerta ou erro)
  ///
  /// Retorna: ResultadoFechamentoFatura com fatura e auditoria.
  /// Pode ser ERRO (bloqueia publicação) ou ALERTA (permite com confirmação).
  ResultadoFechamentoFatura execute({
    required List<Cobranca> cobrancas,
    required ContaCorsan contaCorsan,
    required ContaLuz contaLuz,
    required FaturaCalculada faturaRascunho,
    required List<Leitura> leituras,
  }) {
    // Validação 1: Número de casas
    if (cobrancas.length != numCasasEsperado) {
      throw ArgumentError(
        'Fatura deve ter exatamente $numCasasEsperado cobranças. '
        'Encontradas: ${cobrancas.length}',
      );
    }

    // Cálculo de somas
    final somaMetrosCasas = _somaMetrosCasas(leituras);
    final somaEsgotoCasas = _somaCentavos(
      cobrancas,
      (cob) => cob.valorEsgoto,
    );
    final somaLuzCasas = _somaCentavos(
      cobrancas,
      (cob) => cob.valorLuz,
    );
    final totalCobrado = _somaCentavos(
      cobrancas,
      (cob) => cob.valorTotal,
    );

    final consumoGeralCorsan = contaCorsan.consumoM3;
    final valorEsgotoCorsan = contaCorsan.valorEsgoto.centavos;
    final valorLuzCorsan = contaLuz.valorTotal.centavos;

    // Diferenças
    final diferencaMetros = consumoGeralCorsan - somaMetrosCasas;
    final diferencaEsgoto = somaEsgotoCasas - valorEsgotoCorsan;
    final diferencaLuz = somaLuzCasas - valorLuzCorsan;

    // Determinar status da auditoria
    final statusAuditoria = _determinarStatus(
      diferencaMetros,
      diferencaEsgoto,
      diferencaLuz,
    );

    final mensagem = _construirMensagem(
      diferencaMetros,
      diferencaEsgoto,
      diferencaLuz,
      statusAuditoria,
    );

    final auditoria = AuditoriaFatura(
      faturaId: faturaRascunho.id,
      somaMetrosCasas: somaMetrosCasas,
      consumoGeralCorsan: consumoGeralCorsan,
      diferencaMetros: diferencaMetros,
      somaEsgotoCasas: somaEsgotoCasas,
      valorEsgotoCorsan: valorEsgotoCorsan,
      somaLuzCasas: somaLuzCasas,
      valorLuzCorsan: valorLuzCorsan,
      totalCobrado: totalCobrado,
      status: statusAuditoria,
      mensagem: mensagem,
    );

    // Status ERRO bloqueia publicação
    final statusFatura = statusAuditoria == StatusAuditoria.erro
        ? StatusFatura.rascunho
        : StatusFatura.publicado;

    final faturaAtualizada = faturaRascunho.copyWith(
      status: statusFatura,
    );

    return ResultadoFechamentoFatura(
      fatura: faturaAtualizada,
      auditoria: auditoria,
    );
  }

  /// Soma metros de água de todas as leituras.
  int _somaMetrosCasas(List<Leitura> leituras) {
    return leituras.fold<int>(0, (sum, leitura) => sum + leitura.consumoM3);
  }

  /// Soma um campo de centavos de todas as cobranças.
  int _somaCentavos(
    List<Cobranca> cobrancas,
    int Function(Cobranca) extractor,
  ) {
    return cobrancas.fold<int>(0, (sum, cob) => sum + extractor(cob));
  }

  /// Determina o status da auditoria baseado nas diferenças.
  ///
  /// OK: Todas as diferenças = 0
  /// ERRO: Soma > consumo (impossível) OU diferenças absurdas em esgoto/luz
  /// ALERTA: Diferenças pequenas (quiosque, vazamento, arredondamento)
  StatusAuditoria _determinarStatus(
    int diferencaMetros,
    int diferencaEsgoto,
    int diferencaLuz,
  ) {
    // Erro: soma de casas > consumo geral
    if (diferencaMetros < 0) {
      return StatusAuditoria.erro;
    }

    // Erro: esgoto não bate (diferença > 1 centavo = arredondamento)
    if (diferencaEsgoto.abs() > 1) {
      return StatusAuditoria.erro;
    }

    // Erro: luz não bate (diferença > 1 centavo = arredondamento)
    if (diferencaLuz.abs() > 1) {
      return StatusAuditoria.erro;
    }

    // Alerta: diferença positiva de metros (quiosque/vazamento)
    if (diferencaMetros > 0) {
      return StatusAuditoria.alerta;
    }

    // OK: Tudo batendo
    return StatusAuditoria.ok;
  }

  /// Constrói mensagem descritiva de problemas encontrados.
  String? _construirMensagem(
    int diferencaMetros,
    int diferencaEsgoto,
    int diferencaLuz,
    StatusAuditoria status,
  ) {
    if (status == StatusAuditoria.ok) {
      return null;
    }

    final buffer = <String>[];

    if (diferencaMetros < 0) {
      buffer.add(
        'ERRO: Soma de metros das casas (${-diferencaMetros} m³) '
        'maior que consumo CORSAN. Impossível publicar.',
      );
    } else if (diferencaMetros > 0) {
      buffer.add(
        'ALERTA: Diferença de $diferencaMetros m³ entre CORSAN e casas. '
        'Possível: quiosque, vazamento ou hidrômetro com problema.',
      );
    }

    if (diferencaEsgoto.abs() > 1) {
      buffer.add('ERRO: Soma esgoto não bate com CORSAN (diferença: '
          '${diferencaEsgoto.abs()} centavos)');
    }

    if (diferencaLuz.abs() > 1) {
      buffer.add('ERRO: Soma luz não bate com CORSAN (diferença: '
          '${diferencaLuz.abs()} centavos)');
    }

    return buffer.isNotEmpty ? buffer.join('\n') : null;
  }
}
