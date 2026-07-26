import '../../domain/entities/crowd_entity.dart';

/// النموذج المسؤول عن تحويل بيانات توقع الازدحام من/إلى JSON.
class CrowdPredictionModel extends CrowdPredictionEntity {
  const CrowdPredictionModel({
    required super.locationId,
    required super.locationName,
    required super.level,
    required super.confidenceScore,
    required super.predictedFor,
    super.recommendation,
  });

  factory CrowdPredictionModel.fromJson(Map<String, dynamic> json) {
    return CrowdPredictionModel(
      locationId: json['location_id'] as String,
      locationName: json['location_name'] as String,
      level: _levelFromString(json['level'] as String? ?? 'unknown'),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.0,
      predictedFor: DateTime.parse(json['predicted_for'] as String),
      recommendation: json['recommendation'] as String?,
    );
  }

  static CrowdLevel _levelFromString(String value) {
    switch (value) {
      case 'low':
        return CrowdLevel.low;
      case 'medium':
        return CrowdLevel.medium;
      case 'high':
        return CrowdLevel.high;
      default:
        return CrowdLevel.unknown;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'location_id': locationId,
      'location_name': locationName,
      'level': level.name,
      'confidence_score': confidenceScore,
      'predicted_for': predictedFor.toIso8601String(),
      'recommendation': recommendation,
    };
  }
}
