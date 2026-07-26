import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../crowd/domain/entities/crowd_entity.dart';
import '../../../mazarat/domain/entities/mazar_entity.dart';
import '../../../mazarat/presentation/providers/mazarat_provider.dart';
import '../../domain/entities/planner_entity.dart';
import '../providers/planner_provider.dart';

/// شاشة مخطط الرحلة الذكي الكاملة.
///
/// تدير أربع حالات مرئية متمايزة عبر AnimatedSwitcher بحسب PlannerState
/// القادمة من plannerNotifierProvider:
///   1. نموذج الإدخال (_PlannerFormView): مدة الزيارة عبر Slider فاخر،
///      والاهتمام الثقافي عبر Chips ذهبية قابلة للتعدد، وزر التوليد.
///   2. حالة التحميل (_PlannerLoadingView): مؤشر انتظار فاخر بنبض هادئ.
///   3. حالة النجاح (_PlannerTimelineView): جدول زمني عمودي أنيق لكل
///      عنصر مُولَّد، مع مسافة كل معلم عن التالي، وإمكانية الضغط للانتقال
///      لشاشة تفاصيل المزار.
///   4. حالة الخطأ (_PlannerErrorView) أو النتيجة الفارغة
///      (_PlannerEmptyResultView): معالجة لبقة مع خيار إعادة المحاولة أو
///      تعديل الخيارات والعودة للنموذج.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key});

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  int _selectedDays = 3;
  final Set<String> _selectedCategories = {};

  /// يصبح true بعد أول محاولة توليد ناجحة (حتى لو أعادت قائمة فارغة)،
  /// لتمييز "لم يُطلب شيء بعد" عن "طُلب وعادت النتيجة فارغة".
  bool _hasSubmitted = false;

  /// يحتفظ بآخر طلب أُرسل، ليُعاد إرساله بنفس الخيارات عند الضغط على
  /// "إعادة المحاولة" من شاشة الخطأ دون الحاجة لإعادة بناء الطلب من جديد.
  PlannerRequestEntity? _lastRequest;

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  /// يبني طلب توليد الخطة من خيارات النموذج الحالية، محاولاً إرفاق
  /// إحداثيات موقع المستخدم الحالي (اختياري) ليرتّب الذكاء الاصطناعي
  /// الأماكن جغرافياً بدقة أكبر، دون أن يمنع غياب الموقع من إتمام الطلب.
  Future<void> _handleGeneratePlan() async {
    double? latitude;
    double? longitude;

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
      // نُكمل توليد الخطة دون إحداثيات الموقع الحالي في حال تعذّر الوصول إليه
    }

    final request = PlannerRequestEntity(
      // تاريخ بداية افتراضي: غداً؛ يمكن لاحقاً إضافة منتقي تاريخ مخصص
      // في النموذج دون الحاجة لتعديل بنية الطلب هذه.
      visitDate: DateTime.now().add(const Duration(days: 1)),
      numberOfDays: _selectedDays,
      preferredCategories: _selectedCategories.toList(),
      currentLatitude: latitude,
      currentLongitude: longitude,
    );

    _lastRequest = request;

    if (!mounted) return;
    setState(() => _hasSubmitted = true);

    await ref.read(plannerNotifierProvider.notifier).generatePlan(request);
  }

  /// يعيد إرسال آخر طلب مُسجَّل، يُستخدم من زر "إعادة المحاولة" في شاشة الخطأ.
  Future<void> _retryLastRequest() async {
    final request = _lastRequest;
    if (request == null) {
      await _handleGeneratePlan();
      return;
    }
    await ref.read(plannerNotifierProvider.notifier).generatePlan(request);
  }

  /// يعيد الشاشة إلى نموذج الإدخال الفارغ، من خلال تصفير حالة الموفّر
  /// وحالة الودجت المحلية معاً.
  void _resetToForm() {
    setState(() => _hasSubmitted = false);
    ref.read(plannerNotifierProvider.notifier).reset();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(plannerNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.plannerTitle),
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.white,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(PlannerState state) {
    if (state.isLoading) {
      return const _PlannerLoadingView(key: ValueKey('planner_loading'));
    }

    if (state.errorMessage != null) {
      return _PlannerErrorView(
        key: const ValueKey('planner_error'),
        message: state.errorMessage!,
        onRetry: _retryLastRequest,
        onEditOptions: _resetToForm,
      );
    }

    if (state.items.isNotEmpty) {
      return _PlannerTimelineView(
        key: const ValueKey('planner_timeline'),
        items: state.items,
        onStartOver: _resetToForm,
      );
    }

    if (_hasSubmitted) {
      return _PlannerEmptyResultView(
        key: const ValueKey('planner_empty'),
        onEditOptions: _resetToForm,
      );
    }

    return _PlannerFormView(
      key: const ValueKey('planner_form'),
      selectedDays: _selectedDays,
      onDaysChanged: (value) => setState(() => _selectedDays = value),
      selectedCategories: _selectedCategories,
      onToggleCategory: _toggleCategory,
      onSubmit: _handleGeneratePlan,
    );
  }
}

