import 'package:flutter/material.dart';
import '../constants/theme.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double radius;
  final Color? color;
  const AppCard({super.key, required this.child, this.padding, this.radius = 20, this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color ?? AppColors.card,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.border, width: 1),
    ),
    child: child,
  );
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontFamily: 'Syne', fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        if (action != null)
          GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

class AppLabel extends StatelessWidget {
  final String text;
  final EdgeInsets? padding;
  const AppLabel(this.text, {super.key, this.padding});

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding ?? EdgeInsets.zero,
    child: Text(text.toUpperCase(), style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600, letterSpacing: 0.7)),
  );
}

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  const StatusBadge(this.text, {super.key, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
  );
}

class MacroBar extends StatelessWidget {
  final double value;
  final double max;
  final Color color;
  const MacroBar({super.key, required this.value, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final pct = max > 0 ? (value / max).clamp(0.0, 1.0) : 0.0;
    return Container(
      height: 3,
      decoration: BoxDecoration(color: AppColors.card2, borderRadius: BorderRadius.circular(2)),
      child: FractionallySizedBox(
        widthFactor: pct,
        alignment: Alignment.centerLeft,
        child: Container(decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      ),
    );
  }
}

class PillTabBar extends StatelessWidget {
  final List<String> tabs;
  final String active;
  final ValueChanged<String> onChanged;
  const PillTabBar({super.key, required this.tabs, required this.active, required this.onChanged});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: tabs.map((tab) => GestureDetector(
        onTap: () => onChanged(tab),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: active == tab ? AppColors.secondary : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: active == tab ? AppColors.secondary : AppColors.border2),
          ),
          child: Text(tab, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500,
            color: active == tab ? AppColors.pale : AppColors.textSecondary,
          )),
        ),
      )).toList(),
    ),
  );
}

class EmptyState extends StatelessWidget {
  final String emoji;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.emoji, required this.title, this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(emoji, style: const TextStyle(fontSize: 44)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary), textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
        ],
        if (actionLabel != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ]),
    ),
  );
}

class GreenButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool disabled;
  const GreenButton({super.key, required this.label, required this.onPressed, this.isLoading = false, this.disabled = false});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    height: 50,
    child: ElevatedButton(
      onPressed: (disabled || isLoading) ? null : onPressed,
      child: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: AppColors.pale, strokeWidth: 2))
          : Text(label),
    ),
  );
}

class ModalHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const ModalHeader({super.key, required this.title, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_ios_new, color: AppColors.textSecondary, size: 20),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: const TextStyle(fontFamily: 'Syne', fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary))),
      if (action != null)
        GestureDetector(onTap: onAction, child: Text(action!, style: const TextStyle(color: AppColors.accent, fontSize: 14, fontWeight: FontWeight.w600))),
    ]),
  );
}
