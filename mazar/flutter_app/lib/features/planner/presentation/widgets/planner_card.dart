import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/planner_entity.dart';

/// بطاقة تعرض عنصراً واحداً من الجدول الزمني الذكي المُولَّد للمستخدم.
class PlannerCard extends StatelessWidget {
  final PlannerItemEntity item;

  const PlannerCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.access_time_rounded, color: AppColors.primaryGreen),
        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${item.description}\n${DateFormatter.formatTime(item.scheduledTime)}',
        ),
        isThreeLine: true,
      ),
    );
  }
}
