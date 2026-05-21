# Ward Village 시세맵 — 운영 매뉴얼

> 이 문서는 매주 시세맵을 운영하는 흐름을 정리한 가이드입니다.
> 한 달 후, 6개월 후의 본인도 헷갈리지 않게.

---

## 목차

1. [주간 운영 흐름](#1-주간-운영-흐름)
2. [SQL 자주 쓰는 패턴](#2-sql-자주-쓰는-패턴)
3. [Python 빌드 흐름](#3-python-빌드-흐름)
4. [트러블슈팅](#4-트러블슈팅)
5. [시스템 구조 이해](#5-시스템-구조-이해)
6. [향후 개선 아이디어](#6-향후-개선-아이디어)

---

## 1. 주간 운영 흐름

### 전체 흐름 (약 15-20분)

[매주 월요일 또는 정한 요일]① 변경 정보 수집 (5-10분)

Zillow Saved Search 알림 확인
또는 콘도별 페이지 방문
② 작업 시작 — 백업 (5초)
python snapshot_data.py③ 데이터 입력 (10-15분)

Supabase SQL Editor에서 UPDATE/INSERT
④ 자동 빌드 + 변경 확인 (30초)
.\weekly_update.ps1⑤ 결과 확인 (1분)

콘솔에서 변경 사항 확인
브라우저에서 시세맵 새로고침

### 단계별 상세

#### ① 변경 정보 수집

매주 모니터링할 데이터 출처:

| 데이터 | 출처 | 주기 |
|---|---|---|
| 매물가 변동 | Zillow Saved Search 알림 | 매주 |
| 신규 매물 | Zillow, Hawaii Life | 매주 |
| 분양가 등록 | Honolulu Real Property | 신규 콘도 분양 시 |
| 임대료 추정치 | Zillow Rent Estimate | 매월 |

Zillow Saved Search 설정:
- Zillow.com 가입 → 각 콘도 검색 → Save Search
- 변경 시 이메일 알림 받기
- 13개 콘도 각각 설정 (1회만)

#### ② 작업 시작 — 스냅샷 저장

작업 시작 전 반드시 이거 먼저:

```powershell
cd C:\Users\External\Desktop\ward-village-map
.venv\Scripts\Activate.ps1
python snapshot_data.py
```

`snapshots/` 폴더에 두 파일 생성:
- `ward_village_YYYY-MM-DD.json` — 영구 보관 (이력)
- `latest.json` — diff 도구가 사용

**스냅샷 안 하면**: diff 도구가 이번 주 vs 이번 주 비교 → 변경 없음으로 나옴.

#### ③ 데이터 입력 — Supabase

Supabase 대시보드 → SQL Editor에서 변경 사항 입력.

자주 쓰는 SQL 패턴은 [2번 섹션](#2-sql-자주-쓰는-패턴) 참조.

#### ④ 자동 빌드

```powershell
.\weekly_update.ps1
```

3단계 자동 실행:
1. `build_data.py` — Supabase → JSON
2. `diff_data.py` — 변경 사항 출력
3. `build_html.py` — JSON → HTML 시세맵

#### ⑤ 결과 확인

콘솔의 diff 출력 확인:
📈 가격 상승 (N건):
📉 가격 하락 (N건):
🆕 신규 매물 (N건):
❌ 매물 사라짐 (N건):

브라우저로 `output/index.html` 새로고침 → 시세맵 화면에 반영됐는지 확인.

---

## 2. SQL 자주 쓰는 패턴

### 2-1. 매물가 변경 (가장 자주 씀)

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

### 2-2. 매물 사라짐 (거래 완료 추정)

```sql
-- 매물가를 NULL로 변경 → 시세맵에 "매물 없음" 표시
UPDATE units 
SET current_list_price = NULL 
WHERE unit_no = '2810' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');
```

### 2-3. 신규 매물 등록

```sql
-- 기존 unit이 다시 매물로 나옴
UPDATE units 
SET current_list_price = 695000,
    listing_url = 'https://zillow.com/...'
WHERE unit_no = '1102' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Anaha');

-- 또는 완전 신규 unit 추가
INSERT INTO units (tower_id, unit_type, unit_no, living_sqft, original_price, current_list_price, est_rent_monthly)
VALUES (
  (SELECT id FROM towers WHERE building_name = 'Anaha'),
  '1BR', '1102', 538, 530000, 695000, 4200
);
```

### 2-4. 임대료 업데이트

```sql
-- Zillow Rent Estimate 갱신
UPDATE units 
SET est_rent_monthly = 4500
WHERE unit_no = '507' 
  AND tower_id = (SELECT id FROM towers WHERE building_name = 'Anaha');
```

### 2-5. 데이터 검증 쿼리

```sql
-- 콘도별 매물 수 확인
SELECT t.building_name, COUNT(u.id) as unit_count
FROM towers t
LEFT JOIN units u ON t.id = u.tower_id
GROUP BY t.building_name
ORDER BY t.year_completed;

-- 매물가 있는 unit만 확인
SELECT t.building_name, u.unit_type, u.unit_no, u.current_list_price
FROM units u
JOIN towers t ON u.tower_id = t.id
WHERE u.current_list_price IS NOT NULL
ORDER BY t.year_completed, u.current_list_price DESC;

-- 상승률 TOP 5 계산
SELECT 
  t.building_name, u.unit_type, u.unit_no,
  u.original_price, u.current_list_price,
  ROUND(((u.current_list_price - u.original_price) / u.original_price * 100), 1) as appreciation
FROM units u
JOIN towers t ON u.tower_id = t.id
WHERE u.current_list_price IS NOT NULL AND u.original_price IS NOT NULL
ORDER BY appreciation DESC
LIMIT 5;
```

---

## 3. Python 빌드 흐름

### 빌드 시스템 구조

[Supabase DB]
↓ (build_data.py)
[ward_village_data.json]
↓ (build_html.py)
[output/index.html]
↓
[브라우저에서 시각화]

### 각 스크립트의 역할

| 파일 | 역할 | 실행 시점 |
|---|---|---|
| `snapshot_data.py` | 현재 데이터를 지난주 스냅샷으로 저장 | 주간 작업 **시작 전** |
| `build_data.py` | Supabase → JSON 변환 + 파생값 계산 | 데이터 수정 후 |
| `diff_data.py` | 지난주 vs 이번주 비교 | build_data.py 다음 |
| `build_html.py` | JSON → 시세맵 HTML | diff 확인 후 |
| `weekly_update.ps1` | 위 3개 한 번에 실행 | 매주 |

### 빌드 결과 파일

| 파일 | 위치 | 설명 |
|---|---|---|
| `ward_village_data.json` | 루트 | 빌드된 데이터 (Git 추적 X) |
| `output/index.html` | output/ | 최종 시세맵 |
| `snapshots/latest.json` | snapshots/ | 지난주 스냅샷 |
| `snapshots/ward_village_*.json` | snapshots/ | 날짜별 영구 보관 |

### Python 스크립트 개별 실행 (필요 시)

```powershell
# 데이터만 다시 가져오기
python build_data.py

# diff만 다시 확인
python diff_data.py

# HTML만 다시 빌드
python build_html.py
```

---

## 4. 트러블슈팅

### 4-1. PowerShell 스크립트 실행 안 됨

**에러**: `cannot be loaded because running scripts is disabled`

**원인**: Windows 보안 정책

**해결**:
```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```
Y 입력. 1회만 실행.

### 4-2. 한글 깨짐

**증상**: 콘솔/파일에서 한글이 ??? 또는 ё로 표시

**원인**: 인코딩 문제 (cp949 vs UTF-8)

**해결**:
```powershell
# 파일 저장 시 항상 -Encoding utf8 명시
Out-File -FilePath xxx.md -Encoding utf8

# 또는 PowerShell 콘솔 인코딩 변경 (1회)
chcp 65001
```

### 4-3. Supabase 연결 실패

**에러**: `Could not authenticate user` 또는 `Connection refused`

**확인 사항**:
1. `.env` 파일 존재 여부
```powershell
   ls .env
```
2. `.env` 내용 (실제 키 값 들어있는지)
```powershell
   cat .env
```
3. Supabase 대시보드에서 키 만료 안 됐는지
4. 가상환경 활성화 여부 (`(.venv)` 표시)

### 4-4. diff 결과가 "변경 없음"인데 실제로는 변경됨

**원인**: snapshot을 안 했거나, snapshot이 이미 최신 데이터로 덮어씌워짐

**해결**:
1. snapshot은 **데이터 수정 전**에 실행
2. 수정 후 snapshot 하면 비교 대상이 없어짐
3. 이미 그랬다면 → snapshots/ 폴더의 이전 날짜 파일 확인
```powershell
   ls snapshots/
```
4. 필요 시 이전 날짜 파일을 latest.json으로 복사
```powershell
   copy snapshots\ward_village_2026-05-14.json snapshots\latest.json
```

### 4-5. 시세맵에 변경 사항이 안 보임

**증상**: SQL 수정했는데 브라우저에서 그대로

**확인 순서**:
1. `python build_data.py` 실행했나?
   → JSON 파일 갱신
2. `python build_html.py` 실행했나?
   → HTML 파일 갱신
3. 브라우저 강력 새로고침 (Ctrl + F5)
   → 캐시 무시하고 새로 로드

### 4-6. 가상환경 활성화 안 됨

**증상**: PowerShell 프롬프트에 `(.venv)` 표시 없음

**해결**:
```powershell
cd C:\Users\External\Desktop\ward-village-map
.venv\Scripts\Activate.ps1
```

여전히 안 되면 가상환경 재생성:
```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

---

## 5. 시스템 구조 이해

### 데이터 흐름 다이어그램

┌─────────────────────────────────────────┐
│           외부 데이터 출처               │
│                                         │
│  Zillow │ Hawaii Life │ Honolulu Real   │
│   매물   │   매물      │ Property (등기) │
└────────────┬────────────────────────────┘
│
↓ (도님이 매주 수동 수집)
│
┌────────────▼────────────────────────────┐
│          Supabase (PostgreSQL)          │
│                                         │
│  towers  ←─→  units                     │
│  (13개)       (58개 unit, 가변)         │
└────────────┬────────────────────────────┘
│
↓ (build_data.py)
│
┌────────────▼────────────────────────────┐
│       ward_village_data.json            │
│                                         │
│  - 모든 콘도 + 매물 데이터              │
│  - 파생값 계산됨 (상승률, 수익률 등)    │
│  - 의미적 정렬 (Studio→1BR→2BR→3BR)    │
└────────────┬────────────────────────────┘
│
↓ (build_html.py)
│
┌────────────▼────────────────────────────┐
│         output/index.html               │
│                                         │
│  - Leaflet 지도                         │
│  - 13개 마커 + 팝업                     │
│  - 상승률/임대수익률 탭                 │
│  - 모바일 반응형                        │
└─────────────────────────────────────────┘

### 데이터베이스 스키마

#### towers 테이블 (콘도 정보)

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | INT (PK) | 자동 증가 |
| building_name | TEXT | 콘도 이름 (예: "Anaha") |
| year_completed | INT | 완공/예정 연도 |
| status | TEXT | "completed" 또는 "under_construction" |
| latitude | NUMERIC | 위도 |
| longitude | NUMERIC | 경도 |
| notes | TEXT | 메모 (선택) |

#### units 테이블 (매물 정보)

| 컬럼 | 타입 | 설명 |
|---|---|---|
| id | INT (PK) | 자동 증가 |
| tower_id | INT (FK) | towers.id 참조 |
| unit_type | TEXT | "Studio", "1BR", "2BR" 등 |
| unit_no | TEXT | 호수 (예: "507") |
| living_sqft | INT | 면적 (sqft) |
| original_price | NUMERIC | 분양가 |
| current_list_price | NUMERIC | 현재 매물가 (NULL 가능) |
| est_rent_monthly | NUMERIC | 추정 임대료 (NULL 가능) |
| listing_url | TEXT | 매물 링크 (선택) |

### 파생값 계산 로직

`build_data.py`에서 계산:

| 파생값 | 공식 |
|---|---|
| 상승률 (%) | (현재 매물가 - 분양가) / 분양가 × 100 |
| 자본 이득 ($) | 현재 매물가 - 분양가 |
| 평당 가격 ($/sqft) | 현재 매물가 / 면적 |
| 임대수익률 (%, gross) | 임대료 × 12 / 매물가 × 100 |

NULL이 하나라도 있으면 결과는 NULL.

---

## 6. 향후 개선 아이디어

### 단기 (1-2주)

- [ ] GitHub Pages 배포 → 스터디원과 공유
- [ ] 필터링 기능 (완공/완공 예정, 가격대)
- [ ] 헤더에 시장 요약 (평균 상승률, 평균 수익률)

### 중기 (1-3개월)

- [ ] RapidAPI Zillow 무료 티어 PoC
  - 13개 콘도 자동 조회 가능 여부 확인
  - 운영비 대비 시간 절약 가늠
- [ ] 매물 이력 추적
  - 가격 변동 그래프 (Chart.js 등)
  - 콘도별 시계열 데이터
- [ ] 알림 시스템
  - 큰 변동 시 Slack/이메일

### 장기 (3-6개월)

- [ ] 다른 지역 확장 (NY, Gangnam 등)
- [ ] AI 기반 예측 (가격 추세 분석)
- [ ] 사용자 계정 (즐겨찾기, 알림 설정)

---

## 부록: 자주 묻는 질문

**Q. 매주 갱신 안 하면 어떻게 되나?**  
A. 데이터가 오래됨. 시세맵 우측 하단 면책 박스에 "마지막 데이터 갱신" 날짜로 알 수 있음.

**Q. Supabase 무료 티어 한계는?**  
A. 500MB DB, 1GB 파일 저장, 50,000 monthly active users. 도님 시세맵 규모로는 무한정 OK.

**Q. 시세맵을 다른 사람과 공유하려면?**  
A. GitHub Pages 배포 (Day 9 작업). 그 전엔 output/index.html 파일을 카톡 등으로 공유 가능 (단, 상대방 PC에서 열어야 함).

**Q. 데이터를 백업하려면?**  
A. Supabase 대시보드 → Database → Backups 메뉴에서 다운로드. 또는 snapshots/ 폴더의 JSON 파일이 자동 이력.

**Q. 새 콘도를 추가하려면?**  
A. towers 테이블에 INSERT → units도 INSERT. 그 다음 build_data.py 실행. 좌표는 Howard Hughes 공식 지도 + Google Maps로 확인 필요.

---

*마지막 업데이트: 2026-05-21*  
*Day 5 — 디자인 정밀화 + 운영 도구 + 운영 매뉴얼 작성*
