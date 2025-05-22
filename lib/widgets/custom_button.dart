import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isDisabled;
  final IconData? icon;
  final double width;
  final double height;
  final bool isSecondary;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isDisabled = false,
    this.icon,
    this.width = double.infinity,
    this.height = 50,
    this.isSecondary = false,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Button colors based on theme and state
    final Color backgroundColor = widget.isSecondary
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;
    
    final Color textColor = widget.isSecondary
        ? theme.colorScheme.onSecondary
        : theme.colorScheme.onPrimary;

    return GestureDetector(
      onTapDown: widget.isDisabled
          ? null
          : (_) => _animationController.forward(),
      onTapUp: widget.isDisabled
          ? null
          : (_) {
              _animationController.reverse();
              widget.onPressed();
            },
      onTapCancel: widget.isDisabled
          ? null
          : () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isDisabled ? 1.0 : _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.isDisabled
                ? Colors.grey.shade400
                : backgroundColor,
            borderRadius: BorderRadius.circular(15),
            boxShadow: widget.isDisabled
                ? []
                : [
                    BoxShadow(
                      color: backgroundColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[  
                  Icon(
                    widget.icon,
                    color: textColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.text,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}