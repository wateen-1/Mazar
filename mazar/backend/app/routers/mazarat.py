"""
مسار /mazarat - المزارات التفاعلية
=======================================
نقاط النهاية الخاصة بجلب مزارات التطبيق (المعالم الدينية والتاريخية في مكة
المكرمة والمدينة المنورة)، بناءً على إحداثيات المستخدم الحالية (Latitude,
Longitude) القادمة من تطبيق فلاتر عبر خرائط قوقل.

يحتوي هذا الملف حالياً على قاعدة بيانات ثابتة (Mock Data) لخمسة معالم
رئيسية، ريثما يتم ربطه لاحقاً بقاعدة بيانات فعلية. لكل معلم إحداثيات
جغرافية دقيقة، ووصف ثقافي فخم، ورابط تخيلي لتجربة "المزارات التفاعلية"
الخاصة به.

المنطق الأساسي: عند استقبال موقع المستخدم، يُحسب بُعد المسافة الفعلية
بينه وبين كل معلم باستخدام صيغة Haversine، وإذا كانت هذه المسافة أقل من
أو تساوي 100 متر، يُفعَّل الحقل is_interactive_available بالقيمة true
للسماح للتطبيق بعرض التجربة التفاعلية الخاصة بذلك المعلم.
"""

import math
from typing import List, Optional

from fastapi import APIRouter, HTTPException, Query
from pydantic import BaseModel, Field

router = APIRouter(prefix="/mazarat", tags=["المزارات التفاعلية"])


# ---------------------------------------------------------------------------
# النماذج (Schemas) الخاصة بمزارات التطبيق
# ---------------------------------------------------------------------------

class MazarItem(BaseModel):
    """يمثل معلماً دينياً أو تاريخياً واحداً ضمن مزارات التطبيق."""

    id: str = Field(..., description="معرّف فريد للمعلم")
    name: str = Field(..., description="اسم المعلم")
    city: str = Field(..., description="المدينة التي يقع فيها المعلم")
    description: str = Field(..., description="وصف ثقافي وتاريخي فخم للمعلم")
    latitude: float = Field(..., description="خط عرض المعلم الجغرافي الدقيق")
    longitude: float = Field(..., description="خط طول المعلم الجغرافي الدقيق")
    category: str = Field(..., description="تصنيف المعلم، مثال: مسجد أو معلم تاريخي")
    interactive_experience_url: str = Field(
        ..., description="رابط تجربة المزارات التفاعلية الخاصة بهذا المعلم"
    )
    distance_in_meters: Optional[float] = Field(
        None, description="المسافة الفعلية بالمتر بين موقع المستخدم وهذا المعلم"
    )
    is_interactive_available: bool = Field(
        False,
        description="يصبح true عندما يكون المستخدم على بعد 100 متر أو أقل من المعلم",
    )


class NearbyMazaratResponse(BaseModel):
    """استجابة الاستعلام عن مزارات التطبيق القريبة من موقع المستخدم الحالي."""

    user_latitude: float = Field(..., description="خط عرض موقع المستخدم المُرسَل")
    user_longitude: float = Field(..., description="خط طول موقع المستخدم المُرسَل")
    total_results: int = Field(..., description="عدد المزارات المُعادة في الاستجابة")
    mazarat: List[MazarItem] = Field(default_factory=list)


class ActivateMazarRequest(BaseModel):
    """بيانات طلب تفعيل التجربة التفاعلية لمعلم معيّن عند وصول المستخدم إليه."""

    latitude: float = Field(..., description="خط عرض موقع المستخدم الحالي")
    longitude: float = Field(..., description="خط طول موقع المستخدم الحالي")


# ---------------------------------------------------------------------------
# قاعدة البيانات الثابتة (Mock Data) لمزارات التطبيق الرئيسية
# ---------------------------------------------------------------------------
# ملاحظة: الإحداثيات أدناه دقيقة وحقيقية لكل معلم، بينما رابط التجربة
# التفاعلية (interactive_experience_url) هو رابط تخيلي مؤقت سيُستبدل
# لاحقاً بالرابط الفعلي عند تطوير تجربة الواقع المعزز أو الجولات الصوتية.

