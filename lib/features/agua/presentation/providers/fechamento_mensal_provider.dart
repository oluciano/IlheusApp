import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/presentation/providers/fechamento_mensal_notifier.dart';
import 'package:ilheus_app/features/agua/presentation/providers/fechamento_mensal_state.dart';
import 'package:ilheus_app/features/agua/domain/usecases/orquestrar_fechamento_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/gerar_pdf_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/domain/usecases/fechar_fatura_mensal_usecase.dart';
import 'package:ilheus_app/features/agua/data/repositories/repository_locator.dart';
import 'package:ilheus_app/features/agua/domain/usecases/calcular_cobranca_casa_usecase.dart';

final fechamentoMensalProvider = StateNotifierProvider.autoDispose.family<
    FechamentoMensalNotifier, FechamentoMensalState, String>((ref, mesAno) {
  
  // Repositories
  final casaRepo = RepositoryLocator.casa!;
  final leituraRepo = RepositoryLocator.leitura!;
  final aberturaRepo = RepositoryLocator.aberturaMes!;
  final faturaRepo = RepositoryLocator.faturaCalculada!;
  final cobrancaRepo = RepositoryLocator.cobranca!;
  final debitoRepo = RepositoryLocator.debito!;
  final eventoRepo = RepositoryLocator.eventoUsoQuiosque!;

  // UseCases
  final calcularCobrancaUC = CalcularCobrancaCasaUseCase();
  
  final fecharFaturaUC = FecharFaturaMensalUseCase();

  final orquestrarUC = OrquestrarFechamentoMensalUseCase(
    casaRepository: casaRepo,
    leituraRepository: leituraRepo,
    aberturaMesRepository: aberturaRepo,
    faturaRepository: faturaRepo,
    cobrancaRepository: cobrancaRepo,
    debitoRepository: debitoRepo,
    eventoQuiosqueRepository: eventoRepo,
    calcularCobrancaUseCase: calcularCobrancaUC,
    fecharFaturaUseCase: fecharFaturaUC,
  );

  final gerarPdfUC = GerarPdfMensalUseCase(
    casaRepository: casaRepo,
    leituraRepository: leituraRepo,
    aberturaMesRepository: aberturaRepo,
    cobrancaRepository: cobrancaRepo,
    faturaRepository: faturaRepo,
    diretorioProvider: ref.read(diretorioProvider),
  );

  return FechamentoMensalNotifier(
    mesAno: mesAno,
    aberturaRepo: aberturaRepo,
    leituraRepo: leituraRepo,
    faturaRepo: faturaRepo,
    casaRepo: casaRepo,
    cobrancaRepo: cobrancaRepo,
    orquestrarUseCase: orquestrarUC,
    gerarPdfUseCase: gerarPdfUC,
    auditoriaUseCase: fecharFaturaUC,
  );
});

// Provider para o DiretorioProvider (PDF)
final diretorioProvider = Provider<DiretorioProvider>((ref) {
  return DefaultDiretorioProvider();
});

class DefaultDiretorioProvider implements DiretorioProvider {
  @override
  Future<Directory> getDiretorioDownloads() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        // Tenta pegar o diretório de downloads, ou fallback para documentos
        if (Platform.isAndroid) {
          final dir = await getExternalStorageDirectory();
          if (dir != null) {
            final downloads = Directory('${dir.parent.parent.parent.parent.path}/Download');
            if (await downloads.exists()) return downloads;
          }
        }
        return await getApplicationDocumentsDirectory();
      }
    } catch (_) {}
    return Directory.current;
  }
}
