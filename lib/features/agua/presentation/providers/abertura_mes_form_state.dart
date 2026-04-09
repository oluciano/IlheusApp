import 'package:ilheus_app/features/agua/domain/models/models.dart';

class AberturaMesFormState {
  final String? mesAno;
  final ContaCorsan contaCorsan;
  final ContaLuz contaLuz;
  final ConfiguracaoMes configuracaoMes;
  final List<DespesaExtra> despesasExtras;
  final bool isSalvo;
  final bool isLoading;

  const AberturaMesFormState({
    this.mesAno,
    this.contaCorsan = const ContaCorsan(mesAno: ''),
    this.contaLuz = const ContaLuz(mesAno: ''),
    this.configuracaoMes = const ConfiguracaoMes(mesAno: ''),
    this.despesasExtras = const [],
    this.isSalvo = false,
    this.isLoading = false,
  });

  AberturaMesFormState copyWith({
    String? mesAno,
    ContaCorsan? contaCorsan,
    ContaLuz? contaLuz,
    ConfiguracaoMes? configuracaoMes,
    List<DespesaExtra>? despesasExtras,
    bool? isSalvo,
    bool? isLoading,
  }) {
    return AberturaMesFormState(
      mesAno: mesAno ?? this.mesAno,
      contaCorsan: contaCorsan ?? this.contaCorsan,
      contaLuz: contaLuz ?? this.contaLuz,
      configuracaoMes: configuracaoMes ?? this.configuracaoMes,
      despesasExtras: despesasExtras ?? this.despesasExtras,
      isSalvo: isSalvo ?? this.isSalvo,
      isLoading: isLoading ?? this.isLoading,
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