MAZARAT_DATABASE = [
    {
        "id": "masjid-nabawi",
        "name": "المسجد النبوي الشريف",
        "city": "المدينة المنورة",
        "description": (
            "ثاني أقدس مكان في الإسلام، مسجد بناه النبي محمد صلى الله عليه "
            "وسلم بيده الشريفة عند هجرته إلى المدينة المنورة، ويضم الروضة "
            "الشريفة وقبر النبي صلى الله عليه وسلم وصاحبيه أبي بكر وعمر "
            "رضي الله عنهما. تتجلى فيه عمارة إسلامية فخمة بقبته الخضراء "
            "الشهيرة ومآذنه الشامخة التي تستقبل ملايين الزوار من أنحاء "
            "العالم على مدار العام."
        ),
        "latitude": 24.4672,
        "longitude": 39.6112,
        "category": "مسجد",
        "interactive_experience_url": "https://mazar.app/experience/masjid-nabawi",
    },
    {
        "id": "masjid-quba",
        "name": "مسجد قباء",
        "city": "المدينة المنورة",
        "description": (
            "أول مسجد بُني في الإسلام على الإطلاق، أسسه النبي صلى الله عليه "
            "وسلم فور وصوله مهاجراً إلى المدينة المنورة، قبل دخوله المدينة "
            "نفسها. وردت في فضله أحاديث نبوية تجعل الصلاة فيه تعدل أجر "
            "عمرة كاملة، ويتميز اليوم بتصميمه المعماري الراقي الذي يمزج "
            "بين الطراز الإسلامي الأصيل واللمسات المعاصرة الأنيقة."
        ),
        "latitude": 24.4392,
        "longitude": 39.6173,
        "category": "مسجد",
        "interactive_experience_url": "https://mazar.app/experience/masjid-quba",
    },
    {
        "id": "jabal-uhud",
        "name": "جبل أُحد",
        "city": "المدينة المنورة",
        "description": (
            "جبل عظيم يقع شمال المدينة المنورة، شهد غزوة أُحد الشهيرة في "
            "السنة الثالثة للهجرة، ودُفن عند سفحه سبعون من الصحابة الكرام "
            "استُشهدوا في تلك الغزوة، من بينهم سيد الشهداء حمزة بن عبد "
            "المطلب رضي الله عنه. وصفه النبي صلى الله عليه وسلم بقوله "
            "\"جبل يحبنا ونحبه\"، فهو معلم إيماني وتاريخي بامتياز."
        ),
        "latitude": 24.5044,
        "longitude": 39.6118,
        "category": "معلم تاريخي",
        "interactive_experience_url": "https://mazar.app/experience/jabal-uhud",
    },
    {
        "id": "masjid-al-haram",
        "name": "المسجد الحرام",
        "city": "مكة المكرمة",
        "description": (
            "أقدس بقعة على وجه الأرض، يضم الكعبة المشرفة قبلة المسلمين "
            "أجمعين، وبئر زمزم المباركة، ومقام إبراهيم عليه السلام. تتوافد "
            "إليه ملايين المسلمين سنوياً لأداء فريضتي الحج والعمرة، وتحيط "
            "به عمارة إسلامية مهيبة تجمع بين الفخامة الحديثة وقدسية المكان "
            "الأزلية التي لا تُضاهى."
        ),
        "latitude": 21.4225,
        "longitude": 39.8262,
        "category": "مسجد",
        "interactive_experience_url": "https://mazar.app/experience/masjid-al-haram",
    },
    {
        "id": "jabal-al-nour",
        "name": "جبل النور",
        "city": "مكة المكرمة",
        "description": (
            "جبل شامخ يقع شمال شرق مكة المكرمة، يحتضن في قمته غار حراء "
            "حيث كان النبي محمد صلى الله عليه وسلم يتعبّد قبل البعثة، "
            "ونزل عليه فيه الوحي لأول مرة بآيات سورة العلق. يقصده الزوار "
            "اليوم لتسلق دربه الوعر واستحضار لحظة بدء الرسالة الخالدة "
            "التي غيّرت مجرى التاريخ."
        ),
        "latitude": 21.4578,
        "longitude": 39.8590,
        "category": "معلم تاريخي",
        "interactive_experience_url": "https://mazar.app/experience/jabal-al-nour",
    },
]


