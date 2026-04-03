import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_pretext/flutter_pretext.dart';

class AnimatedObstacleDemo extends StatefulWidget {
  const AnimatedObstacleDemo({super.key});

  @override
  State<AnimatedObstacleDemo> createState() => _AnimatedObstacleDemoState();
}

class _AnimatedObstacleDemoState extends State<AnimatedObstacleDemo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late PreparedText _preparedText;
  final TextStyle _style = const TextStyle(
      fontSize: 16, color: Colors.blueGrey, height: 1.2);

  final String _demoText =
      "This screen showcases the raw performance of Pretext. We are running an animation loop at 60 FPS. Every frame, the bounding boxes of the Flutter Dash and the Bug move. Traditional flutter text layout would shatter or drop frames if pushed this hard, but because pretext leverages a direct mathematical iterator with layout constraints cached purely in memory, this recalculates completely natively every single frame without a sweat. Watch the words flow apart and merge back together dynamically like water around stones in a river. This unlocks completely new interactive design paradigms!";

  bool _isPlaying = true;

  @override
  void initState() {
    super.initState();
    _preparedText = prepare(_demoText, _style);
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  void _toggleAnimation() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleAnimation,
        child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
      ),
      body: Center(
        child: Container(
          width: 350,
          height: 450,
          decoration: BoxDecoration(
              border: Border.all(color: Colors.black12, width: 2),
              borderRadius: BorderRadius.circular(12)),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              double t = _controller.value * 2 * math.pi;
              double dashX = 120 + math.cos(t) * 90;
              double dashY = 150 + math.sin(t) * 90;

              double bugX = 130 + math.cos(t + math.pi) * 90;
              double bugY = 220 + math.sin(t + math.pi) * 90;

              Rect dashRect = Rect.fromLTWH(dashX, dashY, 80, 80);
              Rect bugRect = Rect.fromLTWH(bugX, bugY, 80, 80);

              return Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ObstacleTextFlow(
                        preparedText: _preparedText,
                        textStyle: _style,
                        obstacles: [dashRect, bugRect],
                        lineHeight: 16 * 1.2,
                        wrapBothSides: true,
                      ),
                    ),
                  ),
                  Positioned.fromRect(
                    rect: dashRect,
                    child: const Center(
                        child: Icon(Icons.flutter_dash,
                            size: 50, color: Colors.deepPurple)),
                  ),
                  Positioned.fromRect(
                    rect: bugRect,
                    child: const Center(
                        child: Icon(Icons.bug_report,
                            size: 50, color: Colors.deepOrange)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
