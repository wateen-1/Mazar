import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/mazar_entity.dart';

/// بطاقة تفاصيل تظهر عند اختيار مزار معيّن من الخريطة أو من قائمة النتائج.
class MazarDetailsCard extends StatelessWidget {
  final MazarEntity mazar;
  final VoidCallback? onActivate;

  const MazarDetailsCard({super.key, required this.mazar, this.onActivate});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(mazar.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(mazar.description, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            if (!mazar.isInteractiveAvailable)
              ElevatedButton.icon(
                onPressed: onActivate,
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('تفعيل المزار عند الوصول'),
              )
            else
              const Chip(label: Text('التجربة التفاعلية متاحة الآن')),
          ],
        ),
      ),
    );
  }
}
