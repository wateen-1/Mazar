"""
النماذج المشتركة (Schemas)
============================
تعريفات Pydantic لكل النماذج المستخدمة عبر نقاط النهاية المختلفة في خادم مزار.
فصل النماذج هنا يسهّل إعادة استخدامها بين أكثر من Router دون تكرار الكود.
"""

from datetime import datetime
from typing import List, Optional

from pydantic import BaseModel, Field


# ---------------------------------------------------------------------------
# نماذج /planner - مخطط الرحلة الذكي
# ---------------------------------------------------------------------------

class PlannerRequest(BaseModel):
    """بيانات الطلب المرسلة من التطبيق لتوليد جدول زيارة ذكي."""

    visit_date: datetime = Field(..., description="تاريخ بداية الزيارة")
    number_of_days: int = Field(..., ge=1, le=30, description="عدد أيام الزيارة")
    preferred_categories: List[str] = Field(
        default_factory=list,
        description="التصنيفات المفضلة لدى المستخدم مثل: مساجد، متاحف، مزارات تاريخية",
    )
    current_latitude: Optional[float] = Field(
        None, description="خط عرض موقع المستخدم الحالي"
    )
    current_longitude: Optional[float] = Field(
        None, description="خط طول موقع المستخدم الحالي"
    )


class PlannerItem(BaseModel):
    """
    عنصر واحد ضمن الجدول الزمني المُولَّد.

    الحقول الأربعة الأخيرة (day_number، distance_to_next_meters،
    crowd_status) أُضيفت مع تفعيل محرك التخطيط الذكي الفعلي، وهي جميعاً
    اختيارية (Optional) بقيمة افتراضية None، حتى تبقى الاستجابة متوافقة
    تماماً مع أي عميل قديم كان يقرأ فقط الحقول الأساسية الخمسة الأولى دون
    أن ينكسر عند إضافة هذه الحقول الجديدة.
    """

    id: str
    title: str
    description: str
    scheduled_time: datetime
    location_name: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

    day_number: Optional[int] = Field(
        None, description="رقم اليوم ضمن خطة الرحلة (1 يعني اليوم الأول من الزيارة)"
    )
    distance_to_next_meters: Optional[float] = Field(
        None,
        description="المسافة بالمتر بين هذا المعلم والمعلم الذي يليه مباشرة في "
        "ترتيب الخطة الكامل؛ تكون None إذا كان هذا آخر معلم في الخطة بأكملها",
    )
    crowd_status: Optional[str] = Field(
        None,
        description="تنبؤ تقريبي لحالة الازدحام في وقت الزيارة المقترح. "
        "القيم الممكنة: Low | Medium | High",
    )


class PlannerResponse(BaseModel):
    """استجابة نقطة النهاية /planner الكاملة."""

    items: List[PlannerItem] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# نماذج /mazarat - المزارات التفاعلية
# ---------------------------------------------------------------------------

class MazarItem(BaseModel):
    """يمثل مزاراً أو معلماً دينياً واحداً."""

    id: str
    name: str
    description: str
    latitude: float
    longitude: float
    category: str
    distance_in_meters: Optional[float] = None
    is_unlocked: bool = False


class NearbyMazaratResponse(BaseModel):
    """استجابة الاستعلام عن المزارات القريبة من موقع المستخدم."""

    mazarat: List[MazarItem] = Field(default_factory=list)


class ActivateMazarRequest(BaseModel):
    """بيانات طلب تفعيل مزار عند وصول المستخدم إليه فعلياً عبر GPS."""

    latitude: float = Field(..., description="خط عرض موقع المستخدم الحالي")
    longitude: float = Field(..., description="خط طول موقع المستخدم الحالي")


# ---------------------------------------------------------------------------
# نماذج /crowd - توقع الازدحام
# ---------------------------------------------------------------------------

class CrowdPrediction(BaseModel):
    """نتيجة توقع مستوى الازدحام لمكان معيّن في وقت معيّن."""

    location_id: str
    location_name: str
    level: str = Field(..., description="القيم الممكنة: low | medium | high | unknown")
    confidence_score: float = Field(..., ge=0, le=1)
    predicted_for: datetime
    recommendation: Optional[str] = None
