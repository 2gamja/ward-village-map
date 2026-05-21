# Ward Village 시세맵 (Honolulu Kakaako)

호놀룰루 Ward Village 마스터플랜 커뮤니티의 콘도 시세를 자동 추적/시각화하는 시스템.

## 무엇을 하는가

- **13개 콘도** (완공 9 + 완공 예정 4)의 매물 정보 추적
- **58개 매물**의 분양가 / 매물가 / 임대료 추정치 관리
- **상승률** (분양가 대비 매물가)과 **임대수익률** 자동 계산
- **인터랙티브 시세맵** HTML로 시각화

## 화면

- **상승률 탭**: 분양가 대비 현재 매물가 상승률 (양수 녹색, 음수 빨강)
- **임대수익률 탭**: 매물가 대비 추정 임대료 수익률 (5%+ 진녹, 3-5% 연녹, 3%- 회색)
- **콘도 마커**: 약자 + 색상으로 완공/완공 예정 구분
- **모바일 반응형**: 768px 이하 자동 적응

## 기술 스택

| 영역 | 기술 |
|---|---|
| 데이터베이스 | Supabase (PostgreSQL) |
| 백엔드 빌드 | Python 3.11 + supabase-py |
| 템플릿 | Jinja2 |
| 지도 | Leaflet.js + OpenStreetMap |
| 호스팅 | GitHub Pages (예정) |

## 데이터 출처

- **분양가**: 호놀룰루시 공식 등기 정보 (Honolulu Real Property)
- **매물가**: Zillow, Hawaii Life 등 공개 매물 정보
- **임대료**: Zillow Rent Estimate 등 시장 추정치
- **좌표**: Howard Hughes 공식 지도 기반 매핑

## 빠른 시작

### 1. 프로젝트 클론

git clone <repository>
cd ward-village-map

### 2. 가상환경 + 라이브러리 설치

python -m venv .venv
.venv\Scripts\Activate.ps1
pip install -r requirements.txt

### 3. 환경 변수 설정

`.env` 파일 생성 후:
SUPABASE_URL=https://[your-project].supabase.co
SUPABASE_KEY=sb_publishable_xxx

### 4. 빌드 실행

python build_data.py
python build_html.py

### 5. 결과 확인

`output/index.html`을 브라우저로 열기.

## 폴더 구조

ward-village-map/
├── .venv/                       # Python 가상환경
├── .env                         # Supabase 비밀 키
├── .gitignore                   # Git 제외 규칙
├── requirements.txt             # Python 라이브러리 목록
├── build_data.py                # Supabase → JSON 빌드
├── build_html.py                # JSON → HTML 빌드
├── ward_village_data.json       # 빌드 결과 데이터
├── templates/
│   └── map_template.html.j2     # Jinja2 시세맵 템플릿
└── output/
└── index.html               # 최종 시세맵 HTML

## 운영 가이드

매주 데이터 갱신 흐름 등 상세 내용은 OPERATIONS.md 참조.

## 면책

본 시세맵은 비공식 자료로 **투자 참고용**입니다. 실거래 시 반드시 공식 매물 정보 및 전문가 자문을 받으시기 바랍니다. 임대료는 시장 추정치이며 실거래와 다를 수 있습니다.

## 개발 일정

- Day 1-2: Supabase 셋업 + 데이터 입력
- Day 3: Python 빌드 파이프라인
- Day 4: HTML 시세맵 + 지도 + 팝업
- Day 5: 디자인 정밀화 + 모바일 대응
- Day 9: GitHub Pages 배포 예정

