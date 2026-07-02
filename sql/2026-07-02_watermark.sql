-- ============================================================
-- 2026-07-02  The Watermark (1551 Ala Wai Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow The Watermark, For Sale 3건 (전부 2BR)
--   2BR : 401 $1.079M / 2803 $1.499M / 3104 $1.52M → 2nd = 2803
--
-- 대표 변동 요약:
--   2BR : 401 ($1.079M) → 2803 ($1,499,000, 1113sqft) [신규]
--
-- 분양가 출처: 도 조사값
--   2803: original $1,218,590 / rent $5,200
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (2BR 2803) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'The Watermark'),
   '2BR', '2803', 1113, 1218590, 1499000, 5200,
   NULL, 'Ocean', NULL, '2bd 2ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 2BR 대표 401 비활성 (여전히 활성 매물이지만 최저가라 rep 아님) ─
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '401'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Watermark');

-- ── 3) 점검: Watermark 타입별 상태 ────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'The Watermark')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 4) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'The Watermark')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
