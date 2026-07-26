import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/mazar_entity.dart';
import '../../domain/usecases/activate_mazar_usecase.dart';
import '../providers/mazarat_provider.dart';

/// شاشة تفاصيل المزار الفاخرة، تُفتح عند الضغط على أي بطاقة مزار في
/// الشاشة الرئيسية، وتستقبل كائن MazarEntity كاملاً عبر معامل الودجت.
///
/// تتكون من ثلاثة أجزاء:
///   1. رأسية بصرية فخمة (Hero) تمثّل "صورة تعبيرية" للمعلم برسم برمجي
///      متسق مع هوية التطبيق (بلا حاجة لأصول صور خارجية بعد).
///   2. بطاقة تفاصيل تعرض الاسم والمدينة والوصف الثقافي العميق بخطوط
///      مريحة وتنسيق فخم مستوحى بالكامل من app_colors.dart.
///   3. شريط سفلي ثابت يحتوي زر تفعيل التجربة التفاعلية الفعلي (يستدعي
///      POST /mazarat/{mazar_id}/activate عبر Provider مخصص)، أو تنويهاً
///      هادئاً في حال كان المعلم غير متاح للتفعيل من الموقع الحالي.
class MazarDetailScreen extends ConsumerStatefulWidget {
  final MazarEntity mazar;

  const MazarDetailScreen({super.key, required this.mazar});

  @override
  ConsumerState<MazarDetailScreen> createState() => _MazarDetailScreenState();
}

class _MazarDetailScreenState extends ConsumerState<MazarDetailScreen> {
  bool _isActivating = false;

  /// يُنفَّذ عند الضغط على زر "تفعيل التجربة التفاعلية في الموقع".
  ///
  /// الخطوات: (1) تحديد موقع المستخدم الحالي فعلياً عبر GPS في هذه اللحظة
  /// بالذات (وليس الاعتماد على المسافة القديمة القادمة من قائمة الشاشة
  /// الرئيسية، لأن المستخدم قد يكون تحرك)، (2) استدعاء POST
  /// /mazarat/{mazar_id}/activate عبر ActivateMazarUseCase، (3) في حال
  /// النجاح فتح رابط التجربة التفاعلية، وفي حال الفشل بسبب الموقع (403)
  /// عرض ورقة سفلية توضيحية لبقة، أو رسالة خطأ عامة لأي فشل آخر.
  Future<void> _handleActivation() async {
    setState(() => _isActivating = true);

    double latitude;
    double longitude;

    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('تم رفض صلاحية الوصول إلى الموقع الجغرافي');
      }

      final position = await Geolocator.getCurrentPosition();
      latitude = position.latitude;
      longitude = position.longitude;
    } catch (_) {
      if (!mounted) return;
      setState(() => _isActivating = false);
      _showSnackBar(
        'تعذر تحديد موقعك الحالي، تأكد من تفعيل خدمة الموقع ومنح الإذن اللازم ثم حاول مجدداً',
        isError: true,
      );
      return;
    }

    final activateMazarUseCase = ref.read(activateMazarUseCaseProvider);
    final result = await activateMazarUseCase(
      ActivateMazarParams(
        mazarId: widget.mazar.id,
        latitude: latitude,
        longitude: longitude,
      ),
    );

    if (!mounted) return;
    setState(() => _isActivating = false);

    result.fold(
      (failure) {
        if (failure is LocationOutOfRangeFailure) {
          _showOutOfRangeSheet(failure.message);
        } else {
          _showSnackBar(failure.message, isError: true);
        }
      },
      (activatedMazar) => _handleActivationSuccess(activatedMazar),
    );
  }

  /// يعرض إشعاراً سريعاً (SnackBar) بألوان الهوية عند حدوث خطأ عام أو
  /// نجاح بسيط، دون الحاجة لواجهة معقدة.
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.navy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// يعرض ورقة سفلية (Bottom Sheet) فاخرة بألوان ذهبية/رمادية مطفأة، توضّح
  /// للمستخدم بلباقة أنه خارج النطاق الجغرافي المسموح به (100 متر)، وأنه
  /// ما زال بإمكانه استعراض الوصف الثقافي للمعلم في الوقت الحالي.
  void _showOutOfRangeSheet(String serverMessage) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(26, 20, 26, 34),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundSecondary,
                ),
                child: const Icon(
                  Icons.location_off_rounded,
                  color: AppColors.oliveDark,
                  size: 28,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'خارج النطاق الجغرافي المسموح به',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'عذراً، يجب أن تكون متواجداً في محيط المعلم (ضمن 100 متر) '
                'لتتمكن من تفعيل هذه التجربة الحية. يمكنك استعراض الوصف '
                'الثقافي حالياً.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: AppColors.textSecondary,
                  height: 1.8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                serverMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppColors.oliveDark),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('حسناً، فهمت', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// يُستدعى عند نجاح التفعيل من الخادم: يحاول فتح رابط التجربة التفاعلية
  /// الخاصة بالمعلم في متصفح خارجي، ثم يعرض في جميع الأحوال حواراً فاخراً
  /// يؤكد نجاح التفعيل، سواء نجح فتح الرابط فعلياً أم تعذّر ذلك.
  Future<void> _handleActivationSuccess(MazarEntity activatedMazar) async {
    bool linkOpened = false;

    try {
      final uri = Uri.parse(activatedMazar.interactiveExperienceUrl);
      linkOpened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      linkOpened = false;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => _ActivationSuccessDialog(
        mazar: activatedMazar,
        linkOpened: linkOpened,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mazar = widget.mazar;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _HeroHeader(mazar: mazar)),
              SliverToBoxAdapter(child: _DetailCard(mazar: mazar)),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: _RoundIconButton(
                    icon: const BackButtonIcon(),
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: mazar.isInteractiveAvailable
              ? _ActivationButton(isLoading: _isActivating, onPressed: _handleActivation)
              : const _UnavailableNotice(),
        ),
      ),
    );
  }
}

