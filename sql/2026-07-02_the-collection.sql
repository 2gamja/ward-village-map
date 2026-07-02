-- ============================================================
-- 2026-07-02  The Collection (600 Ala Moana Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow The Collection Active (S301 37sqft $58k 스토리지 제외)
--
--   1BR (5건): 3304 $815k / 3604 $775k / 508 $775k / 1203 $745k / 1304 $739k
--     · 2nd 최고가 = $775k 동률(3604, 508)
--     · 기존 rep 3604가 동률 그룹 안에 있으므로 rep 유지 (교체 없음)
--     · 508만 비활성 (동률 뒷순위 정리)
--
--   2BR (4건): 2502 $1.399M / 2009 $1.250M / 1105 $1.099M / 1906 $1.095M
--     · 2nd 최고가 = 2009 [신규 rep]
--     · 기존 rep 2402·2806은 Zillow 리스트에서 사라짐 → 비활성
--
--   3BR (1건): 3301 $1.475M
--     · 유일 활성 → 자동 rep [신규]
--     · 기존 rep 2801은 Zillow 리스트에서 사라짐 → 비활성
--
-- 대표 변동 요약:
--   1BR : 3604 유지 ($775k, 580sqft)
--   2BR : 2402 → 2009 ($1,250,000, 959sqft)
--   3BR : 2801 → 3301 ($1,475,000, 1133sqft)
--
-- 분양가/임대 (도 조사값):
--   2009: original $720,063 / rent $4,568
--   3301: original $995,576 / rent $5,202
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (2BR 2009, 3BR 3301) ──────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'The Collection'),
   '2BR', '2009', 959, 720063, 1250000, 4568,
   NULL, 'Ocean', NULL, '2bd 2ba', true, CURRENT_DATE, CURRENT_DATE),
  ((SELECT id FROM towers WHERE building_name = 'The Collection'),
   '3BR', '3301', 1133, 995576, 1475000, 5202,
   NULL, 'Ocean', NULL, '3bd 2ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 1BR 508 비활성 ($775k 동률 뒷순위, 3604 rep 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '508'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Collection');

-- ── 3) 기존 2BR 대표 2402 비활성 (시장에서 내려감) ────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2402'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Collection');

-- ── 4) 기존 2BR 활성 2806 비활성 (시장에서 내려감) ────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2806'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Collection');

-- ── 5) 기존 3BR 대표 2801 비활성 (시장에서 내려감) ────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2801'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Collection');

-- ── 6) 점검: The Collection 타입별 상태 ───────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'The Collection')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 7) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'The Collection')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
