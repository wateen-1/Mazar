import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';

/// شاشة البداية (Splash Screen) لتطبيق مزار.
///
/// تصميم أنيق وهادئ، متعمّد الابتعاد عن الرمزية النمطية المكرَّرة
/// (الهلال والنجمة الذهبية المألوفة في كل تطبيق ديني)، ويستبدلها برمز
/// بصري خاص بهوية "مزار" نفسها: ثلاث نقاط ذهبية متصاعدة الحجم على مسار
/// قطري متقطّع، ترمز إلى "الخُطى" التي يقتفيها المستخدم واحدة تلو الأخرى
/// على درب الحبيب صلى الله عليه وسلم. تُحاط هذه العلامة بحلقة ذهبية
/// رفيعة للغاية (Hairline)، على خلفية متدرّجة بالكحلي الفخم الهادئ بدل
/// الألوان الصاخبة، مع زوايا زخرفية دقيقة أعلى وأسفل الشاشة أشبه ببطاقة
/// دعوة فاخرة، وحركات دخول هادئة بلا قفزات أو ارتداد.
///
/// تنتقل الشاشة تلقائياً إلى الشاشة الرئيسية (HomeScreen) بعد 3 ثوانٍ
/// بالضبط من لحظة ظهورها، عبر نظام التنقل go_router.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _markController;
  late final AnimationController _textController;
  late final AnimationController _loadingController;

  late final Animation<double> _markScale;
  late final Animation<double> _markOpacity;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _textOpacity;
  late final Animation<double> _loadingOpacity;

  @override
  void initState() {
    super.initState();

    _markController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _markScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _markController, curve: Curves.easeOutCubic),
    );

    _markOpacity = CurvedAnimation(
      parent: _markController,
      curve: Curves.easeIn,
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));

    _textOpacity = CurvedAnimation(
      parent: _textController,
      curve: Curves.easeIn,
    );

    _loadingOpacity = CurvedAnimation(
      parent: _loadingController,
      curve: Curves.easeIn,
    );

    _startSequence();
  }

  /// يشغّل تسلسل الحركة الهادئ: العلامة، ثم النص، ثم مؤشر التحميل، وينتقل
  /// تلقائياً إلى الشاشة الرئيسية بعد مرور 3 ثوانٍ بالضبط من بداية الشاشة.
  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 100));
    if (!mounted) return;
    _markController.forward();

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _textController.forward();
    _loadingController.forward();

    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    // الانتقال التلقائي إلى الشاشة الرئيسية HomeScreen بعد 3 ثوانٍ من الظهور
    context.goNamed('home');
  }

  @override
  void dispose() {
    _markController.dispose();
    _textController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // الخلفية المتدرجة بالكحلي الفخم الهادئ
            Container(
              decoration: const BoxDecoration(gradient: AppColors.splashGradient),
            ),

            // توهّج مركزي خفيف جداً خلف العلامة، لإضفاء عمق دون صخب
            Align(
              alignment: const Alignment(0, -0.15),
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.10),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // زوايا زخرفية رفيعة أعلى وأسفل الشاشة، بأسلوب بطاقات الدعوة الفاخرة
            Positioned.fill(
              child: CustomPaint(painter: _CornerFramePainter()),
            ),

            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // العلامة البصرية الخاصة بمزار (نقاط متصاعدة على مسار متقطّع)
                  ScaleTransition(
                    scale: _markScale,
                    child: FadeTransition(
                      opacity: _markOpacity,
                      child: const _MazarMark(),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // اسم التطبيق
                  FadeTransition(
                    opacity: _markOpacity,
                    child: Text(
                      AppStrings.appName,
                      style: GoogleFonts.amiri(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // خط فاصل ذهبي رفيع جداً (Hairline)
                  FadeTransition(
                    opacity: _markOpacity,
                    child: Container(
                      width: 64,
                      height: 1,
                      color: AppColors.primaryLight.withOpacity(0.6),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // الشعار التعريفي: "على خُطى الحبيب صلى الله عليه وسلم"
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textOpacity,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 44),
                        child: Text(
                          AppStrings.appSlogan,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cairo(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryLight,
                            letterSpacing: 0.6,
                            height: 1.7,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // مؤشر تحميل هادئ ورفيع، مع رسالة انتظار مكتومة اللون
                  FadeTransition(
                    opacity: _loadingOpacity,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryLight.withOpacity(0.85),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.loading,
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            color: AppColors.textOnDark.withOpacity(0.65),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 44),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// العلامة البصرية الخاصة بتطبيق مزار: حلقة ذهبية رفيعة للغاية تحتضن ثلاث
/// نقاط ذهبية متصاعدة الحجم على مسار قطري متقطّع، ترمز إلى رحلة الزائر
/// نحو المزار خطوة تلو الأخرى على الدرب. اختيار مقصود لتفادي الرمزية
/// النمطية المكررة (الهلال والنجمة) التي تتشابه في كل تطبيق ديني تقريباً.
class _MazarMark extends StatelessWidget {
  const _MazarMark();

  @override
  Widget build(BuildContext context) {
    // ملاحظة: لا يجوز وضع const هنا لأن _StepsMarkPainter لا يملك مُنشئاً
    // ثابتاً (const constructor) صريحاً، وأي محاولة لتمييز شجرة الودجات هذه
    // بالكامل كـ const (بما فيها CustomPaint(painter: _StepsMarkPainter()))
    // كانت تتسبب في خطأ تجميع: "الثابت (const) يعتمد على مُنشئ غير ثابت".
    return SizedBox(
      width: 132,
      height: 132,
      child: CustomPaint(painter: _StepsMarkPainter()),
    );
  }
}

class _StepsMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final ringPaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width / 2 - 1.5, ringPaint);

    // حلقة داخلية أدق كإطار زخرفي إضافي هادئ
    final innerRingPaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, size.width / 2 - 14, innerRingPaint);

    // المسار المتقطّع الذي تسير عليه النقاط الثلاث الرمزية للخُطى
    final trailPaint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final p1 = Offset(size.width * 0.32, size.height * 0.66);
    final p2 = Offset(size.width * 0.50, size.height * 0.50);
    final p3 = Offset(size.width * 0.70, size.height * 0.33);

    final trailPath = Path()
      ..moveTo(p1.dx, p1.dy)
      ..lineTo(p2.dx, p2.dy)
      ..lineTo(p3.dx, p3.dy);

    canvas.drawPath(
      _dashPath(trailPath, dashLength: 4, gapLength: 4),
      trailPaint,
    );

    // ثلاث نقاط ذهبية متصاعدة الحجم، ترمز إلى الخُطى المتقدّمة على الدرب
    final dotPaint = Paint()
      ..color = AppColors.primaryLight
      ..style = PaintingStyle.fill;

    canvas.drawCircle(p1, 3.0, dotPaint);
    canvas.drawCircle(p2, 4.3, dotPaint);
    canvas.drawCircle(p3, 5.8, dotPaint);
  }

  /// يحوّل مساراً متصلاً إلى مسار متقطّع (Dashed) بطول شرطة وفجوة محددين،
  /// لعدم توفر خاصية جاهزة لذلك في Flutter الأساسي.
  Path _dashPath(Path source, {required double dashLength, required double gapLength}) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final segmentLength = draw ? dashLength : gapLength;
        final nextDistance = math.min(distance + segmentLength, metric.length);
        if (draw) {
          dashedPath.addPath(metric.extractPath(distance, nextDistance), Offset.zero);
        }
        distance = nextDistance;
        draw = !draw;
      }
    }
    return dashedPath;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// يرسم زوايا زخرفية رفيعة للغاية (Hairline Corner Brackets) في الزاوية
/// العلوية والزاوية السفلية المقابلة لها فقط، بأسلوب بطاقات الدعوة
/// والمطبوعات الفاخرة، كلمسة تصميم هادئة وغير مبتذلة بديلة عن الأنماط
/// الهندسية الإسلامية المتكررة الشائعة في شاشات البداية.
class _CornerFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryLight.withOpacity(0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const margin = 28.0;
    const armLength = 22.0;

    _drawCorner(
      canvas,
      Offset(size.width - margin, margin),
      paint,
      armLength,
      pointsDown: true,
      pointsLeft: true,
    );

    _drawCorner(
      canvas,
      Offset(margin, size.height - margin),
      paint,
      armLength,
      pointsDown: false,
      pointsLeft: false,
    );
  }

  void _drawCorner(
    Canvas canvas,
    Offset corner,
    Paint paint,
    double armLength, {
    required bool pointsDown,
    required bool pointsLeft,
  }) {
    final horizontalEnd = Offset(
      corner.dx + (pointsLeft ? -armLength : armLength),
      corner.dy,
    );
    final verticalEnd = Offset(
      corner.dx,
      corner.dy + (pointsDown ? armLength : -armLength),
    );

    canvas.drawLine(corner, horizontalEnd, paint);
    canvas.drawLine(corner, verticalEnd, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
