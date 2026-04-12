import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';
import 'package:ilheus_app/features/agua/domain/usecases/orquestrar_fechamento_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/gerar_pdf_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/fechar_fatura_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/presentation/providers/fechamento_mensal_state.dart';

class FechamentoMensalNotifier extends StateNotifier<FechamentoMensalState> {
  final String mesAno;
  final AberturaMesRepository aberturaRepo;
  final LeituraRepository leituraRepo;
  final FaturaCalculadaRepository faturaRepo;
  final CasaRepository casaRepo;
  final CobrancaRepository cobrancaRepo;
  final OrquestrarFechamentoMensalUseCase orquestrarUseCase;
  final GerarPdfMensalUseCase gerarPdfUseCase;
  final FecharFaturaMensalUseCase auditoriaUseCase;
  final _uuid = const Uuid();

  FechamentoMensalNotifier({
    required this.mesAno,
    required this.aberturaRepo,
    required this.leituraRepo,
    required this.faturaRepo,
    required this.casaRepo,
    required this.cobrancaRepo,
    required this.orquestrarUseCase,
    required this.gerarPdfUseCase,
    required this.auditoriaUseCase,
  }) : super(FechamentoMensalState()) {
    carregarDados();
  }

  Future<void> carregarDados() async {
    state = state.copyWith(status: FechamentoMensalStatus.loading);
    try {
      final contaCorsan = await aberturaRepo.getContaCorsan(mesAno);
      final contaLuz = await aberturaRepo.getContaLuz(mesAno);
      final configuracao = await aberturaRepo.getConfiguracaoMes(mesAno);
      final leituras = await leituraRepo.buscarLeiturasPorMes(mesAno);
      final leituraCompleta = await leituraRepo.verificarLeituraCompleta(mesAno);
      final casas = await casaRepo.buscarAtivas();
      final evento = await orquestrarUseCase.eventoQuiosqueRepository.buscarPorMes(mesAno);
      final inadimplentesAnterior = await cobrancaRepo.buscarInadimplentesAnterior(mesAno);

      // Mapa de id -> numero para sort rápido
      final mapaCasas = {for (var c in casas) c.id: c.numero};
      
      // Ordenar leituras pelo número da casa (1 a 22)
      final leiturasOrdenadas = List<Leitura>.from(leituras)
        ..sort((a, b) {
          final numA = mapaCasas[a.casaId] ?? 0;
          final numB = mapaCasas[b.casaId] ?? 0;
          return numA.compareTo(numB);
        });

      if (contaCorsan == null || contaLuz == null || configuracao == null) {
        state = state.copyWith(
          status: FechamentoMensalStatus.error,
          errorMessage: 'Dados do mês não encontrados.',
        );
        return;
      }

      // PASSO NOVO: Calcular cobranças prévias para exibição na lista
      final cobrancasPrevias = <Cobranca>[];

      // Preparar dados para rateio com isenções
      final casasPagantes = casas.where((c) => !c.isento).toList();
      final qtdCasasPagantes = casasPagantes.length;
      final consumoGeralPagantes = casasPagantes.fold<int>(
        0,
        (sum, c) {
          try {
            final l = leituras.firstWhere((l) => l.casaId == c.id);
            return sum + l.consumoM3;
          } catch (_) {
            return sum; // Caso não encontre leitura, não soma
          }
        },
      );

      for (final casa in casas) {
        final leitura = leituras.firstWhere(
          (l) => l.casaId == casa.id,
          orElse: () => Leitura(
            id: _uuid.v4(),
            casaId: casa.id,
            mesAno: mesAno,
            leituraAnteriorM3: 0,
            leituraAtualM3: 0
          ),
        );

        final cob = orquestrarUseCase.calcularCobrancaUseCase.execute(
          casa: casa,
          leitura: leitura,
          contaCorsan: contaCorsan,
          contaLuz: contaLuz,
          configuracao: configuracao,
          eventoQuiosque: evento,
          debitosAbertos: [], // Não carregamos débitos na prévia para performance
          inadimplentesAnterior: inadimplentesAnterior,
          allLeituras: leituras,
          qtdCasasPagantes: qtdCasasPagantes,
          consumoGeralPagantes: consumoGeralPagantes,
        );
        cobrancasPrevias.add(cob);
      }

      // Mock de fatura rascunho para auditoria prévia se não existir
      var fatura = await faturaRepo.buscarPorMes(mesAno);
      if (fatura == null) {
        fatura = FaturaCalculada(
          id: _uuid.v4(),
          mesAno: mesAno,
          status: StatusFatura.rascunho,
        );
      }

      // Auditoria prévia simplificada (apenas metros para o BLOCO 3)
      final somaMetros = leituras.fold<int>(0, (sum, l) => sum + l.consumoM3);
      final diferenca = contaCorsan.consumoM3 - somaMetros;
      
      StatusAuditoria statusAudit = StatusAuditoria.ok;
      if (diferenca < 0) statusAudit = StatusAuditoria.erro;
      else if (diferenca > 0) statusAudit = StatusAuditoria.alerta;

      final auditoria = AuditoriaFatura(
        faturaId: fatura.id,
        somaMetrosCasas: somaMetros,
        consumoGeralCorsan: contaCorsan.consumoM3,
        diferencaMetros: diferenca,
        somaEsgotoCasas: 0, 
        valorEsgotoCorsan: contaCorsan.valorEsgoto.centavos,
        somaLuzCasas: 0, 
        valorLuzCorsan: contaLuz.valorTotal.centavos,
        totalCobrado: 0,
        status: statusAudit,
      );

      state = state.copyWith(
        status: FechamentoMensalStatus.initial,
        contaCorsan: contaCorsan,
        contaLuz: contaLuz,
        configuracao: configuracao,
        leituras: leiturasOrdenadas,
        casas: casas,
        cobrancas: cobrancasPrevias,
        leituraCompleta: leituraCompleta,
        auditoria: auditoria,
      );
    } catch (e) {
      state = state.copyWith(
        status: FechamentoMensalStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> fecharMes() async {
    state = state.copyWith(status: FechamentoMensalStatus.loading);
    try {
      final faturaRascunho = await faturaRepo.buscarPorMes(mesAno) ?? 
          FaturaCalculada(
            id: _uuid.v4(),
            mesAno: mesAno,
            status: StatusFatura.rascunho,
          );

      await orquestrarUseCase.execute(
        mesAno: mesAno,
        faturaRascunho: faturaRascunho,
        configuracao: state.configuracao!,
      );

      final resultadoPdf = await gerarPdfUseCase.execute(mesAno: mesAno);

      state = state.copyWith(
        status: FechamentoMensalStatus.success,
        pdfGerado: resultadoPdf,
      );
    } on FechamentoMensalException catch (e) {
      state = state.copyWith(
        status: FechamentoMensalStatus.error,
        errorMessage: e.mensagem,
      );
    } catch (e) {
      state = state.copyWith(
        status: FechamentoMensalStatus.error,
        errorMessage: 'Erro inesperado: $e',
      );
    }
  }
}
