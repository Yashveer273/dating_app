import 'dart:math';
import 'package:flutter/material.dart';
import 'package:talk24loves/components/app_colors.dart';

class HeartBackground extends StatefulWidget {
  const HeartBackground({super.key});

  @override
  State createState() => _HeartBackgroundState();
}

class _HeartBackgroundState extends State with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _AnimatedHeart(
          controller: _controller,
          top: 40,
          left: 35,
          size: 14,
          color: AppColors.primaryPink.withOpacity(0.5),
          offset: 0.0,
        ),
        _AnimatedHeart(
          controller: _controller,
          top: 25,
          right: 40,
          size: 18,
          color: AppColors.primaryPink.withOpacity(0.6),
          offset: 1.0,
        ),
        _AnimatedHeart(
          controller: _controller,
          top: 130,
          left: 25,
          size: 12,
          color: AppColors.pinkLight.withOpacity(0.4),
          offset: 2.0,
        ),
        _AnimatedHeart(
          controller: _controller,
          top: 145,
          right: 30,
          size: 14,
          color: AppColors.primaryPink.withOpacity(0.5),
          offset: 0.5,
        ),
      ],
    );
  }
}

class _AnimatedHeart extends StatelessWidget {
  const _AnimatedHeart({
    required this.controller,
    this.top,
    this.left,
    this.right,
    required this.size,
    required this.color,
    required this.offset,
  });

  final AnimationController controller;
  final double? top;
  final double? left;
  final double? right;
  final double size;
  final Color color;
  final double offset;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          final value = sin((controller.value * 2 * pi) + offset) * 6.0;
          return Transform.translate(
            offset: Offset(0, value),
            child: Icon(Icons.favorite, size: size, color: color),
          );
        },
      ),
    );
  }
}
