import 'package:flutter/material.dart';

import '../sky_theme.dart';

/// A reusable circular badge with the sun-glow gradient used across the app bars.
class SkySunBadge extends StatelessWidget {
  const SkySunBadge({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize,
    this.shadowOpacity = 0.18,
    this.blurRadius = 10,
    this.shadowOffset = const Offset(0, 4),
  });

  final IconData icon;
  final double size;
  final double? iconSize;
  final double shadowOpacity;
  final double blurRadius;
  final Offset shadowOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SkyGradients.sunGlow,
        boxShadow: SkyShadows.soft(
          opacity: shadowOpacity,
          blurRadius: blurRadius,
          offset: shadowOffset,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        color: Colors.white,
        size: iconSize ?? size * 0.55,
      ),
    );
  }
}

/// A title/subtitle combination that matches the Icarus sky branding.
class SkyAppBarHeader extends StatelessWidget {
  const SkyAppBarHeader({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.titleStyle,
    this.subtitleStyle,
    this.spacing = 12,
  });

  final Widget leading;
  final String title;
  final String? subtitle;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle resolvedTitleStyle = titleStyle ??
        textTheme.titleMedium!.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        );
    final TextStyle? resolvedSubtitleStyle = subtitle == null
        ? null
        : (subtitleStyle ??
            textTheme.bodySmall?.copyWith(
              color: Colors.white70,
            ));

    return Row(
      children: <Widget>[
        leading,
        SizedBox(width: spacing),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(title, style: resolvedTitleStyle),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 2),
              Text(subtitle!, style: resolvedSubtitleStyle),
            ],
          ],
        ),
      ],
    );
  }
}
