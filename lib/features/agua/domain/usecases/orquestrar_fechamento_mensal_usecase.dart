import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/casa.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/configuracao_mes.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/debito.dart';
import 'package:ilheus_app/features/agua/domain/models/erro_fechamento.dart';
import 'package:ilheus_app/features/agua/domain/models/evento_uso_quiosque.dart';
import 'package:ilheus_app/features/agua/domain/models/fatura_calculada.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/models/resultado_fechamento.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/debito_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/evento_uso_quiosque_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/domain/usecases/calcular_cobranca_casa_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/fechar_fatura_mensal_usecase.dart';

/// Exception levantada quando o fechamento mensal falha.
class FechamentoMensalException implements Exception {
  final ErroFechamento erro;
  final String mensagem;

  FechamentoMensalException({
    required this.erro,
    required this.mensagem,
  });

  @override
  String toString() => 'FechamentoMensalException: $mensagem';
}

/// UseCase: Orquestra o fechamento mensal completo.
///
/// Este é o coração do sistema — une todos os outros UseCases e repositories
/// para executar o fechamento mensal em 4 passos obrigatórios:
///
/// PASSO 1: Validar pré-condições
/// - 22 casas ativas cadastradas?
/// - ContaCORSAN do mês existe?
/// - ContaLuz do mês existe?
/// - Todas as 22 casas têm leitura?
///
/// PASSO 2: Calcular cobrança de cada casa
/// - Executa CalcularCobrancaCasaUseCase para cada casa
/// - Busca débitos abertos
/// - Aplica EventoUsoQuiosque
/// - Aplica juros conforme ConfiguracaoMes
///
/// PASSO 3: Fechar fatura
/// - Executa FecharFaturaMensalUseCase
/// - Valida auditoria (metros, esgoto, luz)
/// - Status ERRO → lança exceção, não persiste
/// - Status ALERTA → persiste com flag de alerta
///
/// PASSO 4: Persistir
/// - Salva todas as Cobrancas no banco
/// - Atualiza FaturaCalculada para status publicado
class OrquestrarFechamentoMensalUseCase {
  /// Número exato de casas residenciais (1-22).
  static const int numCasasEsperado = 22;

  final CasaRepository casaRepository;
  final LeituraRepository leituraRepository;
  final AberturaMesRepository aberturaMesRepository;
  final FaturaCalculadaRepository faturaRepository;
  final CobrancaRepository cobrancaRepository;
  final DebitoRepository debitoRepository;
  final EventoUsoQuiosqueRepository eventoQuiosqueRepository;

  final CalcularCobrancaCasaUseCase calcularCobrancaUseCase;
  final FecharFaturaMensalUseCase fecharFaturaUseCase;

  OrquestrarFechamentoMensalUseCase({
    required this.casaRepository,
    required this.leituraRepository,
    required this.aberturaMesRepository,
    required this.faturaRepository,
    required this.cobrancaRepository,
    required this.debitoRepository,
    required this.eventoQuiosqueRepository,
    required this.calcularCobrancaUseCase,
    required this.fecharFaturaUseCase,
  });

