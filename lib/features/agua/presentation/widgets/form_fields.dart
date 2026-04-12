import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CurrencyInputFormField extends StatefulWidget {
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
  State<CurrencyInputFormField> createState() => _CurrencyInputFormFieldState();
}

class _CurrencyInputFormFieldState extends State<CurrencyInputFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toStringAsFixed(2) ?? '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(CurrencyInputFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue?.toStringAsFixed(2) ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        label: Text(widget.label),
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
          widget.onChanged(double.parse(cleaned));
        } else if (cleaned.isEmpty && value.isEmpty) {
          widget.onChanged(0);
        }
      },
    );
  }
}

class IntInputFormField extends StatefulWidget {
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
  State<IntInputFormField> createState() => _IntInputFormFieldState();
}

class _IntInputFormFieldState extends State<IntInputFormField> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialValue?.toString() ?? '',
    );
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void didUpdateWidget(IntInputFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue && !_focusNode.hasFocus) {
      _controller.text = widget.initialValue?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        label: Text(widget.label),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (value) {
        if (value.isNotEmpty) {
          widget.onChanged(int.parse(value));
        }
      },
    );
  }
}