# ---------------------------------------------------------------------------
# دوال مساعدة لحساب المسافة الجغرافية
# ---------------------------------------------------------------------------

EARTH_RADIUS_METERS = 6371000
INTERACTIVE_ACTIVATION_RADIUS_METERS = 100


def calculate_distance_in_meters(
    lat1: float, lon1: float, lat2: float, lon2: float
) -> float:
    """
    يحسب المسافة بالمتر بين نقطتين جغرافيتين باستخدام صيغة Haversine،
    وهي الصيغة القياسية والدقيقة لحساب المسافة بين نقطتين على سطح كروي
    مثل سطح الأرض، اعتماداً على خطوط العرض والطول لكل نقطة.
    """
    lat1_rad = math.radians(lat1)
    lon1_rad = math.radians(lon1)
    lat2_rad = math.radians(lat2)
    lon2_rad = math.radians(lon2)

    delta_lat = lat2_rad - lat1_rad
    delta_lon = lon2_rad - lon1_rad

    a = (
        math.sin(delta_lat / 2) ** 2
        + math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2
    )
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return EARTH_RADIUS_METERS * c


def build_mazar_item(
    mazar_data: dict, user_latitude: float, user_longitude: float
) -> MazarItem:
    """
    يبني كائن MazarItem كاملاً انطلاقاً من بيانات معلم ثابتة من قاعدة
    البيانات، مضيفاً إليه المسافة الفعلية من موقع المستخدم الحالي،
    وحالة تفعيل "المزارات التفاعلية" بناءً على تلك المسافة.
    """
    distance_in_meters = calculate_distance_in_meters(
        user_latitude,
        user_longitude,
        mazar_data["latitude"],
        mazar_data["longitude"],
    )

    is_interactive_available = distance_in_meters <= INTERACTIVE_ACTIVATION_RADIUS_METERS

    return MazarItem(
        id=mazar_data["id"],
        name=mazar_data["name"],
        city=mazar_data["city"],
        description=mazar_data["description"],
        latitude=mazar_data["latitude"],
        longitude=mazar_data["longitude"],
        category=mazar_data["category"],
        interactive_experience_url=mazar_data["interactive_experience_url"],
        distance_in_meters=round(distance_in_meters, 2),
        is_interactive_available=is_interactive_available,
    )


# ---------------------------------------------------------------------------
# نقاط النهاية (Endpoints)
# ---------------------------------------------------------------------------

@router.get("", response_model=NearbyMazaratResponse)
async def get_nearby_mazarat(
    latitude: float = Query(
        ...,
        ge=-90,
        le=90,
        description="خط عرض موقع المستخدم الحالي (Latitude) القادم من خرائط قوقل داخل تطبيق فلاتر",
    ),
    longitude: float = Query(
        ...,
        ge=-180,
        le=180,
        description="خط طول موقع المستخدم الحالي (Longitude) القادم من خرائط قوقل داخل تطبيق فلاتر",
    ),
) -> NearbyMazaratResponse:
    """
    يستقبل إحداثيات المستخدم الحالية (latitude, longitude) من تطبيق فلاتر،
    ويعيد قائمة كاملة بجميع مزارات التطبيق، مرتبة من الأقرب إلى الأبعد بالنسبة
    لموقع المستخدم، مع المسافة الفعلية بالمتر بين المستخدم وكل معلم.

    عندما تكون المسافة بين المستخدم ومعلم معيّن أقل من أو تساوي 100 متر،
    يُرجع الحقل is_interactive_available بالقيمة true لذلك المعلم، مما
    يسمح لتطبيق فلاتر بتفعيل تجربة "المزارات التفاعلية" الخاصة به.
    """
    mazarat_list = [
        build_mazar_item(mazar_data, latitude, longitude)
        for mazar_data in MAZARAT_DATABASE
    ]

    # ترتيب المزارات من الأقرب إلى الأبعد بالنسبة لموقع المستخدم الحالي
    mazarat_list.sort(key=lambda item: item.distance_in_meters)

    return NearbyMazaratResponse(
        user_latitude=latitude,
        user_longitude=longitude,
        total_results=len(mazarat_list),
        mazarat=mazarat_list,
    )


