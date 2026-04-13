import 'package:flutter/material.dart';

import 'animated_obstacles.dart';
import 'shrink_wrap.dart';
import 'balanced_text.dart';
import 'shaped_text.dart';
import 'arabic_demo.dart';

void main() {
  runApp(const PretextShowcaseApp());
}

class PretextShowcaseApp extends StatelessWidget {
  const PretextShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pretext Showcase',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ShowcaseScreen(),
    );
  }
}

class ShowcaseScreen extends StatefulWidget {
  const ShowcaseScreen({super.key});

  @override
  State<ShowcaseScreen> createState() => _ShowcaseScreenState();
}

class _ShowcaseScreenState extends State<ShowcaseScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AnimatedObstacleDemo(),
    const ShrinkWrapDemo(),
    const BalancedTextDemo(),
    const ShapedTextDemo(),
    const ArabicTextDemo(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Pretext Showcase'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.animation), label: 'Obstacles'),
          BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble), label: 'ShrinkWrap'),
          BottomNavigationBarItem(
              icon: Icon(Icons.balance), label: 'Balanced Text'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shape_line), label: 'Custom Shapes'),
          BottomNavigationBarItem(
              icon: Icon(Icons.language), label: 'Arabic (RTL)'),
        ],
      ),
    );
  }
}
