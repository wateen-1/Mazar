"""
إعدادات التطبيق العامة
=======================
يجمع هذا الملف جميع متغيرات الإعداد والبيئة الخاصة بخادم مزار في مكان واحد،
بحيث يسهل التعديل عليها لاحقاً دون الحاجة للبحث داخل الكود.
"""

import os
from typing import List


class Settings:
    """كائن إعدادات مركزي يُقرأ من متغيرات البيئة عند توفرها."""

    APP_NAME: str = "مزار - Mazar API"
    APP_VERSION: str = "0.1.0"

    # المنفذ الذي يعمل عليه الخادم؛ توفّر Replit هذه القيمة تلقائياً عبر PORT
    PORT: int = int(os.getenv("PORT", 8000))

    # قائمة المصادر المسموح لها بالاتصال بالـ API
    # يُفضّل تحديدها بدقة (مثال: رابط تطبيق الويب) عند النشر الفعلي بدلاً من "*"
    ALLOWED_ORIGINS: List[str] = [
        origin.strip()
        for origin in os.getenv("ALLOWED_ORIGINS", "*").split(",")
    ]

    # مفتاح Google Maps API، يُستخدم لاحقاً في التحقق من الإحداثيات أو حساب المسافات
    GOOGLE_MAPS_API_KEY: str = os.getenv("GOOGLE_MAPS_API_KEY", "")

    # مفتاح مزوّد الذكاء الاصطناعي المستخدم في توليد الجدول الذكي لنقطة /planner
    AI_PROVIDER_API_KEY: str = os.getenv("AI_PROVIDER_API_KEY", "")

    # رابط قاعدة البيانات، يُستخدم لاحقاً عند ربط تخزين دائم مثل PostgreSQL
    DATABASE_URL: str = os.getenv("DATABASE_URL", "")


settings = Settings()