/// نموذج الإدخال: مدة الزيارة عبر Slider فاخر، والاهتمام الثقافي عبر
/// Chips ذهبية قابلة للاختيار المتعدد، وزر توليد الخطة بتدرج كحلي/ذهبي.
class _PlannerFormView extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;
  final Set<String> selectedCategories;
  final ValueChanged<String> onToggleCategory;
  final VoidCallback onSubmit;

  const _PlannerFormView({
    super.key,
    required this.selectedDays,
    required this.onDaysChanged,
    required this.selectedCategories,
    required this.onToggleCategory,
    required this.onSubmit,
  });

  static const List<String> _interestOptions = [
    'تاريخي',
    'أثري',
    'روحاني',
    'معماري',
    'ثقافي عام',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.backgroundSecondary,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.plannerTitle,
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: AppColors.navy),
                    ),
                    SizedBox(height: 2),
                    Text(
                      AppStrings.plannerSubtitle,
                      style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          const Text(
            'مدة الزيارة المتاحة',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            'حدد عدد أيام رحلتك ليُبنى الجدول الزمني الذكي على أساسها',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),
          _DurationSelector(selectedDays: selectedDays, onChanged: onDaysChanged),

          const SizedBox(height: 32),

          const Text(
            'نوع الاهتمام الثقافي',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
          ),
          const SizedBox(height: 4),
          const Text(
            'اختر واحداً أو أكثر ليخصص الذكاء الاصطناعي رحلتك (اختياري)',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _interestOptions.map((interest) {
              final isSelected = selectedCategories.contains(interest);
              return _InterestChip(
                label: interest,
                isSelected: isSelected,
                onTap: () => onToggleCategory(interest),
              );
            }).toList(),
          ),

          const SizedBox(height: 40),

          _GenerateButton(onPressed: onSubmit),
        ],
      ),
    );
  }
}

/// محدّد مدة الزيارة: قراءة رقمية كبيرة بلون ذهبي عميق، وSlider مخصّص
/// بألوان الهوية (مسار نشط ذهبي، مؤشر كحلي).
class _DurationSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onChanged;

  const _DurationSelector({required this.selectedDays, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$selectedDays',
                style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 8),
              Text(
                selectedDays == 1 ? 'يوم واحد' : 'أيام',
                style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.backgroundSecondary,
              thumbColor: AppColors.navy,
              overlayColor: AppColors.primary.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            ),
            child: Slider(
              value: selectedDays.toDouble(),
              min: 1,
              max: 14,
              divisions: 13,
              label: '$selectedDays',
              onChanged: (value) => onChanged(value.round()),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('يوم واحد', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                Text('14 يوماً', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// شريحة اختيار اهتمام ثقافي واحدة، بلون ذهبي مطفأ عند التحديد وحياد
/// بيج هادئ عند عدم التحديد، مع أيقونة صح صغيرة توضّح الحالة المختارة.
class _InterestChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _InterestChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.14) : AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.divider,
            width: isSelected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.primaryDark),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// زر توليد الخطة الرئيسي، بتدرج كحلي/ذهبي فخم مطابق لأزرار التفعيل في
/// شاشة تفاصيل المزار، للحفاظ على تناسق كامل للهوية عبر التطبيق.
class _GenerateButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _GenerateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          height: 56,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.centerLeft,
              colors: [AppColors.navy, AppColors.navyLight, AppColors.primary],
            ),
            boxShadow: [
              BoxShadow(color: AppColors.navy.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8)),
            ],
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primaryLight, size: 20),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'توليد الخطة الذكية بواسطة الذكاء الاصطناعي',
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 14),
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

