import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// God-Level Card widget providing squircle glassmorphic styling,
/// subtle gradient borders, rich soft drop shadows, and responsive tap feedback.
class GodLevelCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final LinearGradient? gradient;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final bool hasGlow;
  final Color? glowColor;
  final double elevation;

  const GodLevelCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderColor,
    this.borderRadius = 18.0,
    this.onTap,
    this.hasGlow = false,
    this.glowColor,
    this.elevation = 0,
  });

  @override
  State<GodLevelCard> createState() => _GodLevelCardState();
}

class _GodLevelCardState extends State<GodLevelCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ??
        (_isHovered ? AppColors.primary.withOpacity(0.5) : AppColors.border);

    final glow = widget.hasGlow || _isHovered
        ? [
            BoxShadow(
              color: (widget.glowColor ?? AppColors.primary).withOpacity(_isHovered ? 0.22 : 0.14),
              blurRadius: _isHovered ? 22 : 16,
              offset: const Offset(0, 8),
            ),
            const BoxShadow(
              color: Color(0x080F172A),
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ]
        : AppColors.softCardShadow;

    Widget content = Container(
      margin: widget.margin,
      decoration: BoxDecoration(
        color: widget.gradient == null ? (widget.backgroundColor ?? Colors.white) : null,
        gradient: widget.gradient,
        borderRadius: BorderRadius.circular(widget.borderRadius),
        border: Border.all(color: effectiveBorderColor, width: _isHovered ? 1.5 : 1.0),
        boxShadow: glow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: Padding(
          padding: widget.padding ?? EdgeInsets.zero,
          child: widget.child,
        ),
      ),
    );

    if (widget.onTap != null) {
      content = MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          child: content,
        ),
      );
    }

    return content;
  }
}
