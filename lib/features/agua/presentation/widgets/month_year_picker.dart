import 'package:flutter/material.dart';

class MonthYearPickerSheet extends StatefulWidget {
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
  State<MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<MonthYearPickerSheet> {
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
    _selectedMonth = DateTime.now().month;

    if (widget.initialMesAno != null) {
      final parts = widget.initialMesAno!.split('/');
      _selectedMonth = int.parse(parts[0]);
      _selectedYear = int.parse(parts[1]);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                Expanded(child: _buildMonthPicker(context)),
                const SizedBox(width: 16),
                Expanded(child: _buildYearPicker(context)),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                final mesFormatado =
                    '${_selectedMonth.toString().padLeft(2, '0')}/$_selectedYear';
                Navigator.of(context).pop(mesFormatado);
              },
              child: const Text('Confirmar'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthPicker(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Mês', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedMonth,
          items: List.generate(12, (i) => i + 1)
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(_nomeMes(m)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedMonth = v);
            }
          },
        ),
      ],
    );
  }

  Widget _buildYearPicker(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('Ano', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedYear,
          items: List.generate(5, (i) => DateTime.now().year - 1 + i)
              .map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y.toString()),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() => _selectedYear = v);
            }
          },
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
