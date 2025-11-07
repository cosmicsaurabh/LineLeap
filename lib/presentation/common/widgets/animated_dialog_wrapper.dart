import 'package:flutter/material.dart';

/// Wrapper for animated dialog with smooth transitions
class AnimatedDialogWrapper extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const AnimatedDialogWrapper({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  State<AnimatedDialogWrapper> createState() => _AnimatedDialogWrapperState();
}

class _AnimatedDialogWrapperState extends State<AnimatedDialogWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

/// Builder function for creating animated dialogs
Future<T?> showAnimatedDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  Duration duration = const Duration(milliseconds: 300),
  Color barrierColor = const Color(0x80000000),
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (context, animation, secondaryAnimation) {
      return AnimatedDialogWrapper(
        duration: duration,
        child: builder(context),
      );
    },
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dialog',
    transitionDuration: duration,
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return child;
    },
  );
}

