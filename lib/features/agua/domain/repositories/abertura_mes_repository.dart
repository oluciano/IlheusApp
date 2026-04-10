import 'package:ilheus_app/features/agua/domain/models/models.dart';

abstract class AberturaMesRepository {
  Future<ContaCorsan?> getContaCorsan(String mesAno);
  Future<void> saveContaCorsan(ContaCorsan conta);

  Future<ContaLuz?> getContaLuz(String mesAno);
  Future<void> saveContaLuz(ContaLuz conta);

  Future<ConfiguracaoMes?> getConfiguracaoMes(String mesAno);
  Future<void> saveConfiguracaoMes(ConfiguracaoMes config);

  Future<List<DespesaExtra>> getDespesasExtras(String mesAno);
  Future<void> saveDespesaExtra(DespesaExtra despesa);
  Future<void> deleteDespesaExtra(String id);

  Future<bool> mesSalvo(String mesAno);
  Future<List<String>> listarTodosMeses();

  /// Executa um bloco de código dentro de uma transação SQLite.
  ///
  /// Se o [body] completar com sucesso, a transação é confirmada.
  /// Se o [body] lançar uma exceção, a transação é desfeita automaticamente.
  /// O resultado do [body] é retornado.
  Future<T> runInTransaction<T>(Future<T> Function() body);
}
