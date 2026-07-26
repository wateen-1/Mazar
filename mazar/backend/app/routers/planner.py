"""
مسار /planner - محرك تخطيط الرحلات الذكي الفعلي
==================================================
نقطة النهاية الخاصة بتوليد جدول زيارة ذكي كامل للمستخدم، اعتماداً على عدد
أيام زيارته واهتماماته الثقافية المفضلة، وموقعه الجغرافي الحالي إن توفر.

يحتوي هذا الملف حالياً على قاعدة بيانات ثابتة (Mock Data) لثمانية معالم
رئيسية في المدينة المنورة، ريثما يُربط لاحقاً بقاعدة بيانات فعلية أو
بنموذج ذكاء اصطناعي توليدي حقيقي. المنطق الخوارزمي نفسه (الترتيب الجغرافي،
توزيع الأيام، الجدولة الزمنية، حساب المسافات، وتوقع الازدحام) حقيقي
وفعّال بالكامل، وليس مجرد بيانات وهمية ثابتة.

خوارزمية التخطيط تعمل على أربع مراحل متتالية:
    1. تصفية المعالم حسب الاهتمامات الثقافية المُختارة من المستخدم.
    2. ترتيبها جغرافياً عبر خوارزمية "أقرب جار" (Nearest Neighbor) ابتداءً
       من موقع المستخدم الحالي (أو من المسجد النبوي كمركز افتراضي للمدينة).
    3. توزيعها على أيام الزيارة، بحد أقصى ثلاثة معالم في اليوم الواحد.
    4. جدولة وقت بداية كل زيارة داخل يومها، وحساب المسافة الفعلية إلى
       المعلم التالي في الخطة بأكملها عبر صيغة Haversine، وتوقع تقريبي
       لحالة الازدحام وقت تلك الزيارة تحديداً.
"""

import math
from datetime import datetime, timedelta
from typing import Dict, List, Optional

from fastapi import APIRouter, HTTPException

from app.models.schemas import PlannerItem, PlannerRequest, PlannerResponse

router = APIRouter(prefix="/planner", tags=["المخطط الذكي"])


# ---------------------------------------------------------------------------
# ثوابت الخوارزمية
# ---------------------------------------------------------------------------

# الحد الأقصى لعدد المعالم التي تُجدوَل في اليوم الواحد، حفاظاً على تجربة
# زيارة مريحة وغير مُرهقة للمستخدم.
MAX_STOPS_PER_DAY = 3

# الساعة التي تبدأ عندها أول زيارة في كل يوم من أيام الخطة (بتوقيت محلي ساذج
# بلا منطقة زمنية، بما يتوافق مع طريقة إرسال visit_date من تطبيق فلاتر).
DAY_START_HOUR = 9

# فاصل زمني ثابت (بالدقائق) يُضاف بين نهاية زيارة وبداية التي تليها، يمثّل
# وقت التنقل والراحة بين معلمين متتاليين.
TRAVEL_BUFFER_MINUTES = 30

# نصف قطر الأرض بالمتر، يُستخدم في صيغة Haversine لحساب المسافات الجغرافية.
EARTH_RADIUS_METERS = 6371000.0

# إحداثيات المسجد النبوي الشريف، تُستخدم كمركز انطلاق افتراضي للمسار
# الجغرافي عندما لا يُرسل التطبيق موقع المستخدم الحالي ضمن الطلب.
DEFAULT_START_LATITUDE = 24.4672
DEFAULT_START_LONGITUDE = 39.6112


# ---------------------------------------------------------------------------
# قاعدة البيانات الثابتة (Mock Data) لمعالم المدينة المنورة الرئيسية
# ---------------------------------------------------------------------------
# ملاحظة: قيم categories هنا مطابقة حرفياً لقائمة شرائح الاهتمام الثقافي
# المعروضة في نموذج شاشة المخطط الذكي داخل تطبيق فلاتر
# (lib/features/planner/presentation/screens/planner_screen.dart):
# "تاريخي"، "أثري"، "روحاني"، "معماري"، "ثقافي عام".
# كل معلم قد يحمل أكثر من تصنيف واحد، مما يسمح بمطابقته مع أكثر من اهتمام.

