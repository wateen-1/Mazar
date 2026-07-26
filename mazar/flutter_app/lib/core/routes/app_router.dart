import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../features/planner/presentation/screens/planner_screen.dart';
import '../../features/mazarat/presentation/screens/mazarat_map_screen.dart';
import '../../features/mazarat/presentation/screens/mazar_detail_screen.dart';
import '../../features/mazarat/domain/entities/mazar_entity.dart';
import '../../features/crowd/presentation/screens/crowd_screen.dart';
import '../constants/app_colors.dart';

/// يجمع نظام التنقل الكامل لتطبيق مزار باستخدام حزمة go_router.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String home = '/home';
  static const String planner = '/planner';
  static const String mazarat = '/mazarat';
  static const String mazaratDetail = '/mazarat/detail';
  static const String crowd = '/crowd';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: planner,
        name: 'planner',
        builder: (context, state) => const PlannerScreen(),
      ),
      GoRoute(
        path: mazarat,
        name: 'mazarat',
        builder: (context, state) => const MazaratMapScreen(),
      ),
      GoRoute(
        path: mazaratDetail,
        name: 'mazaratDetail',
        builder: (context, state) {
          final extra = state.extra;

          // تحقّق آمن من نوع الكائن الممرَّر عبر الوسيط extra قبل تحويله
          // (Casting) إلى MazarEntity، لتفادي أي خطأ أو انهيار في حال تم
          // فتح هذا المسار دون تمرير كائن مزار صحيح (مثلاً عبر رابط خارجي
          // أو استعادة حالة تنقل قديمة لا تحمل بيانات المزار).
          if (extra is MazarEntity) {
            return MazarDetailScreen(mazar: extra);
          }

          return const _InvalidMazarRouteScreen();
        },
      ),
      GoRoute(
        path: crowd,
        name: 'crowd',
        builder: (context, state) => const CrowdScreen(),
      ),
    ],
  );
}

/// شاشة احتياطية تُعرض في حال محاولة فتح مسار تفاصيل المزار (mazaratDetail)
/// دون تمرير كائن MazarEntity صحيح عبر الوسيط extra، بدلاً من السماح
/// بحدوث خطأ في التحويل (Casting Exception) يوقف التطبيق بالكامل.
class _InvalidMazarRouteScreen extends StatelessWidget {
  const _InvalidMazarRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.textSecondary, size: 40),
              const SizedBox(height: 12),
              const Text(
                'تعذّر عرض تفاصيل هذا المزار، يرجى العودة والمحاولة مجدداً',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.divider),
                ),
                child: const Text('العودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
