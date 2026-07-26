import 'package:equatable/equatable.dart';

import '../../../crowd/domain/entities/crowd_entity.dart';

/// يمثل عنصراً واحداً ضمن الجدول الزمني الذكي الذي يولّده محرك التخطيط.
///
/// الحقول الثلاثة الأخيرة (dayNumber، distanceToNextMeters، crowdStatus)
/// تقابل الحقول الإضافية التي أصبح محرك التخطيط الذكي الفعلي في الخادم
/// يُعيدها الآن مع كل عنصر: رقم اليوم ضمن خطة الرحلة، والمسافة الجغرافية
/// بالمتر إلى المعلم التالي مباشرة في ترتيب الخطة، وتوقع تقريبي لحالة
/// الازدحام وقت الزيارة. نُعيد استخدام تعداد CrowdLevel نفسه المستخدم في
/// ميزة الازدحام (features/crowd) بدلاً من نص خام، لضمان اتساق الألوان
/// والمنطق بين شاشة الخريطة وشاشة المخطط الذكي.
class PlannerItemEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledTime;
  final String? locationName;
  final double? latitude;
  final double? longitude;
  final int dayNumber;
  final double? distanceToNextMeters;
  final CrowdLevel crowdStatus;

  const PlannerItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledTime,
    this.locationName,
    this.latitude,
    this.longitude,
    this.dayNumber = 1,
    this.distanceToNextMeters,
    this.crowdStatus = CrowdLevel.unknown,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        scheduledTime,
        locationName,
        latitude,
        longitude,
        dayNumber,
        distanceToNextMeters,
        crowdStatus,
      ];
}

/// يمثل طلب توليد جدول زيارة ذكي يرسله المستخدم إلى نقطة النهاية /planner.
class PlannerRequestEntity extends Equatable {
  final DateTime visitDate;
  final int numberOfDays;
  final List<String> preferredCategories;
  final double? currentLatitude;
  final double? currentLongitude;

  const PlannerRequestEntity({
    required this.visitDate,
    required this.numberOfDays,
    this.preferredCategories = const [],
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  List<Object?> get props => [
        visitDate,
        numberOfDays,
        preferredCategories,
        currentLatitude,
        currentLongitude,
      ];
}