MEDINAH_MAZARAT_DATABASE: List[Dict] = [
    {
        "id": "masjid-nabawi",
        "name": "المسجد النبوي الشريف",
        "city": "المدينة المنورة",
        "description": (
            "ثاني أقدس مكان في الإسلام، ومسجد بناه النبي محمد صلى الله عليه "
            "وسلم بيده الشريفة عند هجرته إلى المدينة المنورة، ويضم الروضة "
            "الشريفة وقبر النبي صلى الله عليه وسلم وصاحبيه أبي بكر وعمر "
            "رضي الله عنهما، وتحيط به قبته الخضراء الشهيرة ومآذنه الشامخة."
        ),
        "latitude": 24.4672,
        "longitude": 39.6112,
        "categories": ["روحاني", "تاريخي"],
        "opening_time": "00:00",
        "closing_time": "23:59",
        "visit_duration_minutes": 120,
    },
    {
        "id": "masjid-quba",
        "name": "مسجد قباء",
        "city": "المدينة المنورة",
        "description": (
            "أول مسجد بُني في الإسلام على الإطلاق، أسسه النبي صلى الله عليه "
            "وسلم فور وصوله مهاجراً إلى المدينة المنورة. وردت في فضله "
            "أحاديث نبوية تجعل الصلاة فيه تعدل أجر عمرة كاملة، ويتميز اليوم "
            "بتصميمه المعماري الراقي الذي يمزج بين الأصالة والحداثة."
        ),
        "latitude": 24.4392,
        "longitude": 39.6173,
        "categories": ["روحاني", "تاريخي"],
        "opening_time": "05:00",
        "closing_time": "22:00",
        "visit_duration_minutes": 60,
    },
    {
        "id": "masjid-qiblatain",
        "name": "مسجد القبلتين",
        "city": "المدينة المنورة",
        "description": (
            "مسجد تاريخي فريد شهد لحظة نزول الأمر الإلهي بتحويل القبلة من "
            "بيت المقدس إلى المسجد الحرام أثناء صلاة الظهر، فصلّى النبي صلى "
            "الله عليه وسلم والصحابة ركعتين إلى المسجد الأقصى وركعتين إلى "
            "الكعبة المشرفة في الصلاة نفسها، ومن هنا جاءت تسميته."
        ),
        "latitude": 24.4754,
        "longitude": 39.5980,
        "categories": ["تاريخي", "روحاني"],
        "opening_time": "05:00",
        "closing_time": "22:00",
        "visit_duration_minutes": 60,
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
            "\"جبل يحبنا ونحبه\"."
        ),
        "latitude": 24.5044,
        "longitude": 39.6118,
        "categories": ["تاريخي"],
        "opening_time": "06:00",
        "closing_time": "18:00",
        "visit_duration_minutes": 90,
    },
    {
        "id": "al-baqi",
        "name": "مقبرة البقيع",
        "city": "المدينة المنورة",
        "description": (
            "مقبرة أهل المدينة المنورة الملاصقة للمسجد النبوي الشريف، تضم "
            "رفات عدد كبير من الصحابة وأمهات المؤمنين وأهل بيت النبي صلى "
            "الله عليه وسلم رضي الله عنهم أجمعين، وهي من أقدس البقاع "
            "وأكثرها هيبة وسكينة في المدينة المنورة."
        ),
        "latitude": 24.4685,
        "longitude": 39.6135,
        "categories": ["روحاني", "تاريخي"],
        "opening_time": "16:00",
        "closing_time": "18:00",
        "visit_duration_minutes": 45,
    },
    {
        "id": "dar-almadinah-museum",
        "name": "متحف دار المدينة",
        "city": "المدينة المنورة",
        "description": (
            "متحف تراثي وثقافي يروي قصة المدينة المنورة عبر العصور، من "
            "خلال مجسمات ووثائق ومقتنيات تاريخية تعرّف الزائر بتاريخ "
            "المدينة العمراني والاجتماعي، ويُعد وجهة مثالية لمحبي "
            "استكشاف الجانب الأثري والثقافي العميق للمدينة."
        ),
        "latitude": 24.4700,
        "longitude": 39.6050,
        "categories": ["أثري", "ثقافي عام"],
        "opening_time": "09:00",
        "closing_time": "21:00",
        "visit_duration_minutes": 75,
    },
    {
        "id": "jabal-rumah",
        "name": "جبل الرماة",
        "city": "المدينة المنورة",
        "description": (
            "الموقع الذي تمركز فيه رماة المسلمين في غزوة أُحد بأمر من "
            "النبي صلى الله عليه وسلم لحماية ظهر الجيش، ويُعد من أبرز "
            "المواقع الأثرية والتاريخية المرتبطة بأحداث الغزوة، ويوفّر "
            "إطلالة بانورامية على أرض المعركة بأكملها."
        ),
        "latitude": 24.5090,
        "longitude": 39.6140,
        "categories": ["تاريخي", "أثري"],
        "opening_time": "06:00",
        "closing_time": "18:00",
        "visit_duration_minutes": 60,
    },
    {
        "id": "hejaz-railway-museum",
        "name": "متحف محطة سكة حديد الحجاز",
        "city": "المدينة المنورة",
        "description": (
            "محطة تاريخية من محطات خط سكة حديد الحجاز العثماني، تحوّلت "
            "اليوم إلى متحف يعرض القاطرات والعربات القديمة والمباني ذات "
            "الطراز المعماري العثماني الأصيل، وتحكي قصة أحد أعظم المشاريع "
            "الهندسية في تاريخ المنطقة."
        ),
        "latitude": 24.4645,
        "longitude": 39.5893,
        "categories": ["معماري", "ثقافي عام"],
        "opening_time": "08:00",
        "closing_time": "20:00",
        "visit_duration_minutes": 60,
    },
]


