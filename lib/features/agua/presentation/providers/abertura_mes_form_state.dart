import 'package:ilheus_app/features/agua/domain/models/models.dart';

class AberturaMesFormState {
  final String? mesAno;
  final ContaCorsan contaCorsan;
  final ContaLuz contaLuz;
  final ConfiguracaoMes configuracaoMes;
  final List<DespesaExtra> despesasExtras;
  final bool isSalvo;
  final bool isLoading;
  final bool leituraCompleta;
  
  // Referências do mês anterior para UX
  final ContaCorsan? contaCorsanAnterior;
  final ContaLuz? contaLuzAnterior;
  final ConfiguracaoMes? configuracaoAnterior;

  const AberturaMesFormState({
    this.mesAno,
    this.contaCorsan = const ContaCorsan(mesAno: ''),
    this.contaLuz = const ContaLuz(mesAno: ''),
    this.configuracaoMes = const ConfiguracaoMes(mesAno: ''),
    this.despesasExtras = const [],
    this.isSalvo = false,
    this.isLoading = false,
    this.leituraCompleta = false,
    this.contaCorsanAnterior,
    this.contaLuzAnterior,
    this.configuracaoAnterior,
  });

  AberturaMesFormState copyWith({
    String? mesAno,
    ContaCorsan? contaCorsan,
    ContaLuz? contaLuz,
    ConfiguracaoMes? configuracaoMes,
    List<DespesaExtra>? despesasExtras,
    bool? isSalvo,
    bool? isLoading,
    bool? leituraCompleta,
    ContaCorsan? contaCorsanAnterior,
    ContaLuz? contaLuzAnterior,
    ConfiguracaoMes? configuracaoAnterior,
  }) {
    return AberturaMesFormState(
      mesAno: mesAno ?? this.mesAno,
      contaCorsan: contaCorsan ?? this.contaCorsan,
      contaLuz: contaLuz ?? this.contaLuz,
      configuracaoMes: configuracaoMes ?? this.configuracaoMes,
      despesasExtras: despesasExtras ?? this.despesasExtras,
      isSalvo: isSalvo ?? this.isSalvo,
      isLoading: isLoading ?? this.isLoading,
      leituraCompleta: leituraCompleta ?? this.leituraCompleta,
      contaCorsanAnterior: contaCorsanAnterior ?? this.contaCorsanAnterior,
      contaLuzAnterior: contaLuzAnterior ?? this.contaLuzAnterior,
      configuracaoAnterior: configuracaoAnterior ?? this.configuracaoAnterior,
    );
  }

  AberturaMesFormState mesSelecionado(String novoMesAno) {
    return AberturaMesFormState(
      mesAno: novoMesAno,
      contaCorsan: ContaCorsan(mesAno: novoMesAno),
      contaLuz: ContaLuz(mesAno: novoMesAno),
      configuracaoMes: ConfiguracaoMes(mesAno: novoMesAno),
      despesasExtras: [],
      isSalvo: false,
      isLoading: false,
    );
  }
}
