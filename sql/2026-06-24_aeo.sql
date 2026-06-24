-- ============================================================
-- 2026-06-24  Ae'o (1001 Queen St) 주간 업데이트
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 제외: S2-14(31sqft·$25k), S5-16(165sqft·$85k) — 창고/주차형 비거주
-- 2BR 쪼개기: 2BR(소형 867sqft) / 2BR(대형 937~985sqft) 분리
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 0) Ae'o tower_id 확인용 (선택) ─────────────────────────
-- SELECT id, building_name FROM towers WHERE building_name = 'Ae''o';

-- ── 1) 신규 대표 INSERT (Studio / 1BR / 2BR소형 / PH) ──────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Ae''o'),
   'Studio', '1407', 416, 627850, 588000, 2867,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ae''o'),
   '1BR', '908', 653, 879150, 854000, 3843,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ae''o'),
   '2BR', '2415', 867, 1054000, 1040000, 4690,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ae''o'),
   'PH', '3915', 850, 1250000, 1399900, 5695,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 2BR 대표(2604)를 "2BR(대형)"으로 리네임 + 갱신 ──
--    (Ae'o 비활성 2BR 행 없음 → 유령 직전호가 위험 없음)
UPDATE units
   SET unit_type = '2BR(대형)',
       current_list_price = 1350000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '2604'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o');

-- ── 3) 변동 없는 대표 last_seen 갱신 (3BR 1900) ────────────
UPDATE units
   SET current_list_price = 2100000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '1900'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o');

-- ── 4) 직전 대표 비활성화 (가격 보존, est_rent 보존) ───────
--    Studio 2110 / 1BR 1708 / PH 4006
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no IN ('2110', '1708', '4006')
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o');

-- ── 5) 점검: Ae'o 활성 대표 한 눈에 ───────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 6) 중복 점검 (INSERT 두 번 Run 사고 방지) ─────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
