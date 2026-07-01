-- ============================================================
-- 2026-06-24  The Park Ward Village (333 Ward Ave) 주간 업데이트  [최종본]
-- 정책: Studio·1BR·2BR 단일 / PH 별도 / 3BR+ 상세(소형·대형).
--   · 1BR·2BR의 기존 Pod/Tower 구분 → 단일로 병합.
--   · 분양가: 2026 입주·소유권 이전 전이라 확인 불가 → 전부 NULL. 임대는 Zillow 추정치.
--   · P3 주차($95k)·최고가 매물 제외.
--   · 소스: zillow.com-333 Ward Ave.pdf (1201 매물 내려가 1BR 대표 3501로 갱신).
--   · 3500+3501 결합 4BR($4.88M)은 3500·3501 중복이라 제외.
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (6건, 분양가 NULL / 임대 有) ──
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'The Park Ward Village'),
   'Studio', '3508', 465, NULL, 952000, 3479,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'The Park Ward Village'),
   '1BR', '3501', 734, NULL, 1625000, 4400,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'The Park Ward Village'),
   '2BR', '1303', 1169, NULL, 2215000, 7001,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'The Park Ward Village'),
   '2BR(PH)', '4111', 923, NULL, 1690000, 5132,
   NULL, NULL, NULL, 'Penthouse', true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'The Park Ward Village'),
   '3BR(소형)', '202', 1312, NULL, 2165000, 6811,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'The Park Ward Village'),
   '3BR(대형)', '3500', 1554, NULL, 3388000, 7955,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 유닛 비활성 + 타입 정리 ───────────────────────
-- 1008(Studio) 매물내려감 → 비활성
UPDATE units SET is_active = false, last_seen = CURRENT_DATE
 WHERE unit_no = '1008' AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Park Ward Village');
-- 516(1BR Pod)·3001(1BR Tower) → '1BR' 병합 + 비활성 (매물내려감)
UPDATE units SET unit_type = '1BR', is_active = false, last_seen = CURRENT_DATE
 WHERE unit_no IN ('516','3001') AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Park Ward Village');
-- 303(2BR Pod) → '2BR' 병합 + 비활성 (아직 활성이나 비대표)
UPDATE units SET unit_type = '2BR', is_active = false, last_seen = CURRENT_DATE
 WHERE unit_no = '303' AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Park Ward Village');
-- 200(3BR Pod, 1554) → '3BR(대형)' + 비활성 (매물내려감)
UPDATE units SET unit_type = '3BR(대형)', is_active = false, last_seen = CURRENT_DATE
 WHERE unit_no = '200' AND tower_id = (SELECT id FROM towers WHERE building_name = 'The Park Ward Village');

-- ── 3) 점검 ───────────────────────────────────────────────
-- SELECT unit_type, unit_no, living_sqft, current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'The Park Ward Village')
--  ORDER BY is_active DESC, unit_type, unit_no;
-- SELECT unit_no, unit_type, count(*)
--   FROM units WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'The Park Ward Village')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
