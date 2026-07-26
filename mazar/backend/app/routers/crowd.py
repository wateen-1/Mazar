"""
مسار /crowd - التنبؤ بالازدحام
================================
نقطة النهاية الخاصة بتوقع مستوى الازدحام في مكان معيّن ووقت معيّن،
لمساعدة المستخدم على اختيار الوقت الأنسب لزيارته.
"""

from datetime import datetime, timezone
from typing import Optional

from fastapi import APIRouter, Query

from app.models.schemas import CrowdPrediction

router = APIRouter(prefix="/crowd", tags=["توقع الازدحام"])


@router.get("", response_model=CrowdPrediction)
async def predict_crowd(
    location_id: str = Query(..., description="معرّف المكان المراد التنبؤ بازدحامه"),
    target_time: Optional[datetime] = Query(
        None, description="الوقت المستهدف للتنبؤ؛ يُستخدم الوقت الحالي إن لم يُحدد"
    ),
) -> CrowdPrediction:
    """
    يتنبأ بمستوى الازدحام في مكان معيّن عند وقت معيّن.

    TODO: ربط هذه النقطة بنموذج تعلم آلي مدرّب على بيانات الزيارات التاريخية
    والوقت والموسم (كرمضان أو موسم الحج) لتوليد توقع دقيق لمستوى الازدحام.
    """
    prediction_time = target_time or datetime.now(timezone.utc)

    # مسار مبدئي فارغ - تُعاد حالياً قيمة افتراضية غير معروفة ريثما يُطوَّر النموذج
    return CrowdPrediction(
        location_id=location_id,
        location_name="",
        level="unknown",
        confidence_score=0.0,
        predicted_for=prediction_time,
        recommendation=None,
    )


@router.get("/health", tags=["عام"])
async def crowd_health():
    """فحص سريع للتأكد من أن خدمة توقع الازدحام متاحة."""
    return {"status": "ok", "service": "crowd"}
