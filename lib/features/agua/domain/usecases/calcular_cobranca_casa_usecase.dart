import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/configuracao_mes.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/modelo_juros.dart';
import 'package:ilheus_app/features/agua/domain/models/status_cobranca.dart';

/// UseCase: Calcula cobrança completa de uma casa para um mês.
///
/// Aplica todas as regras de rateio, isenção, juros e débitos anteriores.
/// Retorna Cobranca com breakdown detalhado em centavos.
class CalcularCobrancaCasaUseCase {
  /// Número máximo de casas residenciais (sem contar quiosque).
  static const int numCasasResidenciais = 22;

  /// Número do quiosque.
  static const int numQuiosque = 23;

  /// Executa o cálculo de cobrança para uma casa.
  ///
  /// Parâmetros:
  /// - [casa]: Casa com flags de isenção
  /// - [leitura]: Leitura de hidrômetro (consumo em m³)
  /// - [contaCorsan]: Conta CORSAN com somas e valores
  /// - [contaLuz]: Conta de luz com valor total
  /// - [configuracao]: Configuração do mês (condôminio, modelo de juros)
  /// - [eventoQuiosque]: Evento de uso do quiosque (nullable)
  /// - [debitosAbertos]: Débitos anteriores em aberto da casa
  /// - [inadimplentesAnterior]: Número de casas inadimplentes no mês anterior (para juros igualitário)
  /// - [dataPagamento]: Data de pagamento (null se não pagou). Dia 10 ou antes = sem juros
  /// - [allLeituras]: Todas as leituras do mês (para cálculo de quiosque)
  /// - [somasDiasInadimplentes]: Soma total de dias de atraso de todos os inadimplentes (para juros proporcional)
  /// - [diasAtrasoCasa]: Dias de atraso desta casa (null = pagou ou está atualizado, para juros proporcional)
  ///
  /// Retorna: Cobranca com todos os componentes calculados e breakdown completo.
  Cobranca execute({
    required Casa casa,
    required Leitura leitura,
    required ContaCorsan contaCorsan,
    required ContaLuz contaLuz,
    required ConfiguracaoMes configuracao,
    EventoUsoQuiosque? eventoQuiosque,
    required List<Debito> debitosAbertos,
    required int inadimplentesAnterior,
    DateTime? dataPagamento,
    required List<Leitura> allLeituras,
    int somasDiasInadimplentes = 0,
    int? diasAtrasoCasa,
  }) {
    // Validações básicas
    if (leitura.consumoM3 < 0) {
      throw ArgumentError('Consumo não pode ser negativo');
    }

    // Cálculo de cada componente
    final valorAgua =
        configuracao.componenteAguaAtivo && !casa.isentoAgua
            ? _calcularAgua(
                leitura.consumoM3,
                contaCorsan.consumoM3,
                contaCorsan.valorAgua.centavos,
              )
            : 0;

    final valorQuiosque =
        configuracao.componenteAguaAtivo && eventoQuiosque != null
            ? _calcularQuiosque(
                casa.numero,
                contaCorsan.valorAgua.centavos,
                eventoQuiosque,
              )
            : 0;

    final valorEsgoto =
        configuracao.componenteEsgotoAtivo && !casa.isentoEsgoto
            ? _calcularIgualitario(contaCorsan.valorEsgoto.centavos)
            : 0;

    final valorServicoBasico = configuracao.componenteServicoBasicoAtivo &&
            !casa.isentoServicoBasico
        ? _calcularIgualitario(contaCorsan.valorServicoBasico.centavos)
        : 0;

    final valorLuz =
        configuracao.componenteLuzAtivo && !casa.isentoLuz
            ? _calcularIgualitario(contaLuz.valorTotal.centavos)
            : 0;

    final valorCond =
        configuracao.componenteCondAtivo && !casa.isentoCond
            ? configuracao.valorCond.centavos
            : 0;

    final valorJuros = _calcularJuros(
      contaCorsan.valorJuros?.centavos ?? 0,
      configuracao.modeloJuros,
      inadimplentesAnterior,
      dataPagamento,
      contaCorsan.vencimento,
      somasDiasInadimplentes,
      diasAtrasoCasa,
    );

    // Débitos anteriores em aberto
    final valorDebitos = debitosAbertos.fold<int>(
      0,
      (sum, debito) => sum + (debito.isAberto ? debito.valorCentavos : 0),
    );

    // Total = soma de todos os componentes
    final valorTotal = valorAgua +
        valorEsgoto +
        valorServicoBasico +
        valorLuz +
        valorCond +
        valorQuiosque +
        valorJuros +
        valorDebitos;

    return Cobranca(
      id: '',
      faturaId: '',
      casaId: leitura.casaId,
      valorAgua: valorAgua,
      valorEsgoto: valorEsgoto,
      valorServicoBasico: valorServicoBasico,
      valorLuz: valorLuz,
      valorCond: valorCond,
      valorQuiosque: valorQuiosque,
      valorJuros: valorJuros,
      valorDebitos: valorDebitos,
      valorTotal: valorTotal,
      status: StatusCobranca.pendente,
    );
  }