@router.get("/{mazar_id}", response_model=MazarItem)
async def get_mazar_details(
    mazar_id: str,
    latitude: Optional[float] = Query(
        None, ge=-90, le=90, description="خط عرض موقع المستخدم الحالي (اختياري)"
    ),
    longitude: Optional[float] = Query(
        None, ge=-180, le=180, description="خط طول موقع المستخدم الحالي (اختياري)"
    ),
) -> MazarItem:
    """
    يعيد تفاصيل معلم واحد محدد عبر معرّفه الفريد (id). في حال إرفاق
    إحداثيات المستخدم الحالية ضمن الطلب، يُحسب أيضاً المسافة الفعلية
    وحالة تفعيل التجربة التفاعلية لذلك المعلم تحديداً.
    """
    mazar_data = next((m for m in MAZARAT_DATABASE if m["id"] == mazar_id), None)

    if mazar_data is None:
        raise HTTPException(
            status_code=404, detail=f"لم يتم العثور على مزار بالمعرّف: {mazar_id}"
        )

    if latitude is not None and longitude is not None:
        return build_mazar_item(mazar_data, latitude, longitude)

    return MazarItem(
        id=mazar_data["id"],
        name=mazar_data["name"],
        city=mazar_data["city"],
        description=mazar_data["description"],
        latitude=mazar_data["latitude"],
        longitude=mazar_data["longitude"],
        category=mazar_data["category"],
        interactive_experience_url=mazar_data["interactive_experience_url"],
        distance_in_meters=None,
        is_interactive_available=False,
    )


@router.post("/{mazar_id}/activate", response_model=MazarItem)
async def activate_mazar(mazar_id: str, request: ActivateMazarRequest) -> MazarItem:
    """
    يتحقق من إمكانية تفعيل التجربة التفاعلية لمعلم معيّن بناءً على موقع
    المستخدم الفعلي المُرسَل، ويعيد بيانات المعلم كاملة إذا كان المستخدم
    ضمن نطاق 100 متر المسموح به. إذا كان المستخدم بعيداً عن المعلم، تُعاد
    استجابة خطأ توضح المسافة الحالية والمسافة المطلوبة للتفعيل.
    """
    mazar_data = next((m for m in MAZARAT_DATABASE if m["id"] == mazar_id), None)

    if mazar_data is None:
        raise HTTPException(
            status_code=404, detail=f"لم يتم العثور على مزار بالمعرّف: {mazar_id}"
        )

    mazar_item = build_mazar_item(mazar_data, request.latitude, request.longitude)

    if not mazar_item.is_interactive_available:
        raise HTTPException(
            status_code=403,
            detail=(
                "لم يتم تفعيل التجربة التفاعلية؛ يجب أن يكون المستخدم على بعد "
                f"{INTERACTIVE_ACTIVATION_RADIUS_METERS} متر أو أقل من المعلم. "
                f"المسافة الحالية: {mazar_item.distance_in_meters} متر."
            ),
        )

    return mazar_item


@router.get("/health/check", tags=["عام"])
async def mazarat_health():
    """فحص سريع للتأكد من أن خدمة المزارات التفاعلية متاحة وتعمل بنجاح."""
    return {
        "status": "ok",
        "service": "mazarat",
        "total_mazarat": len(MAZARAT_DATABASE),
    }
