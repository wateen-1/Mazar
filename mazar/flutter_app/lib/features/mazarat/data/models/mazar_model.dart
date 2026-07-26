import '../../domain/entities/mazar_entity.dart';

/// النموذج المسؤول عن تحويل بيانات المزار من/إلى JSON القادم من نقطة
/// النهاية GET /mazarat في خادم مزار. أسماء الحقول هنا تطابق حرفياً أسماء
/// الحقول التي يُعيدها الـ Backend (بصيغة snake_case).
class MazarModel extends MazarEntity {
  const MazarModel({
    required super.id,
    required super.name,
    required super.city,
    required super.description,
    required super.latitude,
    required super.longitude,
    required super.category,
    required super.interactiveExperienceUrl,
    super.distanceInMeters,
    super.isInteractiveAvailable,
  });

  factory MazarModel.fromJson(Map<String, dynamic> json) {
    return MazarModel(
      id: json['id'] as String,
      name: json['name'] as String,
      city: json['city'] as String? ?? '',
      description: json['description'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      category: json['category'] as String,
      interactiveExperienceUrl: json['interactive_experience_url'] as String? ?? '',
      distanceInMeters: (json['distance_in_meters'] as num?)?.toDouble(),
      isInteractiveAvailable: json['is_interactive_available'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'city': city,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'category': category,
      'interactive_experience_url': interactiveExperienceUrl,
      'distance_in_meters': distanceInMeters,
      'is_interactive_available': isInteractiveAvailable,
    };
  }
}
