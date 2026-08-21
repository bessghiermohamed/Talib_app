import 'package:flutter/material.dart';

/// Screen-level horizontal padding used across the app.
const double screenPaddingH = 18;

/// Shared «طالب» design components — unified design layer v0.2
class TalibCard extends StatelessWidget {
  const TalibCard({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.onSurface.withOpacity(.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(dark ? .06 : .06),
            blurRadius: 30,
            offset: const Offset(0, 14),
            spreadRadius: -18,
          ),
        ],
      ),
      child: child,
    );
  }
}

class TalibIconTile extends StatelessWidget {
  const TalibIconTile({
    super.key,
    required this.icon,
    this.accent = false,
    this.size = 44,
    this.radius = 14,
    this.iconSize = 20,
  });

  const TalibIconTile.small({
    super.key,
    required this.icon,
    this.size = 34,
    this.radius = 11,
    this.iconSize = 16,
  }) : accent = false;

  final IconData icon;
  final bool accent;
  final double size;
  final double radius;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = accent ? const Color(0xFFC8956C) : cs.primary;
    final fg = accent ? const Color(0xFF9C6238) : cs.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg.withOpacity(accent ? .16 : .09),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: fg),
    );
  }
}

class TalibChip extends StatelessWidget {
  const TalibChip({super.key, required this.text, this.filled = false});
  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? cs.primary : cs.primary.withOpacity(.09),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: filled ? cs.onPrimary : cs.primary,
        ),
      ),
    );
  }
}

class TalibProgressRing extends StatelessWidget {
  const TalibProgressRing({super.key, required this.percent, this.size = 46});
  final int percent;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: percent / 100,
              strokeWidth: 5,
              strokeCap: StrokeCap.round,
              backgroundColor: cs.primary.withOpacity(.13),
              valueColor: AlwaysStoppedAnimation(cs.primary),
            ),
          ),
          Text(
            '$percent%',
            style: TextStyle(
              fontSize: size * .28,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
