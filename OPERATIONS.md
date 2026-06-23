# 호놀룰루 콘도 시세맵 — 운영 매뉴얼 v2

> **이 문서는 4개 지역(워드빌리지/와이키키/알라모아나/솔트) 31개 콘도 133 unit 시세맵을 매주 운영하는 흐름을 정리한 가이드입니다.**
> 한 달 후, 6개월 후의 본인도 헷갈리지 않게.
>
> *마지막 업데이트: 2026-05-24 / v2 (4지역 통합 시스템)*

---

## 목차

1. [주간 운영 흐름 (요약)](#1-주간-운영-흐름-요약)
2. [매주 작업 단계 상세](#2-매주-작업-단계-상세)
3. [SQL 자주 쓰는 패턴](#3-sql-자주-쓰는-패턴)
4. [콘도/지역 추가하기](#4-콘도지역-추가하기)
5. [트러블슈팅](#5-트러블슈팅)
6. [시스템 구조 이해](#6-시스템-구조-이해)
7. [향후 개선 아이디어](#7-향후-개선-아이디어)
8. [FAQ](#8-faq)
9. [매주 체크리스트](#9-매주-체크리스트)

---

## 1. 주간 운영 흐름 (요약)

### 전체 흐름 (약 60~90분 — 31개 콘도 기준)

```
[매주 정해진 요일]

① 변경 정보 수집 (30~45분)
   31개 콘도 Zillow Saved Search 알림 확인 + 사이트 순회
   
   ↓
   
② 작업 시작 — 백업 (5초)
   python snapshot_data.py
   
   ↓
   
③ 데이터 입력 (15~30분)
   Supabase SQL Editor에서 UPDATE/INSERT
   
   ↓
   
④ 자동 빌드 + 변경 확인 (1분)
   .\weekly_update.ps1
   → JSON 갱신 → 5개 HTML 자동 빌드 → diff 출력
   
   ↓
   
⑤ 로컬 확인 (1분)
   브라우저로 output 페이지 확인
   
   ↓
   
⑥ GitHub 푸시 (1분)
   git add . && git commit -m "weekly update YYYY-MM-DD"
   git push origin main
   → 1~2분 후 라이브 페이지 갱신
```

---

## 2. 매주 작업 단계 상세

### ① 변경 정보 수집

#### 31개 콘도 우선순위 분류

매주 31개를 다 보긴 부담스러우니까 **변동성 기준 우선순위**로 작업하면 효율적:

| 우선순위 | 콘도 | 이유 |
|---|---|---|
| 🔴 매주 필수 | 매물 회전 빠른 콘도 — 워드빌리지 신축(Aalii, Koula, Victoria Place), Waikiki Banyan, ONE Ala Moana, The Collection | 매물 변동 잦음 |
| 🟡 격주 점검 | 럭셔리 거주형 — Park Lane, Hokua, Ritz-Carlton, Allure, Watermark, Symphony | 회전율 낮음 |
| 🟢 월 1회 점검 | 클래식 (Waikiki Beach Tower 등), 분양 중 신축 (Alia/Kaliu/Kahuina) | 변동 거의 없음 |

#### 데이터 소스

| 데이터 | 출처 | 주기 |
|---|---|---|
| 매물가 변동 | Zillow Saved Search 알림 | 매주 |
| 신규 매물 | Zillow, Hawaii Life, Redfin | 매주 |
| 분양가 등록 | Honolulu Real Property | 신규 분양 시 |
| 임대료 추정치 | Zillow Rent Estimate | 매월 |

#### Zillow Saved Search 설정 (1회만)

각 콘도 검색 → Save Search → 이메일 알림.
**31개 콘도 모두 설정**해두면 변동분만 받아볼 수 있어서 작업 시간 크게 줄어듦.

콘도별 Zillow 주소:
- 워드빌리지 13개: `Ward Village, Honolulu, HI`로 묶어서 검색 가능
- 와이키키 6개: 콘도별 개별 검색 (다양한 단지가 있어서)
- 알라모아나 6개: 개별 검색
- 솔트 6개: `Our Kakaako`로 묶거나 개별 검색

---

### ② 작업 시작 — 스냅샷 저장

**작업 시작 전 반드시 이거 먼저**:

```powershell
cd C:\Users\LG\Desktop\ward-village-map
.venv\Scripts\Activate.ps1
python snapshot_data.py
```

`snapshots/` 폴더에 두 파일 생성:
- `ward_village_YYYY-MM-DD.json` — 영구 보관 (이력)
- `latest.json` — diff 도구가 사용

> **스냅샷 안 하면**: diff 도구가 이번 주 vs 이번 주 비교 → 변경 없음으로 나옴.

---

### ③ 데이터 입력 — Supabase

Supabase 대시보드 → SQL Editor에서 변경 사항 입력.

#### ⚠️ 핵심 원칙 (v3): "기록만 하고, 판단은 코드가 한다"

예전엔 타입별로 **대표 매물 하나를 직접 골라** 저장했다. 그래서 새 매물이 뜰 때마다
"이게 기존 대표보다 비싼가? 교체할까?" 하는 판단이 매번 들어갔고, 그 기준이
머릿속에만 있어서 시간이 지나면 흔들렸다.

**v3부터는 본 매물을 전부 그대로 기록**한다. 어떤 게 그 타입의 "시세 대표"가 될지는
`build_data.py`가 규칙대로 자동으로 고른다(아래 규칙 참조). 즉 입력 단계에는 더 이상
"대표 고르기" 판단이 없다 — Zillow에서 본 대로 INSERT/DEACTIVATE만 하면 된다.

> 💡 "2번째 최고가" 규칙의 효과를 보려면 **타입별로 최소 상위 2~3건은 기록**해야 한다.
> 1건만 기록하면 그 1건이 그대로 대표가 된다(허위/과대호가 거르기 효과 없음).

**대표 선정 규칙 (코드가 자동 적용)**:

| 그 타입의 활성 매물 수 | 대표 = |
|---|---|
| 3건 이상 | 가격 내림차순 **2번째** (최고가는 허위/과대호가 가능성 → 제외) |
| 2건 | 둘 중 **낮은 쪽** (= 2번째 최고가) |
| 1건 | 그 1건 |
| 0건 | 가격이 남아 있는 비활성 매물 중 **최신** → "직전 호가"로 stale 표시 |

#### 매물 변동 처리 (3가지뿐)

| 상황 | 처리 |
|---|---|
| **새 매물 등장** | `INSERT` — 최고가가 아니어도 그대로 한 줄 추가. `is_active=true`, `first_seen`/`last_seen`=오늘 |
| **가격 변동** | `UPDATE current_list_price` + `last_seen`=오늘 |
| **매물 내려감** | `UPDATE is_active=false` + `last_seen`=오늘. **가격은 지우지 말 것** (직전 호가로 보존됨) |

> ❌ 예전처럼 `current_list_price = NULL` 로 지우지 않는다. 가격을 남겨둬야
> 활성 매물이 0건이 됐을 때 "직전 호가"로 시세를 보여줄 수 있다.

자세한 SQL 패턴은 [3번 섹션](#3-sql-자주-쓰는-패턴) 참조.

---

### ③-A. 캡처 → SQL 주간 레시피 (Claude 활용) ⭐

매물 조사·SQL 작성을 Claude에게 맡기는 가장 쉬운 흐름. **도 님은 캡처 주고, 새 대표 호수 분양가만 조사하면 끝.**

```
[바뀐 콘도만]

① Zillow에서 콘도 페이지 → "Available units" → BR 탭별(1bed/2bed/3bed/4bed)로 캡처
   - "All (N)" 숫자도 같이 보이게 (총 매물 수 검증용)
   - 호수·면적·가격이 잘 보이는 '목록' 화면으로

② Claude에 캡처 + 콘도명 전달  (예: "Waiea 업데이트")

③ Claude가 자동 처리:
   - 캡처에서 전 매물 추출 (호수/침실/면적/가격/Active)
   - '2번째 최고가' 규칙으로 타입별 대표 선정
   - 기존 ward_village_data.json과 호수(unit_no)로 대조
     → 가격변동 / 신규 / 사라짐 판별
   - "새 대표 중 처음 보는 호수"만 콕 집어 조사 요청

④ 도 님은 그 호수들의 분양가(+임대 추정)만 조사해서 txt로 전달
   - 탭 구분 표가 이상적 (이미 정리한 숫자는 캡처 말고 txt로)
   - 없으면 "정보없음" → 빈칸으로 처리

⑤ Claude가 복붙용 SQL 생성 (INSERT / last_seen UPDATE / DEACTIVATE)

⑥ Supabase SQL Editor에 붙여 Run → python build_data.py → python build_html.py
   (= .\weekly_update.ps1 한 방) → 확인 → git push
```

**대조·선정 규칙 (Claude가 적용, 일관성 보장)**

- **대표 = 활성 매물 중 "2번째 최고가"** (최고가는 허위/과대호가 가능성 → 제외). 활성 2건이면 낮은 쪽, 1건이면 그것, 0건이면 직전 호가 stale.
- **타입 분류**: 같은 침실 수라도 **가격대가 확연히 다르면 나눈다**(욕실 수·면적 기준, 예: 2ba `2BR` / 2.5ba `2BR(대형)`). 비슷하면 묶는다. Villa·PT·PH 같은 펜트하우스/특수형은 **독립 타입 유지**.
- **"Active Under Contract"(계약 진행중)도 활성**으로 포함.
- **매물 내려가도 `current_list_price`는 지우지 말 것** → `is_active=false`만. (직전 호가 stale 표시에 필요)
- **조사(분양가/임대)는 "처음 보는 새 대표 호수"만.** 한 번 조사한 호수는 DB에 영구 보존돼 다시 대표가 돼도 재사용(재조사 불필요).

**저장 모델**: 타입별 대표 1개만 활성으로 유지(rep-only). 대표가 아니게 된 호수는 비활성 처리하고 가격은 보존. DB = "타입별 시세 대표 + 이력". (모든 활성 매물을 다 담는 store-all로 바꾸려면 매주 SQL이 훨씬 길어지므로 비권장.)

> ⚠️ **타입 이름 변경 시 유령 주의**: 어떤 타입의 이름을 바꿀 땐(예: `2BR(2b3b)`→`2BR(대형)`) **그 타입의 비활성 행도 같이 새 이름으로 UPDATE**할 것. 안 그러면 옛 이름 타입에 활성 매물이 0이 되면서 "직전 호가" 유령 행이 맵에 남는다.
>
> 💡 **PowerShell 실행 주의**: `build_html.py`만 치면 "명령 인식 안 됨" 에러. 반드시 `python build_html.py` 또는 `.\weekly_update.ps1`.

---

### ④ 자동 빌드

```powershell
.\weekly_update.ps1
```

3단계 자동 실행:
1. `build_data.py` — Supabase → JSON
2. `diff_data.py` — 변경 사항 출력
3. `build_html.py` — JSON → **5개 HTML** 자동 빌드
   - `index.html` (전체)
   - `ward-village.html`
   - `waikiki.html`
   - `ala-moana.html`
   - `salt.html`

---

### ⑤ 결과 확인

콘솔의 diff 출력 확인:
```
📈 가격 상승 (N건):
📉 가격 하락 (N건):
🆕 신규 매물 (N건):
❌ 매물 사라짐 (N건):
```

브라우저로 `index.html` 새로고침 → 시세맵 화면에 반영됐는지 확인.

체크 포인트:
- [ ] 변경한 unit의 매물가가 갱신됐나?
- [ ] 매물 없음 처리한 unit의 분양가가 "-"로 표시되나?
- [ ] 최근 실거래 처리한 unit에 노란 배지 보이나?
- [ ] 5개 페이지(전체 + 지역별 4개) 다 정상 빌드됐나?

---

### ⑥ GitHub 푸시

로컬 확인 끝나면 라이브 페이지에도 반영:

```powershell
git add .
git commit -m "weekly update 2026-XX-XX"
git push origin main
```

푸시 후 1~2분 대기 → GitHub Pages 자동 빌드 → 라이브 URL 갱신.

라이브 URL:
```
https://2gamja.github.io/ward-village-map/                    ← 전체
https://2gamja.github.io/ward-village-map/ward-village.html
https://2gamja.github.io/ward-village-map/waikiki.html
https://2gamja.github.io/ward-village-map/ala-moana.html
https://2gamja.github.io/ward-village-map/salt.html
```

---

## 3. SQL 자주 쓰는 패턴

### 3-1. 매물가 변경 (가장 자주 씀)

```sql
-- 특정 콘도의 특정 unit 가격 업데이트
UPDATE units 
SET current_list_price = 1099000 
WHERE unit_no = '507' 
  AND unit_type = '1BR'
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Anaha');
```

**주의**:
- `tower_id`로 콘도 식별 (이름만으로는 다른 콘도 unit 잘못 수정 가능)
- `unit_no` + `unit_type` 조합으로 unit 식별
- v2부터 같은 unit_no가 여러 콘도에 있을 수 있음 (예: #2302가 Park Lane에도 있고 ONE Ala Moana에도 있음). **반드시 building_name으로 콘도 지정**.

---

### 3-2. 매물 사라짐 — 일반 매물 (NULL 처리)

3BR 미만 또는 $2M 미만 매물이 사라진 경우:

```sql
-- 매물가를 NULL로 변경 → 시세맵에 "매물 없음" 표시
UPDATE units 
SET current_list_price = NULL,
    listing_url = NULL,
    est_rent_monthly = NULL
WHERE unit_no = '2810' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');
```

`est_rent_monthly`도 같이 NULL로 — 매물 없으면 임대 데이터도 무의미해서.

---

### 3-3. 매물 사라짐 — 럭셔리 (최근 실거래 처리)

**3BR+ 럭셔리 + $2M 이상**이 사라진 경우 → 데이터 보존:

```sql
-- 매물가는 유지하고 notes에 recent_sold 플래그 추가
UPDATE units 
SET notes = 'recent_sold'
WHERE unit_no = '5301' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');
```

이러면 시세맵에서 매물가 옆에 "최근 실거래" 배지가 자동 표시됨.

#### 럭셔리 매물이 새로 또 나오면 (recent_sold 해제)

```sql
-- recent_sold 플래그 제거 + 새 매물가 입력
UPDATE units 
SET notes = NULL,
    current_list_price = 9500000,
    listing_url = 'https://zillow.com/...'
WHERE unit_no = '5301' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');
```

---

### 3-4. 신규 매물 등록

기존 unit이 다시 매물로 나오는 경우:

```sql
UPDATE units 
SET current_list_price = 695000,
    listing_url = 'https://zillow.com/...',
    est_rent_monthly = 4200
WHERE unit_no = '1102' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Anaha');
```

완전 신규 unit 추가 (그 콘도에서 처음 등록):

```sql
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft, 
  original_price, current_list_price, est_rent_monthly, 
  hoa_monthly, view_type, listing_url, notes
)
VALUES (
  (SELECT id FROM towers WHERE building_name = 'Anaha'),
  '1BR', '1102', 538, 530000, 695000, 4200, 850, 'Ocean',
  'https://zillow.com/...', NULL
);
```

---

### 3-5. 임대료 업데이트

```sql
-- Zillow Rent Estimate 갱신
UPDATE units 
SET est_rent_monthly = 4500
WHERE unit_no = '507' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Anaha');
```

---

### 3-6. 콘도 메타데이터 플래그 (towers.notes)

**리스홀드 전환 콘도 표시** (이미 적용됨):

```sql
-- 리스홀드→피심플 전환 플래그 추가
UPDATE towers 
SET notes = COALESCE(notes, '') || ' [leasehold-converted]'
WHERE building_name IN ('Waikiki Beach Tower', 'Waikiki Banyan');
```

이러면 시세맵 팝업에 노란 경고 박스 자동 표시됨.

> **확장 가능**: 향후 다른 메타데이터 플래그 추가 시 `[plug-in-flag]` 형식으로 추가. 예: `[short-term-rental]`, `[under-renovation]` 등.

---

### 3-7. 데이터 검증 쿼리

#### 지역별 콘도 수 확인

```sql
SELECT neighborhood, COUNT(*) as tower_count
FROM towers
GROUP BY neighborhood
ORDER BY neighborhood;
```

기대: Ward Village 13, Waikiki 6, Ala Moana 6, Salt 6

#### 콘도별 매물 수 + 매물 있는 비율

```sql
SELECT 
  t.neighborhood,
  t.building_name, 
  COUNT(u.id) as total_units,
  COUNT(u.current_list_price) as listed_units
FROM towers t
LEFT JOIN units u ON t.id = u.tower_id
GROUP BY t.neighborhood, t.building_name
ORDER BY t.neighborhood, t.building_name;
```

#### 매물 있는 unit만 확인

```sql
SELECT t.neighborhood, t.building_name, u.unit_type, u.unit_no, 
       u.current_list_price, u.notes
FROM units u
JOIN towers t ON u.tower_id = t.id
WHERE u.current_list_price IS NOT NULL
ORDER BY t.neighborhood, t.building_name, u.current_list_price DESC;
```

#### 최근 실거래(recent_sold) unit 목록

```sql
SELECT t.building_name, u.unit_type, u.unit_no, u.current_list_price
FROM units u
JOIN towers t ON u.tower_id = t.id
WHERE u.notes = 'recent_sold'
ORDER BY t.building_name, u.unit_no;
```

#### 지역별 상승률 TOP 5

```sql
SELECT 
  t.neighborhood,
  t.building_name, u.unit_type, u.unit_no,
  u.original_price, u.current_list_price,
  ROUND(((u.current_list_price - u.original_price) / u.original_price * 100), 1) as appreciation
FROM units u
JOIN towers t ON u.tower_id = t.id
WHERE u.current_list_price IS NOT NULL 
  AND u.original_price IS NOT NULL
  AND t.neighborhood = 'Waikiki'  -- 지역 바꿔서 사용
ORDER BY appreciation DESC
LIMIT 5;
```

---

## 4. 콘도/지역 추가하기

### 4-1. 기존 지역에 콘도 추가 (예: 와이키키에 새 콘도)

#### Step 1: SQL로 콘도 + unit 추가

```sql
-- 1) towers 추가
INSERT INTO towers (neighborhood, building_name, year_completed, status, latitude, longitude, notes)
VALUES ('Waikiki', '새 콘도 이름', 2024, 'completed', 21.28xxx, -157.83xxx, '주소 등');

-- 2) units 추가
INSERT INTO units (tower_id, unit_type, unit_no, living_sqft, original_price, current_list_price, est_rent_monthly, hoa_monthly, view_type, listing_url, notes)
VALUES 
  ((SELECT id FROM towers WHERE building_name = '새 콘도 이름'), '1BR', '101', 600, 700000, 850000, 4000, 800, 'Ocean', 'https://...', NULL),
  ...
;
```

#### Step 2: build_html.py에 약자 추가

`build_html.py` 열어서 `TOWER_ABBR` 딕셔너리 마지막에 추가:

```python
TOWER_ABBR = {
    # ... 기존 30개 ...
    
    # 새 콘도
    "새 콘도 이름": "XX",  # ← 추가
}
```

#### Step 3: 빌드

```powershell
python build_data.py
python build_html.py
```

#### Step 4: GitHub 푸시

```powershell
git add .
git commit -m "feat: Waikiki에 새 콘도 추가 (XX)"
git push origin main
```

---

### 4-2. 새 지역 추가 (예: 카할라 추가)

좀 더 큰 작업. **build_html.py에 4가지 수정 필요**.

#### Step 1: SQL로 지역 + 콘도 + unit 추가

```sql
INSERT INTO towers (neighborhood, building_name, ...) VALUES
  ('Kahala', 'Kahala Beach Apartments', ...),
  ...
;
-- units도 같이
```

#### Step 2: build_html.py 4곳 수정

**(1) TOWER_ABBR에 새 콘도 약자 추가**

```python
TOWER_ABBR = {
    # ... 기존 ...
    "Kahala Beach Apartments": "KB",
    # ...
}
```

**(2) REGION_COLORS에 색 추가**

```python
REGION_COLORS = {
    "Ward Village": "#3B82F6",
    "Waikiki":      "#A855F7",
    "Ala Moana":    "#F97316",
    "Salt":         "#10B981",
    "Kahala":       "#EC4899",  # ← 추가 (핑크)
}
```

**(3) PAGES 리스트에 새 페이지 추가**

```python
PAGES = [
    # ... 기존 5개 ...
    {
        "filename": "kahala.html",
        "regions": ["Kahala"],
        "title": "카할라 시세맵",
        "subtitle": "Honolulu 럭셔리 거주 권역",
        "nav_key": "kahala",
    },
]
```

#### Step 3: 템플릿에 네비게이션 항목 추가

`templates/map_template.html.j2` 열어서 네비게이션 섹션에 추가:

```html
<a href="kahala.html" class="region-nav-item {% if current_nav == 'kahala' %}active{% endif %}">
  <span class="nav-dot" style="background: {{ region_colors['Kahala'] }};"></span>카할라
</a>
```

그리고 JavaScript의 `REGION_LABELS`에도 추가:

```javascript
const REGION_LABELS = {
  "Ward Village": "워드빌리지",
  "Waikiki": "와이키키",
  "Ala Moana": "알라모아나",
  "Salt": "솔트",
  "Kahala": "카할라"  // ← 추가
};
```

범례 영역의 `regions_order`와 `region_labels`에도 'Kahala' 추가.

#### Step 4: 빌드 + 푸시

```powershell
python build_data.py
python build_html.py
git add .
git commit -m "feat: 카할라 지역 추가 (콘도 N개)"
git push origin main
```

> **팁**: 새 지역 추가는 클로드에게 부탁하면 빠름. "build_html.py랑 템플릿에 카할라 지역 추가해줘" 한 마디로 끝.

---

## 5. 트러블슈팅

### 5-1. PowerShell 스크립트 실행 안 됨

**에러**: `cannot be loaded because running scripts is disabled`

**해결**:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

---

### 5-2. 한글 깨짐

**해결**:
```powershell
# 파일 저장 시 항상 -Encoding utf8 명시
Out-File -FilePath xxx.md -Encoding utf8

# 또는 PowerShell 콘솔 인코딩 변경 (1회)
chcp 65001
```

---

### 5-3. Supabase 연결 실패

**확인**:
1. `.env` 파일 존재 (`ls .env`)
2. `.env` 내용 (`cat .env`)
3. Supabase 대시보드에서 키 만료 안 됐는지
4. 가상환경 활성화 여부 (`(.venv)` 표시)

---

### 5-4. diff 결과가 "변경 없음"인데 실제로는 변경됨

**원인**: snapshot을 안 했거나, snapshot이 이미 최신 데이터로 덮어씌워짐

**해결**:
1. snapshot은 **데이터 수정 전**에 실행
2. 이미 덮어씌워졌다면 → snapshots/ 폴더의 이전 날짜 파일 활용:
```powershell
ls snapshots/
copy snapshots\ward_village_2026-05-14.json snapshots\latest.json
```

---

### 5-5. 시세맵에 변경 사항이 안 보임

**확인 순서**:
1. `python build_data.py` 실행했나? → JSON 파일 갱신
2. `python build_html.py` 실행했나? → 5개 HTML 파일 갱신
3. 브라우저 강력 새로고침 (Ctrl + F5) → 캐시 무시
4. GitHub Pages 캐시 → 5분 정도 더 기다리기

---

### 5-6. GitHub Pages 빌드 실패

**확인 방법**:
```
https://github.com/2gamja/ward-village-map/actions
```

여기서 "pages build and deployment" 워크플로우 빨간 X 표시 시:
1. 클릭해서 에러 메시지 확인
2. 보통 HTML 문법 오류 — `python build_html.py`가 콘솔에서 잘 돌면 보통 문제 없음

---

### 5-7. git push 실패

**케이스 A: "rejected" 에러**

원격에 다른 변경사항이 있는 경우:
```powershell
git pull origin main  # 먼저 받기
# 충돌 없으면 자동 머지됨
git push origin main
```

**케이스 B: "Author identity unknown"**

이메일/이름 설정 누락:
```powershell
git config --global user.name "2gamja"
git config --global user.email "본인이메일"
```

---

### 5-8. 새로 추가한 콘도가 마커에 "??"로 표시됨

**원인**: `build_html.py`의 `TOWER_ABBR` 딕셔너리에 약자 추가 안 됨

**해결**: build_html.py 열어서 TOWER_ABBR에 새 콘도 추가 → 재빌드

---

### 5-9. ONE Ala Moana 같은 콘도 좌표 잘못 입력

가장 흔한 실수: **경도 부호 빠짐**. 호놀룰루는 서경이라 음수(-157.xxx)여야 함.

**확인**:
```sql
SELECT building_name, latitude, longitude FROM towers
WHERE longitude > 0 OR latitude < 21 OR latitude > 22;
```

문제 있는 row가 있으면:
```sql
UPDATE towers SET longitude = -157.8410435 WHERE building_name = 'ONE Ala Moana';
```

---

### 5-10. 가상환경 활성화 안 됨

**증상**: 프롬프트에 `(.venv)` 표시 없음

**해결**:
```powershell
cd C:\Users\LG\Desktop\ward-village-map
.venv\Scripts\Activate.ps1
```

여전히 안 되면 가상환경 재생성:
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## 6. 시스템 구조 이해

### 데이터 흐름

```
[외부 데이터 출처]
  Zillow, Hawaii Life, Redfin, Honolulu Real Property
        ↓ (도님이 매주 수동 수집)
        
[Supabase PostgreSQL]
  towers (31개)  ←→  units (가변)
  - neighborhood (지역 구분)
  - notes (메타 플래그)
        ↓ (build_data.py)
        
[ward_village_data.json]
  파생값 계산 + 의미적 정렬
        ↓ (build_html.py)
        
[5개 HTML 파일]
  index.html (전체)
  ward-village.html, waikiki.html, ala-moana.html, salt.html
        ↓ (git push)
        
[GitHub Pages]
  https://2gamja.github.io/ward-village-map/
```

### 데이터베이스 스키마

#### towers 테이블

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | INT (PK) | 자동 증가 |
| neighborhood | TEXT | 지역 (Ward Village/Waikiki/Ala Moana/Salt) |
| building_name | TEXT | 콘도 이름 |
| year_completed | INT | 완공/예정 연도 |
| status | TEXT | "completed" 또는 "under_construction" |
| latitude | NUMERIC | 위도 (21.x) |
| longitude | NUMERIC | 경도 (-157.x, 음수!) |
| notes | TEXT | 메타 정보 + 플래그 (`[leasehold-converted]` 등) |

#### units 테이블

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | INT (PK) | 자동 증가 |
| tower_id | INT (FK) | towers.id 참조 |
| unit_type | TEXT | "Studio", "1BR", "2BR", "3BR(PH)" 등 |
| unit_no | TEXT | 호수 |
| living_sqft | INT | 면적 |
| original_price | NUMERIC | 분양가 |
| current_list_price | NUMERIC | 현재 매물가 (NULL 가능) |
| est_rent_monthly | NUMERIC | 추정 임대료 (NULL 가능) |
| hoa_monthly | NUMERIC | 관리비 |
| view_type | TEXT | "Ocean", "Mountain", "City" 등 |
| listing_url | TEXT | 매물 링크 |
| notes | TEXT | unit 플래그 ("recent_sold" 등) |

### 시각 시스템 (v2)

**지역별 마커 색상**:
- 🔵 워드빌리지: `#3B82F6` 블루
- 🟣 와이키키: `#A855F7` 퍼플
- 🟠 알라모아나: `#F97316` 오렌지
- 🟢 솔트: `#10B981` 그린

**마커 상태**:
- 완공: 단색 + 실선 테두리
- 완공 예정: 같은 색 + 점선 테두리 + 70% 투명도

**팝업 메타 정보**:
- 상단 색 뱃지 = 지역
- 노란 경고 박스 = `notes` 플래그 (예: leasehold-converted)
- "최근 실거래" 배지 = unit notes='recent_sold'

---

## 7. 향후 개선 아이디어

### 단기 (1-2주)
- [ ] 지역별 페이지에 그 지역 특화 인사이트 추가
  - 와이키키: condotel vs 거주형 비교, NUC 단기임대 분석
  - 알라모아나: 디벨로퍼별 시세 비교 (Kobayashi Group: Hokua → ONE → Park Lane)
  - 솔트: Increment I vs II 비교
- [ ] 헤더에 평균 상승률/수익률 외에 평당가 추가

### 중기 (1-3개월)
- [ ] RapidAPI Zillow 무료 티어 PoC
  - 31개 콘도 자동 조회 가능 여부 확인
  - 운영비 vs 절약 시간 비교
- [ ] 매물 이력 추적
  - 가격 변동 그래프 (Chart.js)
  - 콘도별 시계열 데이터
- [ ] 알림 시스템 (큰 변동 시 Slack/이메일)

### 장기 (3-6개월)
- [ ] 새 지역 추가 (카할라, 다이아몬드 헤드 등)
- [ ] AI 기반 가격 예측
- [ ] 사용자 계정 (즐겨찾기, 알림 설정)

---

## 8. FAQ

**Q. 매주 갱신 안 하면 어떻게 되나?**
A. 데이터가 오래됨. 시세맵 우측 하단 면책 박스에 "마지막 데이터 갱신" 날짜로 확인.

**Q. 어떤 unit을 "최근 실거래" 처리하고, 어떤 unit을 NULL 처리하는지 헷갈려.**
A. 간단한 기준:
- **3BR 이상** + **$2M 이상** = 최근 실거래 (notes='recent_sold')
- **나머지 다** = NULL 처리

**Q. unit이 그냥 사라져서 매물 검색 안 되는데, 거래된 건지 아닌지 모르겠어.**
A. Honolulu Real Property에서 거래 이력 확인. 거래 안 됐으면 매물 회수일 가능성 → NULL 처리. 거래됐으면 → recent_sold 처리.

**Q. Supabase 무료 티어 한계는?**
A. 500MB DB, 1GB 파일 저장. 31개 콘도 / 200~300 unit 규모로는 무한정 OK.

**Q. 시세맵을 다른 사람과 공유하려면?**
A. GitHub Pages URL 공유. 라이브 URL은 늘 최신 데이터.

**Q. 데이터를 백업하려면?**
A. Supabase 대시보드 → Database → Backups 메뉴. 또는 `snapshots/` 폴더의 JSON 파일이 자동 이력.

**Q. 새 콘도/지역을 추가하려면?**
A. [4번 섹션](#4-콘도지역-추가하기) 참조. 콘도 추가는 SQL + TOWER_ABBR 추가, 지역 추가는 build_html.py 4곳 수정.

**Q. weekly_update.ps1이 5개 HTML 다 빌드해주나?**
A. YES. v2부터 `build_html.py`가 자동으로 5개 다 빌드함. weekly_update.ps1은 그대로 사용.

**Q. 5개 페이지 다 갱신 안 되고 일부만 갱신되는 경우?**
A. `build_html.py` 콘솔 출력 확인. "✅ 5개 페이지 빌드 완료" 메시지 봤는지. 안 나오면 다시 실행.

**Q. 토지 소유권(fee simple vs leasehold) 차이 어떻게 표시?**
A. 콘도 레벨에서 처리. `towers.notes`에 `[leasehold-converted]` 플래그 추가 → 팝업에 자동 경고 박스.

---

## 9. 매주 체크리스트

매주 작업 시 이 체크리스트 따라가면 끝.

```
□ 1. 가상환경 활성화
   cd C:\Users\LG\Desktop\ward-village-map
   .venv\Scripts\Activate.ps1

□ 2. 스냅샷 저장
   python snapshot_data.py

□ 3. Zillow Saved Search 알림 확인
   - 워드빌리지 (13개)
   - 와이키키 (6개)
   - 알라모아나 (6개)
   - 솔트 (3개 완공)

□ 4. Supabase SQL Editor에서 데이터 업데이트
   변경 사항:
   □ 매물가 변경
   □ 신규 매물 등록
   □ 매물 사라짐 — 일반 매물 (NULL 처리)
   □ 매물 사라짐 — 럭셔리 3BR+ $2M+ (recent_sold 처리)

□ 5. 빌드 실행
   .\weekly_update.ps1

□ 6. diff 출력 확인
   변경 건수 콘솔에서 확인

□ 7. 로컬 시세맵 확인
   index.html 브라우저로 열어서 갱신 확인
   ward-village.html, waikiki.html, ala-moana.html, salt.html도 한 번씩

□ 8. GitHub 푸시
   git add .
   git commit -m "weekly update YYYY-MM-DD"
   git push origin main

□ 9. 라이브 URL 확인 (2분 후)
   https://2gamja.github.io/ward-village-map/
```

---

## 부록: 운영 데이터 (2026-05-24 기준)

### 지역별 콘도 수

| 지역 | 콘도 수 | unit 수 | 마커 색 |
|---|---|---|---|
| 워드빌리지 | 13 | 58 | 🔵 블루 |
| 와이키키 | 6 | 26 | 🟣 퍼플 |
| 알라모아나 | 6 | 31 | 🟠 오렌지 |
| 솔트 | 6 (3 완공 + 3 분양 중) | 18 | 🟢 그린 |
| **합계** | **31** | **133** | |

### 콘도별 약자 (TOWER_ABBR)

**워드빌리지 (13)**:
Waiea(Wa), Anaha(An), Ae'o(Ae), Ke Kilohana(Ke), 'A'ali'i(Aa), Ko'ula(Ko), Victoria Place(VP), Ulana(Ul), The Park Ward Village(Pa), Kalae(Ka), The Launiu(La), 'Ilima(Il), Melia(Me)

**와이키키 (6)**:
Ritz-Carlton Residences(RC), Ka Lai(KL), Waikiki Beach Tower(WBT), Allure(AL), The Watermark(WM), Waikiki Banyan(WB)

**알라모아나 (6)**:
Park Lane(PL), ONE Ala Moana(ONE), Hokua(HK), Azure(AZ), Sky Ala Moana(SKY), Kapiolani Residence(KR)

**솔트 (6)**:
The Collection(TC), Keauhou Place(KP), Symphony Honolulu(SY), Alia(AA), Kaliu(KU), Kahuina(KH)

### 라이브 URL

```
https://2gamja.github.io/ward-village-map/                    ← 전체 (메인)
https://2gamja.github.io/ward-village-map/ward-village.html
https://2gamja.github.io/ward-village-map/waikiki.html
https://2gamja.github.io/ward-village-map/ala-moana.html
https://2gamja.github.io/ward-village-map/salt.html
```

### 기타 URL

- GitHub 리포: https://github.com/2gamja/ward-village-map
- GitHub Actions (빌드 상태): https://github.com/2gamja/ward-village-map/actions
- Supabase 대시보드: https://supabase.com/dashboard

---

*작성일: 2026-05-24*
*마지막 업데이트: 2026-05-24 / v2 (4지역 통합 시스템)*
