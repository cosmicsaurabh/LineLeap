import 'package:flutter/cupertino.dart';

class TypingText extends StatefulWidget {
  final String text;
  final AnimationController controller;
  final TextStyle? style;

  const TypingText({
    super.key,
    required this.text,
    required this.controller,
    this.style,
  });

  @override
  State<TypingText> createState() => _TypingTextState();
}

class _TypingTextState extends State<TypingText> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final progress = widget.controller.value;
        final charCount = (progress * widget.text.length).floor();
        final displayedText = widget.text.substring(
          0,
          charCount.clamp(0, widget.text.length),
        );

        return Text(displayedText, style: widget.style);
      },
    );
  }
}
