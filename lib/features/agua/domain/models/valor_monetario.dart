class ValorMonetario {
  final int centavos;

  const ValorMonetario(this.centavos);

  const ValorMonetario.zero() : centavos = 0;

  factory ValorMonetario.fromCentavos(int c) => ValorMonetario(c);

  factory ValorMonetario.fromReais(int reais) => ValorMonetario(reais * 100);

  factory ValorMonetario.fromDouble(double valor) {
    return ValorMonetario((valor * 100).round());
  }

  double toDouble() => centavos / 100;

  ValorMonetario operator +(ValorMonetario other) {
    return ValorMonetario(centavos + other.centavos);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValorMonetario && centavos == other.centavos;

  @override
  int get hashCode => centavos;

  @override
  String toString() => (centavos / 100).toStringAsFixed(2);
}
