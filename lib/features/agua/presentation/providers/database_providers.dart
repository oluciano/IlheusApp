import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ilheus_app/features/agua/data/repositories/repository_locator.dart';
import 'package:ilheus_app/features/agua/domain/models/models.dart';
import 'package:ilheus_app/features/agua/domain/repositories/abertura_mes_repository.dart';

final aberturaMesRepositoryProvider = Provider<AberturaMesRepository?>((ref) {
  return RepositoryLocator.aberturaMes;
});

class WebNotImplemented implements AberturaMesRepository {
  @override
  Future<ContaCorsan?> getContaCorsan(String mesAno) async => null;
  @override
  Future<void> saveContaCorsan(ContaCorsan conta) async {
    debugPrint('Persistência desabilitada no web (sqflite não suportado)');
  }
  @override
  Future<ContaLuz?> getContaLuz(String mesAno) async => null;
  @override
  Future<void> saveContaLuz(ContaLuz conta) async {
    debugPrint('Persistência desabilitada no web (sqflite não suportado)');
  }
  @override
  Future<ConfiguracaoMes?> getConfiguracaoMes(String mesAno) async => null;
  @override
  Future<void> saveConfiguracaoMes(ConfiguracaoMes config) async {
    debugPrint('Persistência desabilitada no web (sqflite não suportado)');
  }
  @override
  Future<List<DespesaExtra>> getDespesasExtras(String mesAno) async => [];
  @override
  Future<void> saveDespesaExtra(DespesaExtra despesa) async {
    debugPrint('Persistência desabilitada no web (sqflite não suportado)');
  }
  @override
  Future<void> deleteDespesaExtra(String id) async {}
  @override
  Future<bool> mesSalvo(String mesAno) async => false;
  @override
  Future<List<String>> listarTodosMeses() async => [];

  @override
  Future<T> runInTransaction<T>(Future<T> Function() body) async {
    debugPrint('Transações desabilitadas no web (sqflite não suportado)');
    // No web, simplesmente executa o body sem transação
    return body();
  }
}