/// رأسية بصرية فخمة تمثّل "صورة تعبيرية" للمعلم، مبنية برمجياً بتدرّج
/// كحلي عميق ونمط نقطي خفيف وأيقونة كبيرة شفافة تلمّح لفئة المعلم، مع
/// شارة الفئة أعلى الرأسية وأيقونة دائرية بارزة تتوسط الحافة السفلية
/// وتتداخل مع بطاقة التفاصيل أسفلها لإحساس تصميمي متماسك وفاخر.
class _HeroHeader extends StatelessWidget {
  final MazarEntity mazar;

  const _HeroHeader({required this.mazar});

  IconData get _icon =>
      mazar.category == 'مسجد' ? Icons.mosque_rounded : Icons.terrain_rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 260,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navyDark, AppColors.navy, AppColors.navyLight],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -30,
                  top: -20,
                  child: Icon(
                    _icon,
                    size: 220,
                    color: AppColors.primaryLight.withOpacity(0.10),
                  ),
                ),
                Positioned.fill(child: CustomPaint(painter: _HeroPatternPainter())),
                Positioned(
                  top: 50,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      mazar.category,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.primary, width: 2.4),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withOpacity(0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(_icon, color: AppColors.primary, size: 40),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// يرسم نمطاً نقطياً خفيفاً للغاية على الرأسية الفخمة، لإضفاء نسيج بصري
/// هادئ دون أن يطغى على الأيقونة الكبيرة أو شارة الفئة.
class _HeroPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primaryLight.withOpacity(0.06);
    const step = 26.0;

    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.4, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// بطاقة تفاصيل المزار: الاسم، المدينة، المسافة (إن وُجدت)، فاصل ذهبي
/// رفيع، ثم الوصف الثقافي العميق للمعلم بخطوط مريحة ومتباعدة الأسطر.
class _DetailCard extends StatelessWidget {
  final MazarEntity mazar;

  const _DetailCard({required this.mazar});

  String get _formattedDistance {
    final meters = mazar.distanceInMeters;
    if (meters == null) return '';
    if (meters < 1000) {
      return '${meters.round()} م';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -28),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.fromLTRB(22, 44, 22, 26),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.navy.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              mazar.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on_rounded, size: 15, color: AppColors.olive),
                const SizedBox(width: 4),
                Text(
                  mazar.city,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (_formattedDistance.isNotEmpty) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.divider,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'يبعد $_formattedDistance',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.olive,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 20),
            Container(width: 46, height: 1.4, color: AppColors.primary.withOpacity(0.5)),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'نبذة ثقافية',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              mazar.description,
              textAlign: TextAlign.justify,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.9),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر دائري صغير شفاف يُستخدم لزر الرجوع أعلى شاشة التفاصيل، فوق الرأسية
/// الفخمة مباشرة، بلون كحلي شبه شفاف حتى يظل مقروءاً فوق أي محتوى خلفه.
class _RoundIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy.withOpacity(0.55),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: IconTheme(
            data: const IconThemeData(color: AppColors.white, size: 18),
            child: Center(child: icon),
          ),
        ),
      ),
    );
  }
}

/// زر التفعيل الرئيسي بتدرّج كحلي/ذهبي فخم، يظهر فقط عندما يكون الحقل
/// isInteractiveAvailable القادم من الخادم مساوياً true. يعرض مؤشر تحميل
/// هادئاً أثناء انتظار استجابة الخادم لمنع الضغط المتكرر.
class _ActivationButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _ActivationButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: isLoading ? null : onPressed,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [AppColors.navy, AppColors.navyLight, AppColors.primary],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.navy.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                  ),
                )
              : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.location_on_rounded, color: AppColors.primaryLight, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'تفعيل التجربة التفاعلية في الموقع',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// تنويه هادئ يظهر بدلاً من زر التفعيل عندما يكون isInteractiveAvailable
/// مساوياً false، بلون بيج/زيتي مطفأ ينسجم مع هوية التطبيق دون أن يبدو
/// كرسالة خطأ صارمة.
class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: const Row(
        children: [
          Icon(Icons.location_searching_rounded, color: AppColors.olive, size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'التجربة التفاعلية غير متاحة من موقعك الحالي. اقترب حتى 100 '
              'متر من المعلم لتفعيلها، ويمكنك استعراض الوصف الثقافي أعلاه '
              'في هذه الأثناء.',
              style: TextStyle(fontSize: 12.5, color: AppColors.oliveDark, height: 1.6),
            ),
          ),
        ],
      ),
    );
  }
}

/// حوار نجاح فاخر يظهر بعد تفعيل التجربة التفاعلية بنجاح من الخادم، ويوضّح
/// للمستخدم ما إذا فُتح رابط التجربة فعلياً في متصفح خارجي أم لا.
class _ActivationSuccessDialog extends StatelessWidget {
  final MazarEntity mazar;
  final bool linkOpened;

  const _ActivationSuccessDialog({required this.mazar, required this.linkOpened});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [AppColors.navy, AppColors.primary]),
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.white, size: 32),
            ),
            const SizedBox(height: 18),
            const Text(
              'تم تفعيل التجربة التفاعلية',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              linkOpened
                  ? 'استمتع بتجربة "${mazar.name}" التفاعلية التي فُتحت الآن.'
                  : 'تم التفعيل بنجاح، لكن تعذّر فتح رابط التجربة تلقائياً. '
                      'يمكنك نسخ الرابط أدناه وفتحه لاحقاً.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                mazar.interactiveExperienceUrl,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.olive),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('حسناً', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
