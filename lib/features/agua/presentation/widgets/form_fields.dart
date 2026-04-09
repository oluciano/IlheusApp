import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyInputFormField extends StatelessWidget {
  final String label;
  final double? initialValue;
  final ValueChanged<double> onChanged;

  const CurrencyInputFormField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: initialValue != null ? initialValue!.toStringAsFixed(2) : '',
    );

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: Text(label),
        prefixText: 'R\$ ',
        border: const OutlineInputBorder(),
      ),
      keyboardType:
          const TextInputType.numberWithOptions(decimal: true, signed: false),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
      ],
      onChanged: (value) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        if (cleaned.isNotEmpty) {
          onChanged(double.parse(cleaned));
        }
      },
    );
  }
}

class IntInputFormField extends StatelessWidget {
  final String label;
  final int? initialValue;
  final ValueChanged<int> onChanged;

  const IntInputFormField({
    super.key,
    required this.label,
    this.initialValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: initialValue?.toString() ?? '',
    );

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        label: Text(label),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        if (value.isNotEmpty) {
          onChanged(int.parse(value));
        }
      },
    );
  }
}
