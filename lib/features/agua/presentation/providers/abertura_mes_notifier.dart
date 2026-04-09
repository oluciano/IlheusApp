import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';
import 'package:ilheus_app/features/agua/presentation/providers/abertura_mes_form_state.dart';
import 'package:ilheus_app/features/agua/presentation/providers/database_providers.dart';

final aberturaMesFormProvider =
    StateNotifierProvider<AberturaMesNotifier, AberturaMesFormState>((ref) {
  final repo = ref.watch(aberturaMesRepositoryProvider);
  final repository = repo ?? WebNotImplemented();
  return AberturaMesNotifier(repository);
});

class AberturaMesNotifier extends StateNotifier<AberturaMesFormState> {
  final AberturaMesRepository _repository;

  AberturaMesNotifier(this._repository)
      : super(const AberturaMesFormState());

  void selecionarMes(String mesAno) {
    state = state.mesSelecionado(mesAno);
    _carregarDadosMes(mesAno);
  }

  Future<void> _carregarDadosMes(String mesAno) async {
    state = state.copyWith(isLoading: true);

    final contaCorsan = await _repository.getContaCorsan(mesAno);
    final contaLuz = await _repository.getContaLuz(mesAno);
    final config = await _repository.getConfiguracaoMes(mesAno);
    final despesas = await _repository.getDespesasExtras(mesAno);

    state = state.copyWith(
      contaCorsan: contaCorsan ?? ContaCorsan(mesAno: mesAno),
      contaLuz: contaLuz ?? ContaLuz(mesAno: mesAno),
      configuracaoMes: config ?? ConfiguracaoMes(mesAno: mesAno),
      despesasExtras: despesas,
      isSalvo: config != null,
      isLoading: false,
    );
  }

  void atualizarContaCorsan(ContaCorsan conta) {
    state = state.copyWith(contaCorsan: conta, isSalvo: false);
  }

  void atualizarContaLuz(ContaLuz conta) {
    state = state.copyWith(contaLuz: conta, isSalvo: false);
  }

  void atualizarConfiguracaoMes(ConfiguracaoMes config) {
    state = state.copyWith(configuracaoMes: config, isSalvo: false);
  }

  void adicionarDespesaExtra(DespesaExtra despesa) {
    state = state.copyWith(
      despesasExtras: [...state.despesasExtras, despesa],
      isSalvo: false,
    );
  }

  void removerDespesaExtra(String id) {
    state = state.copyWith(
      despesasExtras: state.despesasExtras.where((d) => d.id != id).toList(),
      isSalvo: false,
    );
  }

  Future<bool> salvar() async {
    final mesAno = state.mesAno;
    if (mesAno == null) return false;

    try {
      await _repository.saveContaCorsan(state.contaCorsan);
      await _repository.saveContaLuz(state.contaLuz);
      await _repository.saveConfiguracaoMes(state.configuracaoMes);

      for (final despesa in state.despesasExtras) {
        await _repository.saveDespesaExtra(despesa);
      }

      state = state.copyWith(isSalvo: true);
      return true;
    } catch (_) {
      return false;
    }
  }
}
