import 'dart:math';
import 'package:flutter/material.dart';

// --- Professional Dotted Wave Loader Widget for Login & Actions ---
class WaveDotLoader extends StatefulWidget {
  const WaveDotLoader({super.key, this.color = Colors.white, this.size = 6.0});

  final Color color;
  final double size;

  @override
  State<WaveDotLoader> createState() => _WaveDotLoaderState();
}

class _WaveDotLoaderState extends State<WaveDotLoader>
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
    return SizedBox(
      height: 24,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final double wave =
                  (sin((_controller.value * 2 * pi) - (index * 0.8)) + 1) / 2;
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
      ),
    );
  }
}