/// شاشة انتظار فاخرة تظهر أثناء توليد الخطة، بأيقونة نابضة بهدوء ورسالة
/// "جارٍ نسج خطتك الإيمانية..." تعكس فكرة أن الذكاء الاصطناعي يرتّب
/// المسار بعناية، بدلاً من مؤشر تحميل عام لا يحمل أي طابع للهوية.
class _PlannerLoadingView extends StatefulWidget {
  const _PlannerLoadingView({super.key});

  @override
  State<_PlannerLoadingView> createState() => _PlannerLoadingViewState();
}

class _PlannerLoadingViewState extends State<_PlannerLoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.86, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _pulse,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.navy, AppColors.primary]),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 30, spreadRadius: 6),
                  ],
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppColors.white, size: 42),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'جارٍ نسج خطتك الإيمانية...',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 10),
            const Text(
              'يرتّب الذكاء الاصطناعي الآن أفضل مسار لزيارتك بحسب وقتك واهتماماتك',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 26),
            const SizedBox(
              width: 140,
              child: LinearProgressIndicator(
                color: AppColors.primary,
                backgroundColor: AppColors.backgroundSecondary,
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// شاشة خطأ لبقة تعرض رسالة الفشل (اتصال أو خادم) مع خياري إعادة
/// المحاولة بنفس الطلب، أو العودة لتعديل خيارات الرحلة من جديد.
class _PlannerErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onEditOptions;

  const _PlannerErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onEditOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.backgroundSecondary),
              child: const Icon(Icons.cloud_off_rounded, color: AppColors.oliveDark, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'تعذّر توليد الخطة الذكية',
              style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('إعادة المحاولة', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onEditOptions,
              child: const Text(
                'تعديل خيارات الرحلة',
                style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// حالة نجاح الطلب لكن بلا أي عناصر مُولَّدة (يحدث حالياً دائماً طالما
/// أن نقطة /planner على الخادم لا تزال مساراً مبدئياً يعيد قائمة فارغة)،
/// تُعرض بشكل مختلف تماماً عن رسالة الخطأ حتى لا تبدو كعطل فني.
class _PlannerEmptyResultView extends StatelessWidget {
  final VoidCallback onEditOptions;

  const _PlannerEmptyResultView({super.key, required this.onEditOptions});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.backgroundSecondary),
              child: const Icon(Icons.event_busy_rounded, color: AppColors.olive, size: 30),
            ),
            const SizedBox(height: 20),
            const Text(
              'لم نتمكن من توليد جدول بهذه الخيارات',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy),
            ),
            const SizedBox(height: 8),
            const Text(
              'حاول تغيير عدد أيام الزيارة أو نوع الاهتمام الثقافي، أو أعد المحاولة بعد قليل',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.6),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onEditOptions,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.navy,
                  side: const BorderSide(color: AppColors.divider),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('تعديل خيارات الرحلة', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// الجدول الزمني العمودي (Timeline) الذي يعرض الخطة المُولَّدة الكاملة.
///
/// يقسّم عناصر الخطة تلقائياً بحسب حقل dayNumber القادم من الخادم، ويضع
/// فاصلاً أنيقاً بين كل مجموعة يوم والتي تليها ("اليوم الأول"، "اليوم
/// الثاني"...). يربط بين بطاقات المعالم المتتالية ضمن اليوم نفسه بخط
/// منقّط (Dotted Line) ذهبي، مع شارة المسافة الفعلية بينهما القادمة
/// مباشرة من حقل distance_to_next_meters الذي يحسبه الخادم بصيغة
/// Haversine — لا يُرسم أي خط أو مسافة عبر حدود يوم إلى آخر، لأن فاصل
/// اليوم نفسه يكسر التسلسل البصري هناك بشكل مقصود.
class _PlannerTimelineView extends ConsumerWidget {
  final List<PlannerItemEntity> items;
  final VoidCallback onStartOver;

  const _PlannerTimelineView({super.key, required this.items, required this.onStartOver});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final knownMazarat = ref.watch(mazaratNotifierProvider).mazarat;
    final rows = _buildTimelineRows(context, ref, knownMazarat);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'جدولك الزمني المقترح',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.navy),
                ),
              ),
              TextButton.icon(
                onPressed: onStartOver,
                icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.olive),
                label: const Text(
                  'خطة جديدة',
                  style: TextStyle(color: AppColors.olive, fontWeight: FontWeight.w600, fontSize: 12.5),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: rows,
          ),
        ),
      ],
    );
  }

  /// يبني قائمة الودجات الكاملة للجدول الزمني دفعة واحدة: فاصل يوم عند
  /// كل تغيّر في dayNumber، وعقدة زمنية لكل معلم، مع تفعيل الخط المنقّط
  /// ومسافة "المعلم التالي" فقط بين معلمين يقعان ضمن اليوم نفسه.
  List<Widget> _buildTimelineRows(
    BuildContext context,
    WidgetRef ref,
    List<MazarEntity> knownMazarat,
  ) {
    final rows = <Widget>[];
    int? currentDay;
    int indexInDay = 0;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.dayNumber != currentDay) {
        currentDay = item.dayNumber;
        indexInDay = 0;
        rows.add(_DaySeparator(dayNumber: currentDay));
      }

      indexInDay++;

      final nextItem = i < items.length - 1 ? items[i + 1] : null;
      final isLastInDay = nextItem == null || nextItem.dayNumber != item.dayNumber;

      rows.add(
        _TimelineNode(
          item: item,
          indexInDay: indexInDay,
          showConnector: !isLastInDay,
          onTap: () {
            final mazar = _resolveMazarEntity(item, knownMazarat);
            context.pushNamed('mazaratDetail', extra: mazar);
          },
        ),
      );
    }

    return rows;
  }

  /// يحاول العثور على بيانات المزار الكاملة (MazarEntity) من قائمة
  /// المزارات المعروفة مسبقاً (إن كانت محمَّلة من الشاشة الرئيسية أو
  /// الخريطة في هذه الجلسة)، وإلا يبني كائناً مبسطاً من بيانات عنصر
  /// الجدول الزمني نفسه، حتى تبقى ميزة "الضغط للانتقال للتفاصيل" تعمل
  /// دائماً حتى قبل زيارة الشاشة الرئيسية أو الخريطة.
  static MazarEntity _resolveMazarEntity(PlannerItemEntity item, List<MazarEntity> knownMazarat) {
    for (final mazar in knownMazarat) {
      if (mazar.id == item.id) return mazar;
    }

    return MazarEntity(
      id: item.id,
      name: item.title,
      city: item.locationName ?? '',
      description: item.description,
      latitude: item.latitude ?? 0,
      longitude: item.longitude ?? 0,
      category: item.title.contains('مسجد') ? 'مسجد' : 'معلم تاريخي',
      interactiveExperienceUrl: '',
      distanceInMeters: null,
      isInteractiveAvailable: false,
    );
  }
}

