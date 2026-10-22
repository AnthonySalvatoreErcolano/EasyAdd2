import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import 'board_feet_screen.dart';
import 'concrete_screen.dart';
import 'convert_screen.dart';
import 'stairs_screen.dart';

class ToolsScreen extends StatelessWidget {
  const ToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(Widget screen) => Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => screen));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
          child: Text(
            'Tools',
            style: AppText.style(
              30,
              weight: FontWeight.w700,
              color: AppColors.chalkWhite,
            ),
          ),
        ),
        _ToolCard(
          icon: Icons.foundation,
          title: 'Concrete',
          subtitle: 'Yards and bags for slabs, footings and columns',
          onTap: () => open(const ConcreteScreen()),
        ),
        _ToolCard(
          icon: Icons.stairs_outlined,
          title: 'Stairs',
          subtitle: 'Risers, treads, run and stringer length',
          onTap: () => open(const StairsScreen()),
        ),
        _ToolCard(
          icon: Icons.carpenter,
          title: 'Board Feet',
          subtitle: 'Lumber volume and cost',
          onTap: () => open(const BoardFeetScreen()),
        ),
        _ToolCard(
          icon: Icons.straighten,
          title: 'Convert',
          subtitle: 'Feet, inches, decimal feet and metric',
          onTap: () => open(const ConvertScreen()),
        ),
      ],
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Material(
      color: AppColors.keySteel,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.tapeYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.inkBlack, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppText.style(
                        18,
                        weight: FontWeight.w700,
                        color: AppColors.chalkWhite,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppText.style(14, color: AppColors.chalkDim),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.chalkDim),
            ],
          ),
        ),
      ),
    ),
  );
}
