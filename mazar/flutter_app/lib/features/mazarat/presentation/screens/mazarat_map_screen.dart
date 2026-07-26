import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../crowd/domain/entities/crowd_entity.dart';
import '../../../crowd/presentation/providers/crowd_provider.dart';
import '../../domain/entities/mazar_entity.dart';
import '../providers/mazarat_provider.dart';

/// شاشة خريطة المزارات التفاعلية الكاملة.
///
/// تعرض جميع مزارات التطبيق القريبة من موقع المستخدم الحالي (القادمة حيّة من
/// نقطة النهاية GET /mazarat) كعلامات (Markers) حقيقية على خريطة قوقل،
/// محاطة كل واحدة منها بهالة لونية خفيفة (Circle) تعكس حالة الازدحام
/// الحالية لذلك المعلم تحديداً (القادمة بشكل مستقل من نقطة النهاية
/// GET /crowd لكل معلم على حدة عبر crowdPredictionByLocationProvider):
/// أخضر خافت لحالة انسيابية، ذهبي/برتقالي لحالة متوسطة، وأحمر دافئ لحالة
/// ازدحام شديد، مع نبض هادئ متكرر لهالات الازدحام الشديد فقط لجذب الانتباه
/// دون إزعاج بصري أو إرهاق لقناة الاتصال مع الخريطة الأصلية.
///
/// الضغط على أي علامة يفتح كارتاً سفلياً منبثقاً (ينزلق من أسفل الشاشة دون
/// حجب الخريطة بالكامل) بتصميم فخم يعرض اسم المعلم، مؤشر المسافة، وحالة
/// الازدحام الحيّة، مع زر ينقل المستخدم مباشرة إلى شاشة التفاصيل الكاملة
/// MazarDetailScreen.
class MazaratMapScreen extends ConsumerStatefulWidget {
  const MazaratMapScreen({super.key});

  @override
  ConsumerState<MazaratMapScreen> createState() => _MazaratMapScreenState();
}

class _MazaratMapScreenState extends ConsumerState<MazaratMapScreen> {
  GoogleMapController? _mapController;

  /// المعلم المختار حالياً؛ يتحكم في ظهور الكارت السفلي وموضعه.
  MazarEntity? _selectedMazar;

  /// يحتفظ بآخر معلم تم اختياره حتى أثناء إغلاق الكارت، حتى لا يختفي
  /// محتوى الكارت فجأة أثناء حركة الانزلاق للأسفل (280 مللي ثانية).
  MazarEntity? _lastSelectedMazar;

  /// مؤقّت بسيط يبدّل حالة النبض كل 900 مللي ثانية لهالات الازدحام الشديد
  /// فقط، بديلاً خفيفاً عن AnimationController المستمر (60 لقطة/ثانية)
  /// الذي كان سيرسل تحديثات مفرطة إلى خريطة قوقل الأصلية عبر القناة
  /// البرمجية (Platform Channel) في كل إطار.
  Timer? _pulseTimer;
  bool _pulseExpanded = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(21.4225, 39.8262), // المسجد الحرام كموقع افتراضي عند تعذر تحديد الموقع
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();

