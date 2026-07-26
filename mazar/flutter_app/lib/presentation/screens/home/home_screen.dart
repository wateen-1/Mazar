import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../features/mazarat/domain/entities/mazar_entity.dart';
import '../../../features/mazarat/presentation/providers/mazarat_provider.dart';

/// الشاشة الرئيسية لتطبيق مزار، تظهر مباشرة بعد شاشة البداية.
///
/// تتكون من ثلاثة أقسام رئيسية مرتّبة عمودياً:
///   1. رأسية ترحيبية ذكية تتغيّر تحيّتها حسب وقت اليوم الحالي.
///   2. بطاقة فخمة تمثّل مساحة الخريطة التفاعلية (Placeholder حالياً،
///      وتفتح خريطة قوقل الفعلية عند الضغط عليها).
///   3. قسم سفلي مرن يعرض "المزارات التفاعلية المجاورة"، ببيانات حيّة
///      قادمة من نقطة النهاية GET /mazarat في الخادم. الضغط على أي بطاقة
///      يفتح شاشة تفاصيل المزار الكاملة (MazarDetailScreen)، حيث تظهر
///      شارة "التجربة التفاعلية متاحة الآن" على البطاقة فقط للمعالم التي
///      يكون فيها المستخدم ضمن النطاق المسموح به (is_interactive_available).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNearbyMazarat());
  }

  /// يحاول تحديد موقع المستخدم الحالي عبر GPS، ثم يطلب من الخادم قائمة
  /// مزارات التطبيق القريبة منه. في حال تعذّر الوصول للموقع أو رفض المستخدم
  /// منح الصلاحية، يُستخدم موقع المسجد الحرام في مكة المكرمة كموقع
  /// افتراضي حتى تبقى الشاشة مفيدة وتعرض بيانات فعلية من الخادم.
  Future<void> _loadNearbyMazarat() async {
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

  /// يبني نصاً ترحيبياً ذكياً يتغيّر بحسب وقت اليوم الحالي على جهاز المستخدم.
  String get _smartGreeting {
    final hour = DateTime.now().hour;
    if (hour >= 4 && hour < 12) {
      return 'صباح الخير';
    } else if (hour >= 12 && hour < 17) {
      return 'طاب يومك';
    } else if (hour >= 17 && hour < 21) {
      return 'مساء الخير';
    }
    return 'أهلاً بك';
  }

  @override
  Widget build(BuildContext context) {
    final mazaratState = ref.watch(mazaratNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: _loadNearbyMazarat,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _WelcomeHeader(greeting: _smartGreeting)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: _MapPlaceholderCard(
                    // نستخدم pushNamed بدلاً من goNamed حتى تُضاف شاشة الخريطة
                    // فوق الشاشة الرئيسية في مكدس التنقل (Navigation Stack)،
                    // فيحصل المستخدم على زر رجوع طبيعي وسلس بدلاً من استبدال
                    // الموقع الحالي بالكامل.
                    onTap: () => context.pushNamed('mazarat'),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 30, 20, 12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'المزارات التفاعلية المجاورة',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ),
                      if (mazaratState.mazarat.isNotEmpty)
                        Text(
                          '${mazaratState.mazarat.length} معالم',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              _buildMazaratSliver(mazaratState),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }

  /// يبني القسم السفلي المرن الذي يعرض حالة قائمة المزارات: تحميل، خطأ،
  /// قائمة فارغة، أو قائمة كروت المزارات الفعلية القادمة من الخادم.
  Widget _buildMazaratSliver(MazaratState state) {
    if (state.isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.2),
          ),
        ),
      );
    }

    if (state.errorMessage != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: _ErrorState(message: state.errorMessage!, onRetry: _loadNearbyMazarat),
        ),
      );
    }

    if (state.mazarat.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30),
          child: Center(
            child: Text(
              'لم يتم العثور على مزارات قريبة حالياً',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final mazar = state.mazarat[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _NearbyMazarCard(mazar: mazar),
            );
          },
          childCount: state.mazarat.length,
        ),
      ),
    );
  }
}

