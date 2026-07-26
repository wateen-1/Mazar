import 'package:equatable/equatable.dart';

/// يمثّل مزاراً أو معلماً دينياً وتاريخياً واحداً ضمن مزارات التطبيق، بما
/// يطابق تماماً شكل البيانات القادم من نقطة النهاية GET /mazarat في الخادم.
class MazarEntity extends Equatable {
  final String id;
  final String name;
  final String city;
  final String description;
  final double latitude;
  final double longitude;
  final String category;
  final String interactiveExperienceUrl;
  final double? distanceInMeters;
  final bool isInteractiveAvailable;

  const MazarEntity({
    required this.id,
    required this.name,
    required this.city,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.interactiveExperienceUrl,
    this.distanceInMeters,
    this.isInteractiveAvailable = false,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        city,
        description,
        latitude,
        longitude,
        category,
        interactiveExperienceUrl,
        distanceInMeters,
        isInteractiveAvailable,
      ];
}
