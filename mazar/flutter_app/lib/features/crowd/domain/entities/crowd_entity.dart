import 'package:equatable/equatable.dart';

enum CrowdLevel { low, medium, high, unknown }

/// يمثّل توقّع مستوى الازدحام في مكان وزمن معينين.
class CrowdPredictionEntity extends Equatable {
  final String locationId;
  final String locationName;
  final CrowdLevel level;
  final double confidenceScore;
  final DateTime predictedFor;
  final String? recommendation;

  const CrowdPredictionEntity({
    required this.locationId,
    required this.locationName,
    required this.level,
    required this.confidenceScore,
    required this.predictedFor,
    this.recommendation,
  });

  @override
  List<Object?> get props => [
        locationId,
        locationName,
        level,
        confidenceScore,
        predictedFor,
        recommendation,
      ];
}
