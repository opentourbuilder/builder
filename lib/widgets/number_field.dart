import 'dart:math';

import 'package:flutter/material.dart';

const _poiEditorInputDecoration = InputDecoration(
  filled: true,
  fillColor: Color(0xFFFFFFFF),
  hoverColor: Color(0xFFFFFFFF),
);

class NumberField extends StatefulWidget {
  const NumberField({
    super.key,
    required this.labelText,
    required this.value,
    required this.requestValueChange,
  });

  final String labelText;
  final double value;
  final void Function(double) requestValueChange;

  @override
  State<StatefulWidget> createState() => _NumberFieldState();
}

class _NumberFieldState extends State<NumberField> {
  final TextEditingController controller = TextEditingController();
  String prevText = "";
  late double value;
  bool bad = false;

  @override
  void initState() {
    super.initState();

    controller.addListener(() {
      if (controller.text == prevText) return;
      final String text = controller.text.replaceAll(RegExp(r'[^\d.-]'), "");
      prevText = text;
      controller.value = controller.value.copyWith(
        text: text,
        selection: TextSelection(
          baseOffset: min(controller.value.selection.baseOffset, text.length),
          extentOffset:
              min(controller.value.selection.extentOffset, text.length),
        ),
      );

      double? newValue = double.tryParse(text);
      setState(() {
        if (newValue != null) {
          value = newValue;
          bad = false;

          widget.requestValueChange(value);
        } else {
          bad = true;
        }
      });
    });

    value = widget.value;
    controller.text = '$value';
  }

  @override
  void didUpdateWidget(covariant NumberField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (value != widget.value) {
      setState(() {
        value = widget.value;
        controller.text = '$value';
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: _poiEditorInputDecoration.copyWith(
        labelText: widget.labelText,
        errorText: bad ? "Must be a number" : null,
        errorMaxLines: 2,
      ),
      controller: controller,
    );
  }
}