# ---------------------------------------------------------------------------
# دوال مساعدة: المسافة الجغرافية
# ---------------------------------------------------------------------------

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


# ---------------------------------------------------------------------------
# المرحلة الأولى: تصفية المعالم حسب الاهتمامات الثقافية المُختارة
# ---------------------------------------------------------------------------

def filter_landmarks_by_interest(preferred_categories: List[str]) -> List[Dict]:
    """
    يعيد قائمة المعالم التي تطابق واحداً على الأقل من الاهتمامات الثقافية
    المُختارة من المستخدم. إذا لم يُحدَّد المستخدم أي اهتمام، تُعاد قاعدة
    البيانات كاملة. وإذا لم يطابق أي معلم الاهتمامات المُرسَلة (اهتمامات
    غير معروفة مثلاً)، تُعاد أيضاً القاعدة كاملة بدلاً من خطة فارغة تماماً،
    حفاظاً على تجربة مستخدم سليمة ومفيدة دوماً.
    """
    if not preferred_categories:
        return list(MEDINAH_MAZARAT_DATABASE)

    normalized_preferences = set(preferred_categories)

    filtered = [
        landmark
        for landmark in MEDINAH_MAZARAT_DATABASE
        if normalized_preferences.intersection(landmark["categories"])
    ]

    return filtered if filtered else list(MEDINAH_MAZARAT_DATABASE)


# ---------------------------------------------------------------------------
# المرحلة الثانية: الترتيب الجغرافي عبر خوارزمية أقرب جار (Nearest Neighbor)
# ---------------------------------------------------------------------------

def build_geographic_route(
    landmarks: List[Dict],
    start_latitude: float,
    start_longitude: float,
    max_stops: int,
) -> List[Dict]:
    """
    يبني مساراً جغرافياً منطقياً عبر خوارزمية "أقرب جار" المطمعة (Greedy
    Nearest Neighbor): تبدأ من موقع الانطلاق (موقع المستخدم الحالي أو
    المسجد النبوي كمركز افتراضي)، وفي كل خطوة تختار أقرب معلم غير مُزار
    بعد من الموقع الحالي، حتى تصل إلى الحد الأقصى المطلوب من التوقفات.
    هذا يضمن أن يكون ترتيب الزيارات منطقياً جغرافياً ولا يُهدر وقت
    المستخدم بالتنقل ذهاباً وإياباً بين أطراف المدينة.
    """
    remaining_landmarks = list(landmarks)
    route: List[Dict] = []

    current_latitude = start_latitude
    current_longitude = start_longitude

    while remaining_landmarks and len(route) < max_stops:
        remaining_landmarks.sort(
            key=lambda landmark: calculate_distance_in_meters(
                current_latitude,
                current_longitude,
                landmark["latitude"],
                landmark["longitude"],
            )
        )

        nearest_landmark = remaining_landmarks.pop(0)
        route.append(nearest_landmark)

        current_latitude = nearest_landmark["latitude"]
        current_longitude = nearest_landmark["longitude"]

    return route


