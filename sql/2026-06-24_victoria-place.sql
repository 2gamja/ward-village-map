-- ============================================================
-- 2026-06-24  Victoria Place (1118 Ala Moana Blvd) 주간 업데이트
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 구조: 2BR -01/-02 → 소형/대형 리네임, 2BR(PH) 신규 추가.
-- AUC는 활성 포함.
-- ⚠ 1002 임대($5,691)가 1606과 동일·1010보다 낮음 → 복붙 실수 의심. 확인 요망.
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (6건) ────────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Victoria Place'),
   '1BR', '1606', 895, 1531850, 1860000, 5691,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Victoria Place'),
   '1BR(PH)', '4007', 798, 1542000, 1888000, 5776,
   NULL, NULL, NULL, 'Grand Penthouse', true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Victoria Place'),
   '2BR(소형)', '1010', 1164, 1820000, 2108888, 7364,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Victoria Place'),
   '2BR(대형)', '1002', 1295, 2198050, 2950000, 5691,   -- ⚠ 임대 확인
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Victoria Place'),
   '2BR(PH)', '3802', 1295, 2858800, 3488000, 7551,
   NULL, NULL, NULL, 'Penthouse', true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Victoria Place'),
   '3BR', '700', 1851, 3701200, 4950000, 8183,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 직전 대표/매물내려감 비활성 (가격 보존) ────────────
--    1BR 2908(최고가 제외) / 1BR(PH) 4006(매물내려감) / 3BR 1101(비대표)
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no IN ('2908', '4006', '1101')
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');

-- ── 3) 2810: 2BR-02 → 2BR(소형) 리네임 + 비활성 (최고가 제외) ─
UPDATE units
   SET unit_type = '2BR(소형)',
       is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2810'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');

-- ── 4) 3402: 2BR-01 → 2BR(대형) 리네임 + 비활성 (최고가 제외) ─
UPDATE units
   SET unit_type = '2BR(대형)',
       is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3402'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');

-- ── 5) 2700: 3BR(PH) 대표 유지 + last_seen 갱신 ───────────
UPDATE units
   SET last_seen = CURRENT_DATE, is_active = true
 WHERE unit_no = '2700'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');

-- ── 6) 점검: Victoria Place 타입별 대표 ───────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 7) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
