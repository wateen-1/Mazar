import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_strings.dart';
import '../providers/crowd_provider.dart';
import '../widgets/crowd_indicator.dart';

/// شاشة توقع الازدحام، تتيح للمستخدم الاستعلام عن مستوى الازدحام المتوقع
/// في مكان معيّن لمساعدته على اختيار الوقت الأنسب لزيارته.
class CrowdScreen extends ConsumerWidget {
  const CrowdScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(crowdNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.crowdTitle)),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(AppStrings.crowdSubtitle),
            const SizedBox(height: 20),
            if (state.isLoading) const CircularProgressIndicator(),
            if (state.prediction != null) CrowdIndicator(prediction: state.prediction!),
            const Spacer(),
            ElevatedButton(
              onPressed: () =>
                  ref.read(crowdNotifierProvider.notifier).predict('default_location'),
              child: const Text('تحقق من الازدحام الآن'),
            ),
          ],
        ),
      ),
    );
  }
}
