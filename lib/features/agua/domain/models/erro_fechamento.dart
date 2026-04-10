/// Erros que podem ocorrer durante o fechamento mensal.
enum ErroFechamento {
  /// Menos de 22 casas ativas cadastradas
  casasInsuficientes,

  /// Conta CORSAN não existe para o mês
  contaCorsanAusente,

  /// Conta de luz não existe para o mês
  contaLuzAusente,

  /// Uma ou mais casas não têm leitura registrada
  leiturasIncompletas,

  /// Auditoria de fatura falhou (status ERRO)
  auditoriaFalhou,
}
