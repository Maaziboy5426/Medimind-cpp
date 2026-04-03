import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum StatusType { success, warning, error, info }

/// Small status pill for labels like "Active", "Pending", "Completed".
class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    this.type = StatusType.info,
    this.color,
  });

  final String label;
  final StatusType type;
  final Color? color;

  static Color _colorFor(StatusType t) {
    switch (t) {
      case StatusType.success:
        return AppTheme.success;
      case StatusType.warning:
        return const Color(0xFFFFB74D);
      case StatusType.error:
        return AppTheme.error;
      case StatusType.info:
        return AppTheme.cyanAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? _colorFor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: effectiveColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: effectiveColor.withOpacity(0.5), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
