import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum ActionButtonStyle { primary, secondary, destructive }

class ActionButton extends StatefulWidget {
  final IconData? icon;
  final String? tooltip;
  final VoidCallback onPressed;
  final ActionButtonStyle style;
  final bool showBorder;
  final bool disabled;

  const ActionButton({
    super.key,
    this.icon,
    this.tooltip,
    required this.onPressed,
    this.style = ActionButtonStyle.primary,
    this.showBorder = true,
    this.disabled = false,
  });

  @override
  State<ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.disabled) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Define colors based on style
    Color textColor;
    Color bgColor;

    switch (widget.style) {
      case ActionButtonStyle.primary:
        textColor = theme.colorScheme.onPrimary;
        bgColor = theme.colorScheme.primary;
        break;
      case ActionButtonStyle.destructive:
        textColor = CupertinoColors.white;
        bgColor = CupertinoColors.destructiveRed;
        break;
      default:
        textColor = isDarkMode ? CupertinoColors.white : CupertinoColors.black;
        bgColor =
            isDarkMode
                ? const Color.fromARGB(51, 159, 159, 213)
                : const Color.fromARGB(111, 249, 249, 250);
    }

    return Material(
      color: Colors.transparent,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: _onTapDown,
          onTapUp: _onTapUp,
          onTapCancel: _onTapCancel,
          onTap: widget.disabled ? null : widget.onPressed,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Opacity(
                  opacity: _opacityAnimation.value,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: widget.disabled
                          ? bgColor.withValues(alpha: 0.5)
                          : _isHovered
                              ? bgColor.withValues(alpha: 0.9)
                              : bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border:
                          widget.showBorder
                              ? Border.all(
                                color:
                                    isDarkMode
                                        ? CupertinoColors.systemGrey5.darkColor
                                        : CupertinoColors.systemGrey5.color,
                                width: 0.5,
                              )
                              : null,
                      boxShadow: _isHovered && !widget.disabled
                          ? [
                            BoxShadow(
                              color: bgColor.withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                          : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (widget.icon != null)
                          Icon(widget.icon, color: textColor, size: 18),
                        if (widget.icon != null && widget.tooltip != null)
                          const SizedBox(width: 8),
                        if (widget.tooltip != null)
                          Text(
                            widget.tooltip!,
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
