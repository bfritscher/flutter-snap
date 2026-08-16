import 'dart:math';

import 'package:flutter/material.dart';

class LoadingAnimation extends StatefulWidget {
  const LoadingAnimation({super.key});

  @override
  State<LoadingAnimation> createState() => _LoadingAnimationState();
}

enum SquareType {
  first, // 1
  second, // 2, 4
  third, // 3, 5, 7
  fourth, // 6, 8
  fifth, // 9
}

class SquareTile extends StatelessWidget {
  final SquareType squareType;
  final double maxSide;
  final double minSide;

  final AnimationController animationController;

  const SquareTile({
    super.key,
    required this.squareType,
    this.maxSide = 100,
    this.minSide = 10,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    //    timeDilation = 1; // change it to slow down animations while debugging
    final seq = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: maxSide, end: minSide),
        weight: 0.5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: minSide, end: maxSide),
        weight: 0.8,
      ),
    ]);

    final squareSizeChangeTweenAnimation = seq.animate(
      CurvedAnimation(
        parent: animationController,
        curve: Interval(
          _getBeginForSquareType(),
          _getEndForSquareType(),
          curve: Curves.easeInOut,
        ),
      ),
    );

    return AnimatedBuilder(
      animation: squareSizeChangeTweenAnimation,
      builder: (context, child) {
        final side = squareSizeChangeTweenAnimation.value;
        return Expanded(
          child: SizedBox(
            height: maxSide,
            width: maxSide,
            child: Center(
              child: Container(
                width: side,
                height: side,
                color: getColor(context),
              ),
            ),
          ),
        );
      },
    );
  }

  Color increaseColorLightness(Color color, double increment) {
    final hslColor = HSLColor.fromColor(color);
    final newValue = min(max(hslColor.lightness + increment, 0.0), 1.0);
    return hslColor.withLightness(newValue).toColor();
  }

  Color getColor(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (squareType == SquareType.first) {
      return primary;
    } else if (squareType == SquareType.second) {
      return increaseColorLightness(primary, 0.05);
    } else if (squareType == SquareType.third) {
      return increaseColorLightness(primary, 0.1);
    } else if (squareType == SquareType.fourth) {
      return increaseColorLightness(primary, 0.15);
    } else if (squareType == SquareType.fifth) {
      return increaseColorLightness(primary, 0.2);
    }
    return Colors.black;
  }

  double _getBeginForSquareType() {
    if (squareType == SquareType.first) {
      return 0;
    } else if (squareType == SquareType.second) {
      return 0.1;
    } else if (squareType == SquareType.third) {
      return 0.2;
    } else if (squareType == SquareType.fourth) {
      return 0.3;
    } else if (squareType == SquareType.fifth) {
      return 0.4;
    }
    return 0;
  }

  double _getEndForSquareType() {
    return _getBeginForSquareType() + 0.3;
  }
}

/// 1 2 3
/// 4 5 6
/// 7 8 9
///
/// (1), (2, 4), (3, 5, 7), (6, 8), (9)
class _LoadingAnimationState extends State<LoadingAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  @override
  void initState() {
    super.initState();
    animationController = AnimationController(
      vsync: this,
      value: 0,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareTile(
                  squareType: SquareType.first,
                  animationController: animationController,
                ),
                SquareTile(
                  squareType: SquareType.second,
                  animationController: animationController,
                ),
                SquareTile(
                  squareType: SquareType.third,
                  animationController: animationController,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareTile(
                  squareType: SquareType.second,
                  animationController: animationController,
                ),
                SquareTile(
                  squareType: SquareType.third,
                  animationController: animationController,
                ),
                SquareTile(
                  squareType: SquareType.fourth,
                  animationController: animationController,
                ),
              ],
            ),
          ),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SquareTile(
                  squareType: SquareType.third,
                  animationController: animationController,
                ),
                SquareTile(
                  squareType: SquareType.fourth,
                  animationController: animationController,
                ),
                SquareTile(
                  squareType: SquareType.fifth,
                  animationController: animationController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
