-- ============================================================
-- 2026-06-24  Ke Kilohana (988 Halekauwila St) 주간 업데이트
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 1BR/2BR/3BR 모두 단일 타입(사이즈 촘촘, 쪼개기 불필요)
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 대표 INSERT (1BR / 2BR / 3BR) ─────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Ke Kilohana'),
   '1BR', '4001', 511, 441746, 549000, 3269,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ke Kilohana'),
   '2BR', '3111', 740, 489289, 660000, 3791,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ke Kilohana'),
   '3BR', '2504', 995, 523274, 775000, 4710,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 직전 대표 비활성화 (가격·임대 보존) ────────────────
--    1BR 1712 / 2BR 3907 / 3BR 3507
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no IN ('1712', '3907', '3507')
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ke Kilohana');

-- ── 3) 점검: Ke Kilohana 활성 대표 ────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ke Kilohana')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 4) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ke Kilohana')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
