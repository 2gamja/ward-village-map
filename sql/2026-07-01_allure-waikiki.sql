-- ============================================================
-- 2026-07-01  Allure Waikiki (1837 Kalakaua Ave)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가" (Pending 제외)
-- 소스: Zillow Allure Waikiki, Active 5건 (1 Pending 제외)
--   1BR : 활성 0건
--   2BR : 1008 $908k / 1004 $949k / 3503 $1.65M → 2nd = 1004
--   3BR : 3508 $1.45M / 2206 $1.455M          → 2nd = 3508 (활성 2건 중 낮은 쪽)
--
-- 대표 변동 요약:
--   1BR : 807 ($838k)   → (매물 없음, 807 stale 직전호가로 표시)
--   2BR : 2001 ($1.075M) → 1004 ($949,000, 1234sqft) [신규]
--   3BR : 2206 ($1.455M) → 3508 ($1,450,000, 1409sqft, 3bd 2.5ba) [신규]
--
-- 분양가 출처: 도 조사값
--   1004: original $735,125 / rent $4,857
--   3508: original $696,003 / rent $5,010
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (2BR 1004, 3BR 3508) ──────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Allure Waikiki'),
   '2BR', '1004', 1234, 735125, 949000, 4857,
   NULL, 'Ocean', NULL, '2bd', true, CURRENT_DATE, CURRENT_DATE),
  ((SELECT id FROM towers WHERE building_name = 'Allure Waikiki'),
   '3BR', '3508', 1409, 696003, 1450000, 5010,
   NULL, 'Ocean', NULL, '3bd 2.5ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 1BR 807 비활성 (활성 매물 0건 → stale 직전호가) ─────
--     가격/임대는 보존 (build_data.py가 stale rep으로 표시)
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '807'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Allure Waikiki');

-- ── 3) 기존 2BR 대표 2001 비활성 (시장에서 내려감) ────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2001'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Allure Waikiki');

-- ── 4) 기존 3BR 대표 2206 비활성 (여전히 활성 매물이지만 최고가라 rep 아님) ─
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2206'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Allure Waikiki');

-- ── 5) 점검: Allure 타입별 대표 ───────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Allure Waikiki')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 6) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Allure Waikiki')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