/// الرأسية الترحيبية العلوية، بخلفية كحلي فخمة وتحيّة ذكية تتغيّر حسب الوقت.
class _WelcomeHeader extends StatelessWidget {
  final String greeting;

  const _WelcomeHeader({required this.greeting});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [AppColors.navy, AppColors.navyLight],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primaryLight, width: 1.2),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.primaryLight,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.appName,
                style: const TextStyle(
                  color: AppColors.textOnDark,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '$greeting،',
            style: const TextStyle(
              color: AppColors.primaryLight,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'أهلاً بك في رحلتك المباركة',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 23,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة فخمة تمثّل مساحة الخريطة التفاعلية، تعمل حالياً كـ Placeholder
/// بمظهر خريطة مبسّط (شبكة خطوط رفيعة) وتفتح شاشة الخريطة الفعلية عند الضغط.
class _MapPlaceholderCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MapPlaceholderCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 172,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppColors.surface,
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Positioned.fill(child: CustomPaint(painter: _MapGridPainter())),
                Positioned(
                  right: 18,
                  top: 18,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_rounded, color: AppColors.primaryLight, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'الخريطة التفاعلية',
                          style: TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 18,
                  bottom: 18,
                  right: 18,
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.location_on_rounded, color: AppColors.white),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'استكشف المزارات على الخريطة',
                              style: TextStyle(
                                color: AppColors.navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'اضغط لفتح خرائط قوقل التفاعلية',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// يرسم شبكة خطوط رفيعة جداً تحاكي مظهر الخريطة بشكل تجريدي وأنيق،
/// كخلفية لبطاقة الخريطة التفاعلية الفاخرة (Placeholder).
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.navy.withOpacity(0.05)
      ..strokeWidth = 1;

    const step = 24.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// بطاقة عرض معلم واحد ضمن قائمة "المزارات التفاعلية المجاورة"، بزوايا
/// دائرية بسيطة ونظيفة. الضغط على البطاقة بأكملها يفتح شاشة تفاصيل المزار
/// الكاملة (MazarDetailScreen) حيث تتم عملية التفعيل الفعلية عبر الخادم.
/// تظهر شارة "التجربة التفاعلية متاحة الآن" فقط عندما يكون الحقل
/// is_interactive_available القادم من الخادم مساوياً true، أي عندما يكون
/// المستخدم فعلياً ضمن نطاق 100 متر من ذلك المعلم وقت جلب القائمة.
class _NearbyMazarCard extends StatelessWidget {
  final MazarEntity mazar;

  const _NearbyMazarCard({required this.mazar});

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
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => context.pushNamed('mazaratDetail', extra: mazar),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.divider),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
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
                        const SizedBox(height: 2),
                        Text(
                          mazar.city,
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (_formattedDistance.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text(
                        _formattedDistance,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.olive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                mazar.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (mazar.isInteractiveAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: AppColors.primaryDark),
                          SizedBox(width: 4),
                          Text(
                            'التجربة التفاعلية متاحة الآن',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Spacer(),
                  const Text(
                    'عرض التفاصيل',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.navy,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_back_ios_new_rounded, size: 11, color: AppColors.navy),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// حالة الخطأ التي تظهر عند فشل جلب مزارات التطبيق القريبة من الخادم، مع زر
/// لإعادة المحاولة مباشرة دون الحاجة لإعادة فتح التطبيق.
class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.textSecondary, size: 34),
        const SizedBox(height: 10),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
        const SizedBox(height: 14),
        OutlinedButton(
          onPressed: onRetry,
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.navy,
            side: const BorderSide(color: AppColors.divider),
          ),
          child: const Text('إعادة المحاولة'),
        ),
      ],
    );
  }
}
