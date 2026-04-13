import 'package:flutter/material.dart';
import 'package:flutter_pretext/flutter_pretext.dart';

class ArabicTextDemo extends StatefulWidget {
  const ArabicTextDemo({super.key});

  @override
  State<ArabicTextDemo> createState() => _ArabicTextDemoState();
}

class _ArabicTextDemoState extends State<ArabicTextDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const arabicText =
        "هذا نص عربي لعرض كيف يقوم مكتبة pretext بالتفاف النص تلقائيًا مع المحافظة على الاتجاه الصحيح. حتى مع تفادي العوائق هندسيا واحتساب الحروف الملاصقة بدقة.";

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Arabic / Right-to-Left Text Layout",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            "Notice how the Arabic text respects RTL flow during shape wrapping.",
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // Animate an obstacle horizontally across the text area
                final width = MediaQuery.of(context).size.width - 32;
                final obstacleX = (_controller.value * (width - 100));

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    border:
                        Border.all(color: Colors.blue.withValues(alpha: 0.5)),
                  ),
                  child: Stack(
                    children: [
                      // Obstacle visualization
                      Positioned(
                        left: obstacleX,
                        top: 10,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),

                      // Pretext Obstacle Text Flow
                      Positioned.fill(
                        child: ObstacleTextFlow(
                          preparedText: prepare(
                            arabicText,
                            TextStyleFont(
                              const TextStyle(
                                fontSize: 24,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          lineHeight: 36,
                          obstacles: [
                            Rect.fromLTWH(obstacleX, 10, 100, 100),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