/// شريط فاصل أنيق يُعرض بين مجموعات أيام الخطة، على هيئة شريحة كحلية
/// متدرجة تحمل اسم اليوم ("اليوم الأول"، "اليوم الثاني"...) يتبعها خط
/// أفقي رفيع يمتد حتى نهاية السطر.
class _DaySeparator extends StatelessWidget {
  final int dayNumber;

  const _DaySeparator({required this.dayNumber});

  static const List<String> _arabicOrdinals = [
    'الأول',
    'الثاني',
    'الثالث',
    'الرابع',
    'الخامس',
    'السادس',
    'السابع',
    'الثامن',
    'التاسع',
    'العاشر',
    'الحادي عشر',
    'الثاني عشر',
    'الثالث عشر',
    'الرابع عشر',
  ];

  String get _label {
    if (dayNumber >= 1 && dayNumber <= _arabicOrdinals.length) {
      return 'اليوم ${_arabicOrdinals[dayNumber - 1]}';
    }
    return 'اليوم رقم $dayNumber';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: dayNumber == 1 ? 0 : 22, bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.navy, AppColors.navyLight]),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(color: AppColors.navy.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.today_rounded, size: 13, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  _label,
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: Container(height: 1, color: AppColors.divider)),
        ],
      ),
    );
  }
}

/// شارة صغيرة ملوّنة تعكس حالة الازدحام المتوقعة لمعلم معيّن وقت زيارته
/// المقترحة، بثلاث حالات واضحة (وحالة رابعة محايدة عند غياب البيانات).
class _CrowdBadge extends StatelessWidget {
  final CrowdLevel crowdStatus;

