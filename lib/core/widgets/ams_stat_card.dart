import 'package:flutter/material.dart';
import '../../app/theme/app_theme.dart';

typedef AMSStatCard = AmsStatCard;

class AmsStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final IconData icon;
  final Color iconColor;
  final Color? iconBgColor;
  final double? progress; // 0.0 to 1.0
  final Color? progressColor;
  final VoidCallback? onTap;

  const AmsStatCard({
    super.key,
    String? label,
    String? title,
    required this.value,
    this.subtitle,
    String? badgeText,
    String? badge,
    this.badgeColor,
    this.badgeTextColor,
    required this.icon,
    Color? iconColor,
    Color? color,
    this.iconBgColor,
    this.progress,
    this.progressColor,
    this.onTap,
  })  : label = label ?? title ?? '',
        badgeText = badgeText ?? badge,
        iconColor = iconColor ?? color ?? AppTheme.primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x12000000)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row: Label & Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        label.toUpperCase(),
                        style: const TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: iconBgColor ?? AppTheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: iconColor, size: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Middle: Value & Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor ?? AppTheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badgeText!,
                          style: TextStyle(
                            color: badgeTextColor ?? AppTheme.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                // Subtitle
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Optional Progress bar
                if (progress != null) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress!.clamp(0.0, 1.0),
                      backgroundColor: AppTheme.surfaceContainerHigh,
                      valueColor: AlwaysStoppedAnimation<Color>(progressColor ?? AppTheme.primary),
                      minHeight: 4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