    _pulseTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted) return;
      setState(() => _pulseExpanded = !_pulseExpanded);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocationAndLoadMazarat());
  }

  @override
  void dispose() {
    _pulseTimer?.cancel();
    super.dispose();
  }

  /// يحاول تحديد موقع المستخدم الحالي عبر GPS، ثم يطلب من الخادم قائمة
  /// مزارات التطبيق القريبة منه. في حال تعذّر الوصول للموقع، يُستخدم موقع
  /// المسجد الحرام كموقع افتراضي حتى تبقى الخريطة مفيدة وتعرض بيانات
  /// فعلية من الخادم.
  Future<void> _initLocationAndLoadMazarat() async {
    double latitude = 21.4225;
    double longitude = 39.8262;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever) {
        final position = await Geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }
    } catch (_) {
      // يبقى الموقع الافتراضي (المسجد الحرام) مستخدماً عند تعذّر الوصول للـ GPS
    }

    if (!mounted) return;
    await ref.read(mazaratNotifierProvider.notifier).loadNearbyMazarat(latitude, longitude);
  }

  /// يحرّك الكاميرا لتضم جميع علامات المزارات ضمن مجال الرؤية دفعة واحدة،
  /// أو يقرّب مباشرة على المعلم الوحيد إن كانت النتيجة معلماً واحداً فقط.
  Future<void> _animateCameraToFitAll(List<MazarEntity> mazarat) async {
    if (_mapController == null || mazarat.isEmpty) return;

    if (mazarat.length == 1) {
      final only = mazarat.first;
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(only.latitude, only.longitude), 15),
      );
      return;
    }

    double minLat = mazarat.first.latitude;
    double maxLat = mazarat.first.latitude;
    double minLng = mazarat.first.longitude;
    double maxLng = mazarat.first.longitude;

    for (final mazar in mazarat) {
      minLat = mazar.latitude < minLat ? mazar.latitude : minLat;
      maxLat = mazar.latitude > maxLat ? mazar.latitude : maxLat;
      minLng = mazar.longitude < minLng ? mazar.longitude : minLng;
      maxLng = mazar.longitude > maxLng ? mazar.longitude : maxLng;
    }

    await _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        64,
      ),
    );
  }

  void _selectMazar(MazarEntity mazar) {
    setState(() {
      _selectedMazar = mazar;
      _lastSelectedMazar = mazar;
    });
  }

  void _closeCard() {
    setState(() => _selectedMazar = null);
  }

  /// يحوّل حالة توقّع الازدحام (AsyncValue) إلى لون الهالة المناسب حول
  /// المعلم، وفق الهوية اللونية الفخمة المعتمدة في التطبيق: أخضر خافت
  /// (crowdLow) للحالة الانسيابية، ذهبي/برتقالي (crowdMedium) للحالة
  /// المتوسطة، أحمر دافئ (crowdHigh) للازدحام الشديد، ولون محايد أثناء
  /// التحميل أو عند تعذّر تحديد الحالة.
  Color _crowdHaloColor(AsyncValue<CrowdPredictionEntity> asyncPrediction) {
    return asyncPrediction.when(
      data: (prediction) {
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
      },
      loading: () => AppColors.textSecondary,
      error: (_, __) => AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mazaratState = ref.watch(mazaratNotifierProvider);

    // نستمع لتغيّرات قائمة المزارات لتحريك الكاميرا تلقائياً لتضم جميع
    // العلامات فور وصول أول دفعة بيانات من الخادم، بصرف النظر عمّا إذا
    // كانت خريطة قوقل قد انتهت من التهيئة (onMapCreated) قبل أم بعد ذلك.
    ref.listen<MazaratState>(mazaratNotifierProvider, (previous, next) {
      final wasEmpty = previous == null || previous.mazarat.isEmpty;
      if (wasEmpty && next.mazarat.isNotEmpty) {
        _animateCameraToFitAll(next.mazarat);
      }
    });

    final markers = mazaratState.mazarat.map((mazar) {
      return Marker(
        markerId: MarkerId(mazar.id),
        position: LatLng(mazar.latitude, mazar.longitude),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
        onTap: () => _selectMazar(mazar),
      );
    }).toSet();

    final circles = <Circle>{};
    for (final mazar in mazaratState.mazarat) {
      final asyncPrediction = ref.watch(crowdPredictionByLocationProvider(mazar.id));
      final haloColor = _crowdHaloColor(asyncPrediction);

      final isHighCongestion = asyncPrediction.maybeWhen(
        data: (prediction) => prediction.level == CrowdLevel.high,
        orElse: () => false,
      );

      final radius = isHighCongestion ? (_pulseExpanded ? 118.0 : 88.0) : 90.0;

      circles.add(
        Circle(
          circleId: CircleId('halo_${mazar.id}'),
          center: LatLng(mazar.latitude, mazar.longitude),
          radius: radius,
          fillColor: haloColor.withOpacity(isHighCongestion ? 0.22 : 0.15),
          strokeColor: haloColor.withOpacity(0.5),
          strokeWidth: 1,
          consumeTapEvents: false,
        ),
      );
    }

    final displayedMazar = _selectedMazar ?? _lastSelectedMazar;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.mazaratTitle),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _defaultPosition,
            markers: markers,
            circles: circles,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              if (mazaratState.mazarat.isNotEmpty) {
                _animateCameraToFitAll(mazaratState.mazarat);
              }
            },
            onTap: (_) => _closeCard(),
          ),

          if (mazaratState.isLoading)
            const Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.backgroundSecondary,
              ),
            ),

          if (mazaratState.errorMessage != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _MapErrorBanner(message: mazaratState.errorMessage!),
            ),

          const Positioned(bottom: 16, right: 16, child: _CrowdLegend()),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _selectedMazar != null ? 0 : -300,
            child: displayedMazar == null
                ? const SizedBox.shrink()
                : _MazarInfoCard(mazar: displayedMazar, onClose: _closeCard),
          ),
        ],
      ),
    );
  }
}

