-- ============================================================
-- 2026-07-02  Keauhou Place (555 South St)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Keauhou Place Active 7건
--
--   1BR (2건): 4004 $745k / 3410 $698k
--     · 2nd 최고가 = 3410 [신규 rep]
--     · 기존 rep 3409는 Zillow에서 사라짐 → 비활성
--     · 4004는 최고가라 rep 자격 상실 → 비활성
--
--   2BR (2건): 807 $859k / 1401 $859k (동률)
--     · 기존 rep 807이 동률 그룹 안에 있으므로 rep 유지 (교체 없음)
--     · 기존 rep 3902는 Zillow에서 사라짐 → 비활성
--     · 1401은 신규지만 동률 뒷순위 → INSERT 안 함
--
--   3BR (2건): 1205 $1.288M / 1305 $1.275M
--     · 2nd 최고가 = 1305 (기존 rep 유지)
--     · 단, current_list_price $1,325,000 → $1,275,000 인하 반영
--
--   3BR(PH) (1건): 4305 $1.8M
--     · 기존 rep 그대로 → 변경 없음
--
-- 대표 변동 요약:
--   1BR : 3409 → 3410 ($698,000, 629sqft)
--   2BR : 807 유지 ($859,000, 974sqft)
--   3BR : 1305 유지 (가격만 $1,275,000로 인하)
--   PH  : 4305 유지 (변경 없음)
--
-- 분양가/임대 (도 조사값):
--   3410: original $538,630 / rent $2,954
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR 3410) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Keauhou Place'),
   '1BR', '3410', 629, 538630, 698000, 2954,
   NULL, 'City', NULL, '1bd 1ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 3BR 1305 가격 인하 반영 ($1,325k → $1,275k) ────────
UPDATE units
   SET current_list_price = 1275000,
       last_seen = CURRENT_DATE
 WHERE unit_no = '1305'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Keauhou Place');

-- ── 3) 1BR 3409 비활성 (Zillow에서 사라짐) ────────────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3409'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Keauhou Place');

-- ── 4) 1BR 4004 비활성 (최고가라 rep 자격 상실) ───────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '4004'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Keauhou Place');

-- ── 5) 2BR 3902 비활성 (Zillow에서 사라짐) ────────────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3902'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Keauhou Place');

-- ── 6) 점검: Keauhou Place 타입별 상태 ────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Keauhou Place')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 7) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Keauhou Place')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
