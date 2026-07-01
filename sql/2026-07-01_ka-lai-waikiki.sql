-- ============================================================
-- 2026-07-01  Ka Lai Waikiki Beach (구 Trump Tower Waikiki, 223 Saratoga Rd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: zillow.com/b/trump-tower-waikiki-honolulu-hi-5Xqqn6 (Active 38건)
--
-- 대표 변동 요약:
--   Studio   : 2109 ($850k)    → 2109           [동일, last_seen 갱신]
--   1BR      : 3008 ($1.70M)   → 2011 ($1.85M)  [신규]
--   2BR      : 1619 ($2.985M)  → 1619           [동일, last_seen 갱신]
--   3BR      : 3410 ($4.50M)   → 3410           [동일, last_seen 갱신, 2709와 동가 tie 시 기존 유지]
--   2BR(PH)  : 3801 ($9.98M)   → 3801           [동일, last_seen 갱신]
--
-- 2011 분양가는 준공 후 첫 Valid 개별 매매 (12/09/2010 $1,711,900) 채택.
-- 2009년 두 건 대금액 이전은 디벨로퍼 마스터 이전이라 제외.
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR 2011) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach'),
   '1BR', '2011', 1115, 1711900, 1850000, 5917,
   NULL, 'Ocean', NULL, '1bd 2ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 1BR 대표 비활성 (3008) ────────────────────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3008'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach');

-- ── 3) 변동 없는 활성 대표 last_seen + 호가 갱신 ──────────
UPDATE units
   SET current_list_price = 850000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '2109'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach');

UPDATE units
   SET current_list_price = 2985000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '1619'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach');

UPDATE units
   SET current_list_price = 4500000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '3410'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach');

UPDATE units
   SET current_list_price = 9980000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '3801'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach');

-- ── 4) 점검: Ka Lai 타입별 대표 ───────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 5) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ka Lai Waikiki Beach')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
