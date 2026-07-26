package com.mazar.app

import io.flutter.embedding.android.FlutterActivity

/**
 * النشاط الرئيسي لتطبيق مزار.
 *
 * يمتد هذا الصنف حصرياً من io.flutter.embedding.android.FlutterActivity
 * (Android v2 Embedding)، وليس من الصنف القديم المحذوف
 * io.flutter.app.FlutterActivity (v1) الذي يتسبب في فشل البناء برسالة
 * "Build failed due to use of deleted Android v1 embedding" عند استخدامه
 * أو عند استخدام أي مزيج غير مكتمل بينه وبين علامة flutterEmbedding=2 في
 * AndroidManifest.xml. عدم وجود أي كود إضافي هنا مقصود تماماً: كل منطق
 * التطبيق (الشاشات، الحالة، الشبكة...) مكتوب بالكامل بلغة Dart ضمن lib/،
 * وهذا النشاط لا يفعل أكثر من استضافة محرك Flutter داخل نافذة أندرويد.
 */
class MainActivity : FlutterActivity()
