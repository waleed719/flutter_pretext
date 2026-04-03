import 'package:flutter/material.dart';
import 'package:flutter_pretext/flutter_pretext.dart';

class BalancedTextDemo extends StatefulWidget {
  const BalancedTextDemo({super.key});

  @override
  State<BalancedTextDemo> createState() => _BalancedTextDemoState();
}

class _BalancedTextDemoState extends State<BalancedTextDemo> {
  double _width = 300;

  @override
  Widget build(BuildContext context) {
    const titleStyle =
        TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.1);

    // Changed color to stand out for perfect layout
    final perfectStyle = titleStyle.copyWith(color: Colors.white);

    const title = "The Quick Brown Fox Jumps Over The Lazy Dog";

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("1. Standard Flutter Layout (Awkward)",
            style: TextStyle(color: Colors.grey)),
        Container(
          width: _width,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
          child:
              const Text(title, style: titleStyle, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 24),
        const Text("2. Pretext Balanced Layout (Perfect)",
            style: TextStyle(color: Colors.grey)),
        Container(
          width: _width,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.green.withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Align(
            alignment: Alignment.center,
            child: BalancedText(title, perfectStyle, 32 * 1.1),
          ),
        ),
        const Spacer(),
        Slider(
          value: _width,
          min: 150,
          max: 400,
          onChanged: (v) => setState(() => _width = v),
        ),
        const Text("Drag to resize container"),
        const SizedBox(height: 32),
      ],
    );
  }
}