# ---------------------------------------------------------------------------
# المرحلة الثالثة: توزيع المسار على أيام الزيارة
# ---------------------------------------------------------------------------

def distribute_route_into_days(
    route: List[Dict], number_of_days: int
) -> List[List[Dict]]:
    """
    يوزّع المعالم المُرتَّبة جغرافياً على أيام الزيارة المطلوبة، بحد أقصى
    MAX_STOPS_PER_DAY معالم في اليوم الواحد، مع الحفاظ على ترتيبها
    الجغرافي المتسلسل داخل كل يوم وبين الأيام.
    """
    days: List[List[Dict]] = [[] for _ in range(number_of_days)]

    for index, landmark in enumerate(route):
        day_index = index // MAX_STOPS_PER_DAY
        if day_index >= number_of_days:
            break
        days[day_index].append(landmark)

    return days


# ---------------------------------------------------------------------------
# المرحلة الرابعة: الجدولة الزمنية داخل كل يوم
# ---------------------------------------------------------------------------

def schedule_day(
    day_landmarks: List[Dict], visit_date: datetime, day_index: int
) -> List[Dict]:
    """
    يحدد وقت بداية كل زيارة ضمن يوم واحد من الخطة: يبدأ اليوم الساعة
    DAY_START_HOUR بالضبط (09:00 افتراضياً)، وتُضاف مدة كل زيارة
    (visit_duration_minutes الخاصة بذلك المعلم تحديداً) بالإضافة إلى فاصل
    انتقال ثابت (TRAVEL_BUFFER_MINUTES) قبل بدء الزيارة التي تليها.

    يعيد قائمة من القواميس، كل عنصر منها يحمل بيانات المعلم الأصلية بالإضافة
    إلى وقت الزيارة المجدول ورقم اليوم.
    """
    day_date = (visit_date + timedelta(days=day_index)).date()
    current_time = datetime(day_date.year, day_date.month, day_date.day, DAY_START_HOUR, 0, 0)

    scheduled_items: List[Dict] = []

    for landmark in day_landmarks:
        scheduled_items.append(
            {
                "landmark": landmark,
                "scheduled_time": current_time,
                "day_number": day_index + 1,
            }
        )

        visit_duration = timedelta(minutes=landmark["visit_duration_minutes"])
        travel_buffer = timedelta(minutes=TRAVEL_BUFFER_MINUTES)
        current_time = current_time + visit_duration + travel_buffer

    return scheduled_items


# ---------------------------------------------------------------------------
# توقع تقريبي لحالة الازدحام بحسب وقت الزيارة ونوع المعلم
# ---------------------------------------------------------------------------

def predict_crowd_status(visit_time: datetime, categories: List[str]) -> str:
    """
    يتنبأ بحالة الازدحام التقريبية وقت الزيارة المقترحة، اعتماداً على
    ساعة اليوم (قرب أوقات الصلوات الخمس التي تشهد ذروة الزيارات في
    المواقع الروحانية تحديداً)، ونوع المعلم نفسه. هذا توقع تقريبي مبسّط
    (Heuristic) وليس نموذج تعلّم آلي فعلياً، ريثما تُربط هذه الدالة لاحقاً
    ببيانات ازدحام تاريخية حقيقية عبر نقطة النهاية /crowd.
    """
    time_value = visit_time.hour + (visit_time.minute / 60)
    is_spiritual_site = "روحاني" in categories

    # نوافذ الذروة القريبة من أوقات الصلوات الخمس، حيث يتوافد أكبر عدد من
    # الزوار على المواقع الروحانية تحديداً كالمسجد النبوي ومسجد قباء
    peak_windows = [
        (4.5, 6.0),    # قرب صلاة الفجر
        (11.5, 13.5),  # قرب صلاة الظهر
        (14.5, 16.0),  # قرب صلاة العصر
        (17.5, 19.5),  # قرب صلاة المغرب
        (19.5, 21.0),  # قرب صلاة العشاء
    ]

    for start, end in peak_windows:
        if start <= time_value <= end:
            return "High" if is_spiritual_site else "Medium"

    # نوافذ هادئة: الصباح الباكر جداً، فترة القيلولة بعد الظهر، والليل المتأخر
    quiet_windows = [(0.0, 8.0), (13.5, 14.5), (21.5, 24.0)]

    for start, end in quiet_windows:
        if start <= time_value < end:
            return "Low"

    return "Medium"


