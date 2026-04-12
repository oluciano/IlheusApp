import 'dart:io';

import 'package:ilheus_app/features/agua/data/services/pdf_service.dart';
import 'package:ilheus_app/features/agua/domain/models/auditoria_fatura.dart';
import 'package:ilheus_app/features/agua/domain/models/cobranca.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_corsan.dart';
import 'package:ilheus_app/features/agua/domain/models/conta_luz.dart';
import 'package:ilheus_app/features/agua/domain/models/leitura.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/casa_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/cobranca_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/fatura_calculada_repository.dart';
import 'package:ilheus_app/features/agua/domain/repositories/leitura_repository.dart';

/// Exceção levantada quando a geração de PDF falha.
class GerarPdfException implements Exception {
  final String mensagem;

  GerarPdfException(this.mensagem);

  @override
  String toString() => 'GerarPdfException: $mensagem';
}

/// Resultado da geração do PDF.
class ResultadoPdf {
  /// Caminho absoluto do arquivo PDF gerado.
  final String caminhoArquivo;

  /// Tamanho do arquivo em bytes.
  final int tamanhoBytes;

  /// Bytes reais do PDF para visualização/compartilhamento imediato.
  final List<int> pdfBytes;

  const ResultadoPdf({
    required this.caminhoArquivo,
    required this.tamanhoBytes,
    required this.pdfBytes,
  });
}

/// Abstração para obtenção de diretório de documentos (permite mock em testes).
abstract class DiretorioProvider {
  Future<Directory> getDiretorioDownloads();
}

/// UseCase: Gera o PDF mensal do condomínio.
///
/// O PDF substitui o panfleto manuscrito — contém:
/// - Resumo das contas (CORSAN, Luz, Condomínio)
/// - Tabela de rateio por casa (01 a 22)
/// - Auditoria de fechamento (metros, totais)
///
/// Arquivo salvo em: Download/ilheus_MM_YYYY.pdf
class GerarPdfMensalUseCase {
  final CasaRepository casaRepository;
  final LeituraRepository leituraRepository;
  final AberturaMesRepository aberturaMesRepository;
  final CobrancaRepository cobrancaRepository;
  final FaturaCalculadaRepository faturaRepository;
  final DiretorioProvider diretorioProvider;

  GerarPdfMensalUseCase({
    required this.casaRepository,
    required this.leituraRepository,
    required this.aberturaMesRepository,
    required this.cobrancaRepository,
    required this.faturaRepository,
    required this.diretorioProvider,
  });

  /// Gera o PDF mensal e salva no diretório de Downloads.
  ///
  /// Parâmetros:
  /// - [mesAno]: Mês de referência (ex: '2026-04' ou '04/2026')
  /// - [mostrarAuditoria]: Se true, inclui seção de auditoria no PDF (default: true)
  ///
  /// Retorna: [ResultadoPdf] com caminho e tamanho do arquivo.
  ///
  /// Lança [GerarPdfException] se faltar dado ou falhar na geração.
  Future<ResultadoPdf> execute({
    required String mesAno,
    bool mostrarAuditoria = true,
  }) async {
    // Buscar dados necessários
    final contaCorsan = await aberturaMesRepository.getContaCorsan(mesAno);
    if (contaCorsan == null) {
      throw GerarPdfException('ContaCORSAN não encontrada para $mesAno.');
    }

    final contaLuz = await aberturaMesRepository.getContaLuz(mesAno);
    if (contaLuz == null) {
      throw GerarPdfException('ContaLuz não encontrada para $mesAno.');
    }

    final config = await aberturaMesRepository.getConfiguracaoMes(mesAno);
    if (config == null) {
      throw GerarPdfException(
        'Configuração do mês não encontrada para $mesAno.',
      );
    }

    final casas = await casaRepository.buscarAtivas();
    if (casas.isEmpty) {
      throw GerarPdfException('Nenhuma casa ativa encontrada.');
    }

    final leituras = await leituraRepository.buscarLeiturasPorMes(mesAno);
    if (leituras.isEmpty) {
      throw GerarPdfException('Nenhuma leitura encontrada para $mesAno.');
    }

    final fatura = await faturaRepository.buscarPorMes(mesAno);
    if (fatura == null) {
      throw GerarPdfException('Fatura não encontrada para $mesAno.');
    }

    final cobrancas =
        await cobrancaRepository.buscarCobrancasPorFatura(fatura.id);
    if (cobrancas.isEmpty) {
      throw GerarPdfException(
        'Nenhuma cobrança encontrada para a fatura de $mesAno.',
      );
    }

    // Montar auditoria a partir dos dados
    final auditoria = _montarAuditoria(
      faturaId: fatura.id,
      contaCorsan: contaCorsan,
      contaLuz: contaLuz,
      leituras: leituras,
      cobrancas: cobrancas,
    );

    // Gerar PDF
    final pdfBytes = await PdfService.gerarPdf(
      mesAno: mesAno,
      contaCorsan: contaCorsan,
      contaLuz: contaLuz,
      valorCond: config.valorCond.centavos,
      casas: casas,
      leituras: leituras,
      cobrancas: cobrancas,
      auditoria: auditoria,
      mostrarAuditoria: mostrarAuditoria,
    );

    // Salvar arquivo
    final caminho = await _salvarArquivo(mesAno, pdfBytes);

    return ResultadoPdf(
      caminhoArquivo: caminho,
      tamanhoBytes: pdfBytes.length,
      pdfBytes: pdfBytes,
    );
  }

