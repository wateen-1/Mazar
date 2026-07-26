import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/crowd_entity.dart';

/// يعرض مستوى الازدحام المتوقع بلون ورمز مميّزين حسب شدة الازدحام.
class CrowdIndicator extends StatelessWidget {
  final CrowdPredictionEntity prediction;

  const CrowdIndicator({super.key, required this.prediction});

  Color get _color {
    switch (prediction.level) {
      case CrowdLevel.low:
        return AppColors.crowdLow;
      case CrowdLevel.medium:
        return AppColors.crowdMedium;
      case CrowdLevel.high:
        return AppColors.crowdHigh;
      case CrowdLevel.unknown:
        return AppColors.textSecondary;
    }
  }

  String get _label {
    switch (prediction.level) {
      case CrowdLevel.low:
        return 'ازدحام منخفض';
      case CrowdLevel.medium:
        return 'ازدحام متوسط';
      case CrowdLevel.high:
        return 'ازدحام مرتفع';
      case CrowdLevel.unknown:
        return 'غير معروف';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: _color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.groups_rounded, color: _color, size: 40),
            const SizedBox(height: 8),
            Text(
              _label,
              style: TextStyle(color: _color, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              '${prediction.locationName} — دقة التوقع ${(prediction.confidenceScore * 100).toStringAsFixed(0)}%',
            ),
            if (prediction.recommendation != null) ...[
              const SizedBox(height: 8),
              Text(prediction.recommendation!, textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }
}
