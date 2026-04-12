import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/usecases/gerar_pdf_mensal_usecase.dart';

enum FechamentoMensalStatus { initial, loading, success, error }

class FechamentoMensalState {
  final FechamentoMensalStatus status;
  final String? errorMessage;
  final ContaCorsan? contaCorsan;
  final ContaLuz? contaLuz;
  final ConfiguracaoMes? configuracao;
  final List<Leitura> leituras;
  final List<Casa> casas;
  final List<Cobranca> cobrancas;
  final AuditoriaFatura? auditoria;
  final bool leituraCompleta;
  final ResultadoPdf? pdfGerado;

  FechamentoMensalState({
    this.status = FechamentoMensalStatus.initial,
    this.errorMessage,
    this.contaCorsan,
    this.contaLuz,
    this.configuracao,
    this.leituras = const [],
    this.casas = const [],
    this.cobrancas = const [],
    this.auditoria,
    this.leituraCompleta = false,
    this.pdfGerado,
  });

  FechamentoMensalState copyWith({
    FechamentoMensalStatus? status,
    String? errorMessage,
    ContaCorsan? contaCorsan,
    ContaLuz? contaLuz,
    ConfiguracaoMes? configuracao,
    List<Leitura>? leituras,
    List<Casa>? casas,
    List<Cobranca>? cobrancas,
    AuditoriaFatura? auditoria,
    bool? leituraCompleta,
    ResultadoPdf? pdfGerado,
  }) {
    return FechamentoMensalState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      contaCorsan: contaCorsan ?? this.contaCorsan,
      contaLuz: contaLuz ?? this.contaLuz,
      configuracao: configuracao ?? this.configuracao,
      leituras: leituras ?? this.leituras,
      casas: casas ?? this.casas,
      cobrancas: cobrancas ?? this.cobrancas,
      auditoria: auditoria ?? this.auditoria,
      leituraCompleta: leituraCompleta ?? this.leituraCompleta,
      pdfGerado: pdfGerado ?? this.pdfGerado,
    );
  }
}
