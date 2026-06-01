import 'package:flutter/material.dart';

class OtpInputField extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final double spacing;
  final double boxSize;
  final TextStyle? textStyle;
  final BoxDecoration? boxDecoration;
  final TextEditingController? controller;

  const OtpInputField({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.spacing = 8,
    this.boxSize = 48,
    this.textStyle,
    this.boxDecoration,
    this.controller,
  });

  @override
  State<OtpInputField> createState() => _OtpInputFieldState();
}

class _OtpInputFieldState extends State<OtpInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (_) => FocusNode(),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _onChanged(int index, String value) {
    if (value.length == 1 && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    final code = _controllers.map((c) => c.text).join();
    if (code.length == widget.length) {
      widget.onCompleted(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.length, (index) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
          child: SizedBox(
            width: widget.boxSize,
            height: widget.boxSize,
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              maxLength: 1,
              style: widget.textStyle ?? const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                counterText: '',
                border: widget.boxDecoration != null
                    ? InputBorder.none
                    : OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
              ),
              onChanged: (value) => _onChanged(index, value),
              onTap: () {
                if (_controllers[index].text.isEmpty) {
                  _controllers[index].selection = TextSelection.collapsed(offset: 0);
                }
              },
            ),
          ),
        );
      }),
    );
  }
}
