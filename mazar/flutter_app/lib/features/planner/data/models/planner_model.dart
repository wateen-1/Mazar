import '../../../crowd/domain/entities/crowd_entity.dart';
import '../../domain/entities/planner_entity.dart';

/// النموذج المسؤول عن تحويل بيانات عنصر الجدول الزمني من/إلى JSON القادم
/// من محرك التخطيط الذكي الفعلي في الخادم (POST /planner).
///
/// يقرأ هذا النموذج الحقول الأساسية الخمسة (كما في السابق) بالإضافة إلى
/// ثلاثة حقول إضافية أصبح الخادم يُعيدها الآن: day_number،
/// distance_to_next_meters، وcrowd_status. جميع هذه الحقول الإضافية تُقرأ
/// بأمان تام مع قيم افتراضية منطقية عند غيابها أو كونها null في الاستجابة
/// (عميل قديم من الخادم مثلاً)، حتى لا ينهار التطبيق أو يُظهر بيانات
/// ناقصة بشكل مفاجئ.
class PlannerItemModel extends PlannerItemEntity {
  const PlannerItemModel({
    required super.id,
    required super.title,
    required super.description,
    required super.scheduledTime,
    super.locationName,
    super.latitude,
    super.longitude,
    super.dayNumber,
    super.distanceToNextMeters,
    super.crowdStatus,
  });

  factory PlannerItemModel.fromJson(Map<String, dynamic> json) {
    return PlannerItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      scheduledTime: DateTime.parse(json['scheduled_time'] as String),
      locationName: json['location_name'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      // day_number: قيمة افتراضية آمنة هي 1 (اليوم الأول) عند غيابه أو null،
      // بدلاً من ترك رقم اليوم فارغاً أو مسبباً خطأ تحويل نوع (Type Cast).
      dayNumber: (json['day_number'] as num?)?.toInt() ?? 1,
      // distance_to_next_meters: يبقى null بأمان تام إن غاب من الاستجابة،
      // وهي حالة طبيعية ومتوقعة لآخر معلم في الخطة بأكملها (لا يوجد "تالٍ").
      distanceToNextMeters: (json['distance_to_next_meters'] as num?)?.toDouble(),
      // crowd_status: يُحوَّل النص القادم من الخادم ("Low" | "Medium" | "High")
      // إلى تعداد CrowdLevel الموحّد عبر التطبيق، مع قيمة افتراضية آمنة
      // CrowdLevel.unknown لأي قيمة غير متوقعة أو غائبة.
      crowdStatus: _parseCrowdStatus(json['crowd_status'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'scheduled_time': scheduledTime.toIso8601String(),
      'location_name': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'day_number': dayNumber,
      'distance_to_next_meters': distanceToNextMeters,
      'crowd_status': _crowdStatusToJson(crowdStatus),
    };
  }

  /// يحوّل نص حالة الازدحام القادم من الخادم إلى تعداد CrowdLevel الموحّد.
  /// أي قيمة غير معروفة (بما في ذلك null) تُعامَل بأمان كـ CrowdLevel.unknown
  /// بدلاً من إطلاق استثناء يوقف تحويل بقية عناصر الجدول الزمني.
  static CrowdLevel _parseCrowdStatus(String? value) {
    switch (value) {
      case 'Low':
        return CrowdLevel.low;
      case 'Medium':
        return CrowdLevel.medium;
      case 'High':
        return CrowdLevel.high;
      default:
        return CrowdLevel.unknown;
    }
  }

  /// التحويل العكسي لتعداد CrowdLevel إلى النص المتوقَع من الخادم، للحفاظ
  /// على تناظر كامل بين fromJson وtoJson.
  static String? _crowdStatusToJson(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return 'Low';
      case CrowdLevel.medium:
        return 'Medium';
      case CrowdLevel.high:
        return 'High';
      case CrowdLevel.unknown:
        return null;
    }
  }
}