  /// Calcula rateio proporcional de água.
  ///
  /// água_casa = (consumo_casa / consumo_geral) * valor_agua
  ///
  /// Arredondamento: floor (sempre para baixo) em centavo.
  int _calcularAgua(int consumoCasaM3, int consumoGeralM3, int valorAgua) {
    if (consumoGeralM3 == 0) return 0;
    // floor: sempre para baixo em centavo
    final valor = (consumoCasaM3 * valorAgua) / consumoGeralM3;
    return valor.floor();
  }

  /// Calcula rateio do quiosque (se casa usou).
  ///
  /// agua_quiosque = (valor_agua / 23) / qtd_casas_que_usaram
  ///
  /// Denominador 23 pois esgoto e serviço básico não são cobrados do quiosque.
  int _calcularQuiosque(
    int numeroOpcionCasa,
    int valorAgua,
    EventoUsoQuiosque evento,
  ) {
    // Verifica se casa usou quiosque
    if (!evento.casaIds.contains('casa-$numeroOpcionCasa')) {
      return 0;
    }

    // Cota 23 dividida entre quem usou
    final qtdQueUsaram = evento.qtdCasasQueUsaram;
    if (qtdQueUsaram == 0) return 0;

    final cotaQuiosque = (valorAgua / 23).floor();
    final valor = (cotaQuiosque / qtdQueUsaram).floor();
    return valor;
  }

  /// Calcula rateio igualitário (esgoto, serviço básico, luz).
  ///
  /// componente = valor_total / 22
  ///
  /// Arredondamento: floor em centavo.
  int _calcularIgualitario(int valorTotal) {
    return (valorTotal / numCasasResidenciais).floor();
  }

  /// Calcula juros conforme modelo configurado.
  ///
  /// IGUALITÁRIO: juros_casa = total_juros / qtd_inadimplentes
  /// PROPORCIONAL_DIAS: juros_casa = (dias_atraso_casa / soma_dias_todos) * total_juros
  ///
  /// Regra: se dataPagamento <= 10º dia do mês, sem juros (ambos modelos).
  int _calcularJuros(
    int totalJurosCentavos,
    ModeloJuros modelo,
    int qtdInadimplentes,
    DateTime? dataPagamento,
    DateTime? dataVencimento,
    int somasDiasInadimplentes,
    int? diasAtrasoCasa,
  ) {
    // Se pagou até dia 10, sem juros (regra universal)
    if (dataPagamento != null && dataPagamento.day <= 10) {
      return 0;
    }

    if (totalJurosCentavos == 0) {
      return 0;
    }

    if (modelo == ModeloJuros.igualitario) {
      // Modelo igualitário: divide igualmente entre inadimplentes
      if (qtdInadimplentes == 0) return 0;
      return (totalJurosCentavos / qtdInadimplentes).floor();
    } else {
      // Modelo proporcional por dias de atraso
      if (somasDiasInadimplentes == 0 || diasAtrasoCasa == null) {
        return 0;
      }

      // juros_casa = (dias_atraso_casa / soma_dias_todos) * total_juros
      final valor = (totalJurosCentavos * diasAtrasoCasa) / somasDiasInadimplentes;
      return valor.floor();
    }
  }
}
