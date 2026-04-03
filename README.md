# Flutter Pretext

`flutter_pretext` is a blazingly fast, high-performance text dynamics engine and layout framework natively rebuilt for Flutter.

![Obstacle Wrapping Demo](https://raw.githubusercontent.com/waleedqamar/flutter_pretext/main/example/ss/1_v.gif)

It is a direct Dart implementation and port of the groundbreaking JavaScript text dynamics library originally built by **@chenglou**. All credits for the underlying geometric abstractions, pure-code measuring mechanics, and cursor math layout capabilities go to [chenglou/pretext](https://github.com/chenglou/pretext). 

This package natively migrates those massive layout capabilities to standard Flutter Widgets without bridging FFI or WebViews.

## Why Pretext?

Flutter's standard `Text` widgets do an amazing job rendering strings, but custom geometry flow—like wrapping paragraphs beautifully around floating avatars, shrinking chat bubbles accurately, or splitting text evenly into a circular path—has historically been agonizing to compute cleanly on a device without dropping frames.

Pretext calculates lines mathematically behind the scenes *before* actually laying out the heavy rendering tree.

### 🌟 Features Available Today

#### 1. `ObstacleTextFlow`
Pass in multiple UI widget bounds (like floating `Positioned` icons) and watch the text shatter and wrap flawlessly around them on both sides instantly. 

![Obstacle Wrapping Demo](https://raw.githubusercontent.com/waleed719/flutter_pretext/main/example/ss/1.png)

#### 2. `ShrinkWrapText`
Say goodbye to the "dead empty trailing space" bug in chat bubbles! `ShrinkWrap` computes the absolute geometric longest drawn string line and snaps your container size down perfectly.

![ShrinkWrapText Demo](https://raw.githubusercontent.com/waleed719/flutter_pretext/main/example/ss/2.png)

#### 3. `BalancedText` 
Say goodbye to awkward orphaned words hanging off your `H1` headlines. Drops in a binary-search container to ensure your multi-line headlines have geometrically balanced widths.

![BalancedText Demo](https://raw.githubusercontent.com/waleed719/flutter_pretext/main/example/ss/3.png)

#### 4. Custom Mathematical Shapes & 60 FPS Animations
You can bind your obstacle arrays to `AnimationController`s or custom geometric algorithms like Circular mappings. Text will dynamically flow over moving surfaces without ever dropping a frame.

![CustomShapes Demo](https://raw.githubusercontent.com/waleed719/flutter_pretext/main/example/ss/4_v.gif)

## Quick Start

### Obstacle Layout Flow
Got a square floating avatar taking up the top left edge? Let text handle it like Word or HTML `float:left`. Note: You can even use `.wrapBothSides = true` to drop the avatar in the exact middle of the paragraph!

```dart
final prepared = prepare("Your extremely long dynamic text here...", style);

ObstacleTextFlow(
    preparedText: prepared,
    textStyle: style,
    lineHeight: 18 * 1.2,
    obstacles: [ Rect.fromLTWH(0, 0, 100, 100) ], // Re-renders precisely around this square.
);
```

### Typographic Balanced Headlines
Stop leaving one word hanging alone!

```dart
BalancedText(
  "This Super Long Title Will Splinter Awkwardly Unless You Use Pretext",
  titleStyle,
  /* lineHeight */ 40,
)
```

## Special Thanks

This repository would not exist without the genius foundations of [chenglou/pretext](https://github.com/chenglou/pretext). His commitment to performance boundary pushing was instrumental.
