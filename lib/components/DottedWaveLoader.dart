import 'dart:math';

import 'package:flutter/material.dart';

class DottedWaveLoader extends StatefulWidget {
  const DottedWaveLoader({
    super.key,
    this.color = Colors.white,
    this.size = 6.0,
  });
  final Color color;
  final double size;

  @override
  State<DottedWaveLoader> createState() => _DottedWaveLoaderState();
}

class _DottedWaveLoaderState extends State<DottedWaveLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final double wave =
                (sin((_controller.value * 2 * 3.14159) - (index * 0.8)) + 1) /
                2;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: widget.size + (wave * 6),
              width: widget.size,
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.4 + (wave * 0.6)),
                borderRadius: BorderRadius.circular(widget.size),
              ),
            );
          }),
        );
      },
    );
  }
}
