-- ============================================================
-- 2026-07-03  Kapiolani Residence (1631 Kapiolani Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Kapiolani Residence For-sale (2026-07-03 캡처, 4건)
--
--   1BR (1건): 3403 $703k
--     · 유일 활성 → rep = 3403 [신규 rep]
--     · 기존 rep 3603은 Zillow 리스트에서 사라짐 → 비활성
--
--   2BR (2건): 2907 $898k / 4201 $880k
--     · 2nd 최고가 = 4201 [신규 rep — 이전엔 DB에 활성 2BR 없었음]
--
--   3BR (1건): 4106 $1.2M
--     · 유일 활성 → 기존 rep 유지, $1.2M 동일 → last_seen만
--
-- 대표 변동 요약:
--   1BR : 3603 → 3403 ($703,000, 696sqft) [교체]
--   2BR : — → 4201 ($880,000, 892sqft, 2ba) [신규 활성]
--   3BR : 4106 유지 ($1,200,000, 1236sqft)
--
-- 분양가/임대 (도 조사값):
--   3403: original $506,500 / rent $3,452
--   4201: original $744,000 / rent $4,245
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR 3403, 2BR 4201) ──────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Kapiolani Residence'),
   '1BR', '3403', 696, 506500, 703000, 3452,
   NULL, 'City', NULL, '1bd 1ba', true, CURRENT_DATE, CURRENT_DATE),
  ((SELECT id FROM towers WHERE building_name = 'Kapiolani Residence'),
   '2BR', '4201', 892, 744000, 880000, 4245,
   NULL, 'City', NULL, '2bd 2ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 1BR rep 3603 비활성 (Zillow에서 사라짐) ───────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3603'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Kapiolani Residence');

-- ── 3) 기존 3BR rep 4106 last_seen 갱신 (rep 유지, $1.2M 동일) ──
UPDATE units
   SET last_seen = CURRENT_DATE
 WHERE unit_no = '4106'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Kapiolani Residence');

-- ── 4) 점검: Kapiolani Residence 타입별 상태 ──────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Kapiolani Residence')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 5) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Kapiolani Residence')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