  /// Executa o fechamento mensal completo dentro de uma transação SQLite.
  ///
  /// Parâmetros:
  /// - [mesAno]: Mês no formato 'YYYY-MM' (ex: '2026-04')
  /// - [faturaRascunho]: Fatura em estado rascunho a ser fechada
  /// - [configuracao]: Configuração do mês (componentes, juros, condôminio)
  ///
  /// Retorna: ResultadoFechamento com fatura, cobrancas, auditoria e alertas.
  ///
  /// Lança FechamentoMensalException se alguma validação falhar.
  ///
  /// Se uma exceção ocorrer durante o fechamento, toda a transação é desfeita
  /// (rollback automático) garantindo consistência.
  Future<ResultadoFechamento> execute({
    required String mesAno,
    required FaturaCalculada faturaRascunho,
    required ConfiguracaoMes configuracao,
  }) async {
    return aberturaMesRepository.runInTransaction<ResultadoFechamento>(() async {
      // PASSO 1: Validar pré-condições
      final casasAtivas = await casaRepository.buscarAtivas();
      if (casasAtivas.length < numCasasEsperado) {
        throw FechamentoMensalException(
          erro: ErroFechamento.casasInsuficientes,
          mensagem: 'Apenas ${casasAtivas.length} casas ativas. '
              'Esperadas $numCasasEsperado.',
        );
      }

      final contaCorsan = await aberturaMesRepository.getContaCorsan(mesAno);
      if (contaCorsan == null) {
        throw FechamentoMensalException(
          erro: ErroFechamento.contaCorsanAusente,
          mensagem: 'ContaCORSAN não encontrada para o mês $mesAno.',
        );
      }

      final contaLuz = await aberturaMesRepository.getContaLuz(mesAno);
      if (contaLuz == null) {
        throw FechamentoMensalException(
          erro: ErroFechamento.contaLuzAusente,
          mensagem: 'ContaLuz não encontrada para o mês $mesAno.',
        );
      }

      final leituraCompleta = await leituraRepository.verificarLeituraCompleta(
        mesAno,
      );
      if (!leituraCompleta) {
        throw FechamentoMensalException(
          erro: ErroFechamento.leiturasIncompletas,
          mensagem: 'Uma ou mais casas não têm leitura registrada no mês $mesAno.',
        );
      }

      // PASSO 2: Calcular cobrança de cada casa
      // Primeiro, marcar como inadimplentes todas as cobranças do mês anterior
      // que venceram e ainda estão pendentes (vencimento = dia 10 do mês seguinte)
      await cobrancaRepository.marcarInadimplentesPorVencimento(mesAno);

      final leituras = await leituraRepository.buscarLeiturasPorMes(mesAno);
      final evento = await eventoQuiosqueRepository.buscarPorMes(mesAno);
      final inadimplentesAnterior = await cobrancaRepository
          .buscarInadimplentesAnterior(mesAno);

      // --- Lógica de Redistribuição de Centavos ---
      // 1. Identificar quem paga (casas ativas e não-isentas)
      final casasPagantes = casasAtivas.where((c) => !c.isento).toList();
      final numPagantes = casasPagantes.length;

      if (numPagantes == 0) {
        throw FechamentoMensalException(
          erro: ErroFechamento.auditoriaFalhou,
          mensagem: 'Não há casas pagantes para este mês.',
        );
      }

      // 2. Preparar Rateio Equalitário (Luz, Esgoto, ServBasico)
      // Quota base e resto para distribuir 1 centavo extra
      final quotaLuz = contaLuz.valorTotal.centavos ~/ numPagantes;
      final restoLuz = contaLuz.valorTotal.centavos % numPagantes;

      final quotaEsgoto = contaCorsan.valorEsgoto.centavos ~/ numPagantes;
      final restoEsgoto = contaCorsan.valorEsgoto.centavos % numPagantes;

      final quotaServBasico = contaCorsan.valorServicoBasico.centavos ~/ numPagantes;
      final restoServBasico = contaCorsan.valorServicoBasico.centavos % numPagantes;

      // 3. Preparar Rateio Proporcional (Água)
      final consumoTotalCasas = leituras.fold<int>(0, (sum, l) => sum + l.consumoM3);
      // Denominador para água é o consumo total das casas pagantes (não o geral da CORSAN, 
      // pois perdas/quiosque são tratados separadamente ou pelo fundo)
      // NOTA: Se usarmos consumoGeralCorsan como denominador, a soma nunca bateria se houvesse diferença.
      // Para a auditoria de centavos bater, usamos o consumo somado das casas como base do rateio proporcional.
      final consumoPagantes = casasPagantes.fold<int>(0, (sum, c) {
        final l = leituras.firstWhere((l) => l.casaId == c.id);
        return sum + l.consumoM3;
      });

      final cobrancas = <Cobranca>[];
      int centavosAguaDistribuidos = 0;
      int centavosEsgotoDistribuidos = 0;
      int centavosServDistribuidos = 0;
      int centavosLuzDistribuidos = 0;

      // Ordenar casas por numero para distribuição de centavos ser determinística (01, 02...)
      casasAtivas.sort((a, b) => a.numero.compareTo(b.numero));

      int indexPagante = 0;
      for (final casa in casasAtivas) {
        final leitura = leituras.firstWhere(
          (l) => l.casaId == casa.id,
          orElse: () => throw FechamentoMensalException(
            erro: ErroFechamento.leiturasIncompletas,
            mensagem: 'Leitura não encontrada para casa ${casa.numero}.',
          ),
        );

        final debitosAbertos = await debitoRepository.buscarDebitosAbertos(
          casa.id,
        );

        // Calcula cobrança base
        var cobranca = calcularCobrancaUseCase.execute(
          casa: casa,
          leitura: leitura,
          contaCorsan: contaCorsan,
          contaLuz: contaLuz,
          configuracao: configuracao,
          eventoQuiosque: evento,
          debitosAbertos: debitosAbertos,
          inadimplentesAnterior: inadimplentesAnterior,
          dataPagamento: null,
          allLeituras: leituras,
          qtdCasasPagantes: numPagantes,
          consumoGeralPagantes: consumoPagantes,
        );

        // Ajusta componentes equalitários com redistribuição de centavos
        if (!casa.isento) {
          final extraLuz = indexPagante < restoLuz ? 1 : 0;
          final extraEsgoto = indexPagante < restoEsgoto ? 1 : 0;
          final extraServ = indexPagante < restoServBasico ? 1 : 0;

          cobranca = cobranca.copyWith(
            valorLuz: quotaLuz + extraLuz,
            valorEsgoto: quotaEsgoto + extraEsgoto,
            valorServicoBasico: quotaServBasico + extraServ,
          );
          
          centavosLuzDistribuidos += (quotaLuz + extraLuz);
          centavosEsgotoDistribuidos += (quotaEsgoto + extraEsgoto);
          centavosServDistribuidos += (quotaServBasico + extraServ);
          
          indexPagante++;
        }

        cobrancas.add(cobranca);
      }

      // 4. Ajuste final do Rateio de Água (Proporcional)
      // Como a água é proporcional, o floor() acumulado gera uma diferença.
      // Pegamos a diferença total e aplicamos nas casas com maior consumo.
      final somaAguaCalculada = cobrancas.fold<int>(0, (sum, c) => sum + c.valorAgua);
      int diferencaAguaCents = contaCorsan.valorAgua.centavos - somaAguaCalculada;
      
      if (diferencaAguaCents > 0) {
        // Distribui os centavos restantes entre as casas pagantes (1 centavo cada)
        // até zerar a diferença.
        for (int i = 0; i < cobrancas.length && diferencaAguaCents > 0; i++) {
          final casa = casasAtivas.firstWhere((c) => c.id == cobrancas[i].casaId);
          if (!casa.isento && cobrancas[i].valorAgua > 0) {
            cobrancas[i] = cobrancas[i].copyWith(
              valorAgua: cobrancas[i].valorAgua + 1,
              valorTotal: cobrancas[i].valorTotal + 1,
            );
            diferencaAguaCents--;
          }
        }
      }

      // Recalcular totais após ajustes de centavos
      for (int i = 0; i < cobrancas.length; i++) {
        final c = cobrancas[i];
        cobrancas[i] = c.copyWith(
          valorTotal: c.valorAgua + c.valorEsgoto + c.valorServicoBasico + 
                      c.valorLuz + c.valorCond + c.valorQuiosque + c.valorJuros,
        );
      }

      // PASSO 3: Fechar fatura
      final resultadoFechamento = fecharFaturaUseCase.execute(
        cobrancas: cobrancas,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        faturaRascunho: faturaRascunho,
        leituras: leituras,
      );

      // Se auditoria falhou com erro, não persiste
      if (resultadoFechamento.auditoria.status == StatusAuditoria.erro) {
        throw FechamentoMensalException(
          erro: ErroFechamento.auditoriaFalhou,
          mensagem: resultadoFechamento.auditoria.mensagem ??
              'Auditoria de fatura falhou.',
        );
      }

      // PASSO 4: Persistir
      // Garantir que a fatura rascunho existe no banco antes de salvar cobranças
      await faturaRepository.salvarFatura(faturaRascunho);

      // Injetar faturaId real em cada cobrança antes de persistir
      for (final cobranca in cobrancas) {
        final cobrancaComFatura = cobranca.copyWith(
          faturaId: resultadoFechamento.fatura.id,
        );
        await cobrancaRepository.salvarCobranca(cobrancaComFatura);
      }

      await faturaRepository.atualizarStatus(
        resultadoFechamento.fatura.id,
        resultadoFechamento.fatura.status,
      );

      // Montar resultado final com alertas
      final alertas = <String>[];
      if (resultadoFechamento.auditoria.status == StatusAuditoria.alerta) {
        if (resultadoFechamento.auditoria.mensagem != null) {
          alertas.add(resultadoFechamento.auditoria.mensagem!);
        }
      }

      return ResultadoFechamento(
        fatura: resultadoFechamento.fatura,
        cobrancas: cobrancas,
        auditoria: resultadoFechamento.auditoria,
        alertas: alertas,
      );
    });
  }
}