  const _CrowdBadge({required this.crowdStatus});

  ({Color color, Color background, IconData icon, String label}) get _config {
    switch (crowdStatus) {
      case CrowdLevel.high:
        return (
          color: AppColors.crowdHigh,
          background: AppColors.crowdHigh.withOpacity(0.12),
          icon: Icons.warning_rounded,
          label: 'مزدحم جداً',
        );
      case CrowdLevel.medium:
        return (
          color: AppColors.crowdMedium,
          background: AppColors.crowdMedium.withOpacity(0.15),
          icon: Icons.access_time_filled_rounded,
          label: 'متوسط الازدحام',
        );
      case CrowdLevel.low:
        return (
          color: AppColors.crowdLow,
          background: AppColors.crowdLow.withOpacity(0.12),
          icon: Icons.spa_rounded,
          label: 'أوقات مثالية للزيارة',
        );
      case CrowdLevel.unknown:
        return (
          color: AppColors.textSecondary,
          background: AppColors.backgroundSecondary,
          icon: Icons.help_outline_rounded,
          label: 'حالة الازدحام غير معروفة',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _config;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: config.background, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: 11.5, color: config.color),
          const SizedBox(width: 5),
          Text(
            config.label,
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: config.color),
          ),
        ],
      ),
    );
  }
}

/// عقدة واحدة ضمن الجدول الزمني العمودي: دائرة مرقّمة (ترقيم يبدأ من جديد
/// مع كل يوم) بتدرج كحلي/ذهبي، بطاقة تفاصيل قابلة للضغط تحمل شارة وقت
/// الزيارة وشارة حالة الازدحام الملوّنة، خط منقّط ذهبي يربطها بالمعلم
/// التالي ضمن اليوم نفسه (إن وُجد)، ومسافة ذلك الرابط الفعلية القادمة من
/// الخادم.
class _TimelineNode extends StatelessWidget {
  final PlannerItemEntity item;
  final int indexInDay;
  final bool showConnector;
  final VoidCallback onTap;

  const _TimelineNode({
    required this.item,
    required this.indexInDay,
    required this.showConnector,
    required this.onTap,
  });

  String get _formattedDistance {
    final meters = item.distanceToNextMeters;
    if (meters == null) return '';
    if (meters < 1000) {
      return '${meters.round()} م';
    }
    return '${(meters / 1000).toStringAsFixed(1)} كم';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [AppColors.navy, AppColors.primary]),
                  boxShadow: [
                    BoxShadow(color: AppColors.navy.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$indexInDay',
                    style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              if (showConnector)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: SizedBox(
                      width: 2,
                      child: CustomPaint(painter: _DottedLinePainter()),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: showConnector ? 22 : 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: onTap,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.divider),
                          boxShadow: [
                            BoxShadow(color: AppColors.navy.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.backgroundSecondary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.access_time_rounded, size: 12, color: AppColors.olive),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormatter.formatTime(item.scheduledTime),
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.olive,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.arrow_back_ios_new_rounded, size: 12, color: AppColors.textSecondary),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _CrowdBadge(crowdStatus: item.crowdStatus),
                            const SizedBox(height: 10),
                            Text(
                              item.title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.navy),
                            ),
                            if (item.locationName != null && item.locationName!.isNotEmpty) ...[
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_rounded, size: 12, color: AppColors.olive),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.locationName!,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Text(
                              item.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (showConnector && _formattedDistance.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, right: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.route_rounded, size: 13, color: AppColors.primaryDark),
                          const SizedBox(width: 5),
                          Text(
                            'يبعد $_formattedDistance عن المعلم التالي',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// يرسم خطاً رأسياً منقّطاً (Dotted Line) بلون ذهبي، يربط بصرياً بين بطاقة
/// معلم وبطاقة المعلم التالي له مباشرة ضمن اليوم نفسه، لإبراز أن هناك
/// مسافة جغرافية فعلية محسوبة بينهما (القادمة من distance_to_next_meters).
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.55)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const gapHeight = 4.0;
    double y = 2;

    while (y < size.height) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, math.min(y + dashHeight, size.height)),
        paint,
      );
      y += dashHeight + gapHeight;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
