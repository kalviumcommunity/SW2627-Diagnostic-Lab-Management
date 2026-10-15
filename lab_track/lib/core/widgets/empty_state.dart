import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// God-Level Empty State display widget
class EmptyState extends StatelessWidget {
  final String title;
  final String? message;
  final IconData icon;
  final Widget? action;

  const EmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
