-- ============================================================
-- 2026-06-24  Ko'ula (1000 Auahi St) 주간 업데이트
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 구조 개편: 누락됐던 1BR(소형 509)·GPH 추가, 기존 -01/-02 → 새 이름.
-- Pending(2313,2607)은 비활성 취급.
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR소형 / 1BR대형 / GPH) ─────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Ko''ula'),
   '1BR(소형)', '3403', 509, 902000, 887000, 3482,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ko''ula'),
   '1BR(대형)', '2802', 758, 1280750, 1280000, 4797,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ko''ula'),
   'GPH', '4115', 941, 1610000, 1850000, 5416,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 2BR 직전호가(stale) INSERT — 2607 Pending(비활성) ───
--    표준 2BR 활성 매물 0건 → 가장 최근 호가를 stale 대표로.
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Ko''ula'),
   '2BR', '2607', 968, 1470200, 1447000, NULL,
   NULL, NULL, NULL, 'Pending(비활성)', false, CURRENT_DATE, CURRENT_DATE);

-- ── 3) 4002: 1BR-02 → PH 재분류 + 가격 갱신 (활성 유지) ────
UPDATE units
   SET unit_type = 'PH',
       current_list_price = 1517000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '4002'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');

-- ── 4) 2901: 1BR-01 → 1BR(대형) 리네임 + 비활성 (최고가 제외) ─
UPDATE units
   SET unit_type = '1BR(대형)',
       is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2901'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');

-- ── 5) 3810: 2BR-01 → 2BR 리네임 + 비활성 (매물 내려감) ────
--    last_seen 갱신 안 함 → 2607(오늘)이 stale 대표가 되도록.
UPDATE units
   SET unit_type = '2BR',
       is_active = false
 WHERE unit_no = '3810'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');

-- ── 6) 3504: 2BR-02 → 2BR(대형) 리네임 + 비활성 (stale 보존) ─
--    last_seen 갱신 안 함 → 실제 마지막 확인일을 as_of로 정직하게.
UPDATE units
   SET unit_type = '2BR(대형)',
       is_active = false
 WHERE unit_no = '3504'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');

-- ── 7) 변동 없는 활성 대표 last_seen 갱신 (Studio 2305 / 3BR 2100) ─
UPDATE units
   SET last_seen = CURRENT_DATE, is_active = true
 WHERE unit_no IN ('2305', '2100')
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');

-- ── 8) 점검: Ko'ula 타입별 대표 ───────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 9) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