# ---------------------------------------------------------------------------
# نقاط النهاية (Endpoints)
# ---------------------------------------------------------------------------

@router.post("", response_model=PlannerResponse)
async def generate_plan(request: PlannerRequest) -> PlannerResponse:
    """
    يولّد جدول زيارة ذكياً كاملاً بناءً على مدة زيارة المستخدم (عدد الأيام)
    واهتماماته الثقافية المفضلة وموقعه الحالي إن توفر، عبر أربع مراحل:
    تصفية المعالم، ترتيبها جغرافياً، توزيعها على الأيام، ثم جدولتها زمنياً
    مع حساب المسافة إلى المعلم التالي وتوقع حالة الازدحام لكل زيارة.

    تُعاد جميع عناصر الخطة (عبر كل الأيام) ضمن قائمة items واحدة مسطّحة
    ومرتّبة زمنياً وجغرافياً بالتسلسل الصحيح تماماً كما يستهلكها تطبيق
    فلاتر حالياً، مع حقول day_number وdistance_to_next_meters
    وcrowd_status الإضافية على كل عنصر لإثراء العرض لاحقاً.
    """
    try:
        filtered_landmarks = filter_landmarks_by_interest(request.preferred_categories)

        if not filtered_landmarks:
            # حالة احتياطية نظرية فقط؛ filter_landmarks_by_interest تضمن
            # عملياً عدم إعادة قائمة فارغة أبداً، لكن نتعامل معها بأمان
            return PlannerResponse(items=[])

        max_total_stops = min(
            request.number_of_days * MAX_STOPS_PER_DAY, len(filtered_landmarks)
        )

        start_latitude = (
            request.current_latitude
            if request.current_latitude is not None
            else DEFAULT_START_LATITUDE
        )
        start_longitude = (
            request.current_longitude
            if request.current_longitude is not None
            else DEFAULT_START_LONGITUDE
        )

        geographic_route = build_geographic_route(
            filtered_landmarks, start_latitude, start_longitude, max_total_stops
        )

        days = distribute_route_into_days(geographic_route, request.number_of_days)

        all_scheduled_items: List[Dict] = []
        for day_index, day_landmarks in enumerate(days):
            if not day_landmarks:
                continue
            all_scheduled_items.extend(
                schedule_day(day_landmarks, request.visit_date, day_index)
            )

        planner_items: List[PlannerItem] = []

        for index, scheduled in enumerate(all_scheduled_items):
            landmark = scheduled["landmark"]
            scheduled_time: datetime = scheduled["scheduled_time"]

            distance_to_next_meters: Optional[float] = None
            if index < len(all_scheduled_items) - 1:
                next_landmark = all_scheduled_items[index + 1]["landmark"]
                distance_to_next_meters = round(
                    calculate_distance_in_meters(
                        landmark["latitude"],
                        landmark["longitude"],
                        next_landmark["latitude"],
                        next_landmark["longitude"],
                    ),
                    2,
                )

            crowd_status = predict_crowd_status(scheduled_time, landmark["categories"])

            planner_items.append(
                PlannerItem(
                    id=landmark["id"],
                    title=landmark["name"],
                    description=landmark["description"],
                    scheduled_time=scheduled_time,
                    location_name=landmark["city"],
                    latitude=landmark["latitude"],
                    longitude=landmark["longitude"],
                    day_number=scheduled["day_number"],
                    distance_to_next_meters=distance_to_next_meters,
                    crowd_status=crowd_status,
                )
            )

        return PlannerResponse(items=planner_items)

    except HTTPException:
        # إعادة رفع أي HTTPException أُطلقت عمداً داخل الكتلة أعلاه كما هي
        raise
    except Exception as error:
        # أي خطأ غير متوقع أثناء حساب الخطة يُترجَم إلى استجابة خطأ خادم
        # واضحة (500) بدلاً من انهيار غير مفهوم لدى المستخدم
        raise HTTPException(
            status_code=500,
            detail=f"تعذر توليد الخطة الذكية بسبب خطأ داخلي في الخادم: {error}",
        )


@router.get("/health", tags=["عام"])
async def planner_health():
    """فحص سريع للتأكد من أن خدمة المخطط الذكي متاحة، مع عدد المعالم المتوفرة حالياً."""
    return {
        "status": "ok",
        "service": "planner",
        "total_landmarks": len(MEDINAH_MAZARAT_DATABASE),
    }
