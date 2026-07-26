"""
مزار (Mazar) - Backend API
==========================
نقطة الدخول الرئيسية لخادم تطبيق مزار، مبني باستخدام FastAPI ومُعدّ للعمل
مباشرة على منصة Replit. يهيئ هذا الملف تطبيق FastAPI، يفعّل إعدادات CORS
للسماح لتطبيق فلاتر (ويب، أندرويد، iOS) بالاتصال بالخادم دون قيود أثناء
التطوير، ويربط جميع المسارات الفرعية (Routers) الخاصة بميزات التطبيق:
المخطط الذكي (/planner)، المزارات التفاعلية (/mazarat)، وتوقع الازدحام
(/crowd). كما يوفر رسالة ترحيبية واضحة في المسار الرئيسي "/".
"""

import uvicorn
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.routers import crowd, mazarat, planner


def create_app() -> FastAPI:
    """ينشئ ويهيّئ نسخة تطبيق FastAPI الخاصة بمشروع مزار."""

    application = FastAPI(
        title=settings.APP_NAME,
        description=(
            "الواجهة البرمجية الخلفية لتطبيق مزار - السياحة الدينية الذكية، "
            "على خُطى الحبيب صلى الله عليه وسلم"
        ),
        version=settings.APP_VERSION,
        contact={
            "name": "فريق مزار",
            "email": "support@mazar.app",
        },
    )

    # -----------------------------------------------------------------
    # إعداد CORS (Cross-Origin Resource Sharing)
    # -----------------------------------------------------------------
    # يسمح هذا الإعداد لتطبيق فلاتر (سواء كان يعمل كتطبيق ويب، أندرويد،
    # أو iOS) بالاتصال بالخادم من أي مصدر (Origin) دون أن يرفض المتصفح
    # أو بيئة التشغيل الطلب. يُفضّل تقييد allow_origins إلى نطاقات محددة
    # وموثوقة فقط عند نشر التطبيق فعلياً للمستخدمين النهائيين، وذلك عبر
    # تعديل متغير البيئة ALLOWED_ORIGINS في ملف .env بدلاً من "*".
    # -----------------------------------------------------------------
    application.add_middleware(
        CORSMiddleware,
        allow_origins=settings.ALLOWED_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # -----------------------------------------------------------------
    # ربط جميع المسارات الفرعية (Routers) الخاصة بميزات التطبيق
    # -----------------------------------------------------------------
    application.include_router(planner.router)
    application.include_router(mazarat.router)
    application.include_router(crowd.router)

    return application


app = create_app()


@app.get("/", tags=["عام"])
async def root():
    """
    رسالة ترحيبية أساسية في المسار الرئيسي "/"، تؤكد أن خادم مزار يعمل
    بنجاح، وتعرض معلومات سريعة عن حالة الخادم والمسارات المتاحة، لتسهيل
    التحقق السريع من نجاح النشر على Replit.
    """
    return {
        "message": "مرحباً بك في خادم مزار - على خُطى الحبيب صلى الله عليه وسلم",
        "app": settings.APP_NAME,
        "status": "running",
        "version": settings.APP_VERSION,
        "docs_url": "/docs",
        "available_routes": {
            "planner": "/planner",
            "mazarat": "/mazarat",
            "crowd": "/crowd",
        },
    }


@app.get("/health", tags=["عام"])
async def health_check():
    """نقطة فحص صحة الخادم (Health Check) العامة، تُستخدم من قبل Replit وأدوات المراقبة."""
    return {"status": "ok"}


if __name__ == "__main__":
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=True,
    )
