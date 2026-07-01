-- ============================================================
-- 2026-07-01  Ritz-Carlton Residences Waikiki Beach (383 Kalaimoku St)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가" (최고가 제외)
-- 소스: redfin.com/HI/Honolulu/383-Kalaimoku-St (For Sale 20건)
--
-- 대표 변동 요약:
--   Studio : 1508 ($630k)   → 2001 ($649k)   [신규]
--   1BR    : D3102 ($1.40M) → 3005 ($1.55M)  [신규]
--   2BR    : E2903 ($2.20M) → E2903          [동일, last_seen 갱신]
--   3BR    : 3307 ($3.96M)  → 3307           [동일, last_seen 갱신]
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (Studio 2001 / 1BR 3005) ──────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach'),
   'Studio', '2001', 501, 897800, 649000, 3055,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach'),
   '1BR', '3005', 842, 2098800, 1550000, 4351,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 대표 비활성 (Studio 1508 / 1BR D3102) ─────────
--    새 대표가 붙어서 대표 자리를 넘김. 가격은 보존.
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no IN ('1508', 'D3102')
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach');

-- ── 3) 변동 없는 활성 대표 last_seen + 호가 갱신 (2BR E2903 / 3BR 3307) ─
UPDATE units
   SET current_list_price = 2200000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = 'E2903'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach');

UPDATE units
   SET current_list_price = 3958888,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '3307'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach');

-- ── 4) 점검: Ritz-Carlton 타입별 대표 ─────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 5) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ritz-Carlton Residences Waikiki Beach')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