/// كارت سفلي فخم منبثق يظهر عند اختيار علامة (Marker) على الخريطة، يعرض
/// اسم المعلم ومؤشر المسافة وحالة الازدحام الحيّة الخاصة به تحديداً
/// (عبر crowdPredictionByLocationProvider)، إلى جانب زر ينقل المستخدم
/// مباشرة إلى شاشة التفاصيل الكاملة MazarDetailScreen.
class _MazarInfoCard extends ConsumerWidget {
  final MazarEntity mazar;
  final VoidCallback onClose;

  const _MazarInfoCard({required this.mazar, required this.onClose});

  String get _formattedDistance {
    final meters = mazar.distanceInMeters;
    if (meters == null) return '';
    if (meters < 1000) {
      return '${meters.round()} م';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  IconData get _categoryIcon {
    return mazar.category == 'مسجد' ? Icons.mosque_rounded : Icons.terrain_rounded;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPrediction = ref.watch(crowdPredictionByLocationProvider(mazar.id));

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(_categoryIcon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mazar.name,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: AppColors.olive),
                          const SizedBox(width: 3),
                          Text(
                            mazar.city,
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (_formattedDistance.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              '· يبعد $_formattedDistance',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.olive,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, size: 18, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _CrowdStatusBadge(asyncPrediction: asyncPrediction),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.pushNamed('mazaratDetail', extra: mazar),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                label: const Text(
                  'عرض التفاصيل الكاملة',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شارة تعرض حالة الازدحام الحيّة لمعلم معيّن داخل الكارت السفلي، بثلاث
/// حالات لونية واضحة (منخفض/متوسط/مرتفع) بالإضافة إلى حالتي التحميل
/// والخطأ، متّسقة تماماً مع ألوان الهالات على الخريطة نفسها.
class _CrowdStatusBadge extends StatelessWidget {
  final AsyncValue<CrowdPredictionEntity> asyncPrediction;

  const _CrowdStatusBadge({required this.asyncPrediction});

  @override
  Widget build(BuildContext context) {
    return asyncPrediction.when(
      loading: () => _buildBadge(
        color: AppColors.textSecondary,
        icon: Icons.hourglass_top_rounded,
        label: 'جارٍ تحديد مستوى الازدحام...',
      ),
      error: (_, __) => _buildBadge(
        color: AppColors.textSecondary,
        icon: Icons.help_outline_rounded,
        label: 'تعذر تحديد مستوى الازدحام حالياً',
      ),
      data: (prediction) {
        final config = _configFor(prediction.level);
        return _buildBadge(color: config.color, icon: config.icon, label: config.label);
      },
    );
  }

  ({Color color, IconData icon, String label}) _configFor(CrowdLevel level) {
    switch (level) {
      case CrowdLevel.low:
        return (
          color: AppColors.crowdLow,
          icon: Icons.check_circle_rounded,
          label: 'ازدحام منخفض — الأجواء انسيابية الآن',
        );
      case CrowdLevel.medium:
        return (
          color: AppColors.crowdMedium,
          icon: Icons.access_time_filled_rounded,
          label: 'ازدحام متوسط — يُنصح بالتحلي بقليل من الصبر',
        );
      case CrowdLevel.high:
        return (
          color: AppColors.crowdHigh,
          icon: Icons.warning_rounded,
          label: 'ازدحام مرتفع جداً — قد تطول مدة الزيارة',
        );
      case CrowdLevel.unknown:
        return (
          color: AppColors.textSecondary,
          icon: Icons.help_outline_rounded,
          label: 'مستوى الازدحام غير معروف حالياً',
        );
    }
  }

  Widget _buildBadge({required Color color, required IconData icon, required String label}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// دليل ألوان (Legend) صغير وثابت أعلى يمين الخريطة، يشرح للمستخدم معنى
/// كل لون من ألوان الهالات المحيطة بالمعالم قبل أن يبدأ باستكشافها.
class _CrowdLegend extends StatelessWidget {
  const _CrowdLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _LegendRow(color: AppColors.crowdLow, label: 'انسيابي'),
          SizedBox(height: 5),
          _LegendRow(color: AppColors.crowdMedium, label: 'متوسط'),
          SizedBox(height: 5),
          _LegendRow(color: AppColors.crowdHigh, label: 'مزدحم جداً'),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendRow({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

/// شريط تنبيه صغير أعلى الخريطة يظهر عند فشل جلب قائمة المزارات من الخادم.
class _MapErrorBanner extends StatelessWidget {
  final String message;

  const _MapErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: AppColors.navy.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
