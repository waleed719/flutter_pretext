import 'package:flutter/material.dart';
import 'package:flutter_pretext/flutter_pretext.dart';

class ShrinkWrapDemo extends StatelessWidget {
  const ShrinkWrapDemo({super.key});

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 18, color: Colors.white, height: 1.3);
    const lorem =
        "Notice how standard Flutter widgets leave awkward trailing spaces when wrapping lines naturally.";

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('1. Standard Flutter Text (Bad)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.red[300],
                borderRadius: BorderRadius.circular(16)),
            child: const Text(lorem, style: textStyle),
          ),
          const SizedBox(height: 32),
          const Text('2. Pretext ShrinkWrapText (Perfect)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: Colors.green[500],
                borderRadius: BorderRadius.circular(16)),
            child: const ShrinkWrapText(lorem, textStyle, 18 * 1.3),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 16.0),
            child: Text(
                "Pretext computes the exact geometric drawn width of the longest fitted line, preventing the background bubble from occupying dead space.",
                style: TextStyle(color: Colors.grey)),
          )
        ],
      ),
    );
  }
}
