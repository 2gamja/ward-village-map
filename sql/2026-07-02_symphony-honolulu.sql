-- ============================================================
-- 2026-07-02  Symphony Honolulu (888 Kapiolani Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Symphony Honolulu Active 11건
--
--   1BR (3건, 672sqft): 2001 $805k / 4312 $860k / 4101 $888,888
--     · 2nd 최고가 = 4312 [신규 rep]
--     · 기존 rep 2001은 최저가 → rep 자격 상실 → 비활성
--
--   2BR (3건, PH 제외): 3207 $1.2M / 3907 $1.25M / 2703 $1.28M
--     · 2nd 최고가 = 2703 (기존 rep 유지)
--     · 4505는 DB에서 2BR(PH)로 별도 분류 → 2BR 계산서 제외
--
--   2BR(PH) 4505 $1.4M: 유일 활성 → 기존 rep 유지 (가격 동일, 변경 없음)
--
--   3BR (4건): 1705 $1.549M / 3009 $1.688M / 3505 $1.865M / 3805 $1.88M
--     · 2nd 최고가 = 3505 (기존 rep 유지)
--     · 기존 rep 1709는 Zillow에서 사라짐 (1705는 다른 유닛) → 비활성
--
--   PH: DB row NULL·비활성 → 변경 없음
--
-- 대표 변동 요약:
--   1BR     : 2001 → 4312 ($584,800 / $860,000 / $3,400)
--   2BR     : 2703 유지
--   2BR(PH) : 4505 유지 (변경 없음)
--   3BR     : 3505 유지, 1709 비활성
--
-- 분양가/임대 (도 조사값):
--   4312: original $584,800 / rent $3,400
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR 4312) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Symphony Honolulu'),
   '1BR', '4312', 672, 584800, 860000, 3400,
   NULL, 'City', NULL, '1bd 1ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 1BR 2001 비활성 (최저가라 rep 자격 상실) ───────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2001'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Symphony Honolulu');

-- ── 3) 3BR 1709 비활성 (Zillow에서 사라짐) ────────────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '1709'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Symphony Honolulu');

-- ── 4) 점검: Symphony Honolulu 타입별 상태 ────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Symphony Honolulu')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 5) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Symphony Honolulu')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
