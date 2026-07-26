import 'package:flutter_riverpod/flutter_riverpod.dart';

/// حالة عامة للتطبيق: هل أنهى المستخدم شاشات التعريف (Onboarding) من قبل.
final onboardingCompletedProvider = StateProvider<bool>((ref) => false);

/// موفر بسيط لتتبّع تبويب التنقل السفلي النشط حالياً في الشاشة الرئيسية.
final currentTabIndexProvider = StateProvider<int>((ref) => 0);
