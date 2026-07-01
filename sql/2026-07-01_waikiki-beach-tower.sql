-- ============================================================
-- 2026-07-01  Waikiki Beach Tower (2470 Kalakaua Ave) [leasehold-converted]
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: redfin.com/HI/Honolulu/2470-Kalakaua-Ave (For Sale 6건, 전부 2BR)
--
-- 대표 변동 요약:
--   2BR : 504 ($770k) → 1101 ($2.80M)  [신규]
--
-- 활성 desc: 2800(1101), 2800(2201), 2650(3102), 2450(903), 2350(1604), 770(504)
-- 최고가 tie → 호수 낮은 1101을 2번째 위치 rep로 채택.
-- 504는 나머지($2.35M+)와 3배 차이 outlier low(leasehold 잔존/특수 상황 추정) → 비활성.
--
-- 1101 분양가: 1983 준공 leasehold 건물의 이 호수 최초 개별 판매(02/01/1987 $470k LEASE)를
-- 분양가로 채택. 1995년 fee 전환비($91k)와 2023년 재매매($1.9M)는 분양이 아님.
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (2BR 1101) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Waikiki Beach Tower'),
   '2BR', '1101', 1150, 470000, 2800000, 4553,
   NULL, 'Ocean', NULL, '1987 leasehold 최초분양 $470k → fee 전환 완료', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 2BR 대표 비활성 (504) ─────────────────────────
--    504는 outlier low($770k, leasehold 잔존/특수 상황 추정). 가격은 보존.
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '504'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Beach Tower');

-- ── 3) 점검: Waikiki Beach Tower 타입별 대표 ──────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Beach Tower')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 4) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Beach Tower')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