  /// Monta AuditoriaFatura a partir dos dados disponíveis.
  AuditoriaFatura _montarAuditoria({
    required String faturaId,
    required ContaCorsan contaCorsan,
    required ContaLuz contaLuz,
    required List<Leitura> leituras,
    required List<Cobranca> cobrancas,
  }) {
    final somaMetrosCasas =
        leituras.fold<int>(0, (sum, l) => sum + l.consumoM3);
    final somaEsgotoCasas =
        cobrancas.fold<int>(0, (sum, c) => sum + c.valorEsgoto);
    final somaLuzCasas =
        cobrancas.fold<int>(0, (sum, c) => sum + c.valorLuz);
    final totalCobrado =
        cobrancas.fold<int>(0, (sum, c) => sum + c.valorTotal);

    final diferencaMetros = contaCorsan.consumoM3 - somaMetrosCasas;
    final diferencaEsgoto = somaEsgotoCasas - contaCorsan.valorEsgoto.centavos;
    final diferencaLuz = somaLuzCasas - contaLuz.valorTotal.centavos;

    StatusAuditoria status;
    String? mensagem;

    if (diferencaMetros < 0 ||
        diferencaEsgoto.abs() > 1 ||
        diferencaLuz.abs() > 1) {
      status = StatusAuditoria.erro;
    } else if (diferencaMetros > 0) {
      status = StatusAuditoria.alerta;
      mensagem =
          'Diferença de $diferencaMetros m³ — verificar quiosque/vazamento';
    } else {
      status = StatusAuditoria.ok;
    }

    return AuditoriaFatura(
      faturaId: faturaId,
      somaMetrosCasas: somaMetrosCasas,
      consumoGeralCorsan: contaCorsan.consumoM3,
      diferencaMetros: diferencaMetros,
      somaEsgotoCasas: somaEsgotoCasas,
      valorEsgotoCorsan: contaCorsan.valorEsgoto.centavos,
      somaLuzCasas: somaLuzCasas,
      valorLuzCorsan: contaLuz.valorTotal.centavos,
      totalCobrado: totalCobrado,
      status: status,
      mensagem: mensagem,
    );
  }

  /// Salva os bytes do PDF no diretório de Downloads.
  Future<String> _salvarArquivo(
    String mesAno,
    List<int> pdfBytes,
  ) async {
    // Normalizar mesAno para MM_YYYY
    String mm;
    String yyyy;
    if (mesAno.contains('-')) {
      final partes = mesAno.split('-');
      yyyy = partes[0];
      mm = partes[1];
    } else if (mesAno.contains('/')) {
      final partes = mesAno.split('/');
      mm = partes[0];
      yyyy = partes[1];
    } else {
      throw GerarPdfException('Formato de mesAno inválido: $mesAno');
    }

    final nomeArquivo = 'ilheus_${mm}_$yyyy.pdf';
    final dir = await diretorioProvider.getDiretorioDownloads();
    final caminhoCompleto = '${dir.path}/$nomeArquivo';
    final arquivo = File(caminhoCompleto);
    await arquivo.writeAsBytes(pdfBytes);

    return caminhoCompleto;
  }
}
