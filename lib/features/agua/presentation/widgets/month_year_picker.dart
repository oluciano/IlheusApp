import 'package:flutter/material.dart';

class MonthYearPickerSheet extends StatelessWidget {
  final String? initialMesAno;

  const MonthYearPickerSheet({super.key, this.initialMesAno});

  static Future<String?> show(BuildContext context,
      {String? initialMesAno}) {
    return showModalBottomSheet<String>(
      context: context,
      builder: (_) => MonthYearPickerSheet(initialMesAno: initialMesAno),
    );
  }

  @override
  Widget build(BuildContext context) {
    int selectedYear = DateTime.now().year;
    int selectedMonth = DateTime.now().month;

    if (initialMesAno != null) {
      final parts = initialMesAno!.split('/');
      selectedMonth = int.parse(parts[0]);
      selectedYear = int.parse(parts[1]);
    }

    return StatefulBuilder(
      builder: (context, setState) {
        final theme = Theme.of(context);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Selecionar Mês/Ano',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildMonthPicker(
                          context, setState, selectedMonth, selectedYear),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildYearPicker(
                          context, setState, selectedMonth, selectedYear),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    final mesFormatado =
                        '${selectedMonth.toString().padLeft(2, '0')}/$selectedYear';
                    Navigator.of(context).pop(mesFormatado);
                  },
                  child: const Text('Confirmar'),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMonthPicker(
    BuildContext context,
    StateSetter setState,
    int selectedMonth,
    int selectedYear,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Mês', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedMonth,
          items: List.generate(12, (i) => i + 1)
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(_nomeMes(m)),
                  ))
              .toList(),
          onChanged: (v) {},
        ),
      ],
    );
  }

  Widget _buildYearPicker(
    BuildContext context,
    StateSetter setState,
    int selectedMonth,
    int selectedYear,
  ) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Ano', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: selectedYear,
          items: List.generate(5, (i) => DateTime.now().year - 1 + i)
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y.toString()),
                  ))
              .toList(),
          onChanged: (v) {},
        ),
      ],
    );
  }

  String _nomeMes(int mes) {
    const meses = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return meses[mes - 1];
  }
}
