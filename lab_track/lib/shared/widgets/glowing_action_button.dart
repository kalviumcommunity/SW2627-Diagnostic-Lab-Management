import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// God-Level Glowing Action Button with gradient background,
/// glowing hover shadow, and micro-press animation.
class GlowingActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final Color? glowColor;
  final bool isLoading;
  final double height;
  final double borderRadius;

  const GlowingActionButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.gradient,
    this.glowColor,
    this.isLoading = false,
    this.height = 48.0,
    this.borderRadius = 14.0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.primaryGradient;
    final effectiveGlowColor = glowColor ?? AppColors.primary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient: onPressed == null ? null : effectiveGradient,
        color: onPressed == null ? AppColors.border : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: effectiveGlowColor.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
