// --- Reusable Animated Custom Heart Widget ---
import 'package:flutter/material.dart';
import 'package:talk24loves/components/app_colors.dart';

class AnimatedCustomHeart extends StatefulWidget {
  const AnimatedCustomHeart({
    super.key,
    this.size = 20.0,
    this.borderColor = AppColors.primaryPink,
    this.innerColor = AppColors.pinkLight,
    this.isBouncing = true,
    this.isPulsing = false,
  });

  final double size;
  final Color borderColor;
  final Color innerColor;
  final bool isBouncing;
  final bool isPulsing;

  @override
  State<AnimatedCustomHeart> createState() => _AnimatedCustomHeartState();
}

class _AnimatedCustomHeartState extends State<AnimatedCustomHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    if (widget.isBouncing) {
      _animation = Tween<double>(
        begin: 0.0,
        end: -6.0,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    } else if (widget.isPulsing) {
      _animation = Tween<double>(
        begin: 1.0,
        end: 1.2,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    } else {
      _animation = AlwaysStoppedAnimation(0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget heartStack = Stack(
      alignment: Alignment.center,
      children: [
        Icon(
          Icons.favorite_rounded,
          size: widget.size,
          color: widget.borderColor,
        ),
        Icon(
          Icons.favorite_rounded,
          size: widget.size * 0.75,
          color: widget.innerColor,
        ),
      ],
    );

    if (widget.isBouncing) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: heartStack,
      );
    } else if (widget.isPulsing) {
      return ScaleTransition(scale: _animation, child: heartStack);
    }

    return heartStack;
  }
}
