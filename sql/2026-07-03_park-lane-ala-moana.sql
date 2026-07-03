-- ============================================================
-- 2026-07-03  Park Lane Ala Moana (1388 Ala Moana Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Park Lane Active (2026-07-03 캡처, 총 9건)
--
--   2BR (6건): 6700 $8.48M / 3805 $5.889M / 2302 $5.4M
--              / 2303 $4.75M / 7703 $3.55M / 1406 $2.6M(AUC)
--     · 2nd 최고가 = 3805 [신규 rep]
--     · 기존 rep 2302·7703은 Zillow 활성 유지 but rep 아님 → 비활성
--     · 신규 활성(2303/2303/1406/6700)은 rep 아니라 저장 스킵 (rep-only 모델)
--
--   3BR (2건): 8804 $10.39M(AUC) / 5401 $8.9M
--     · 2nd 최고가 = 5401 [신규 rep]
--     · 기존 rep 5301·7601은 Zillow 리스트에서 사라짐 → 비활성
--
--   4BR (0건): Zillow 매물 없음
--     · 기존 rep 3800 비활성 (재캡처 시까지 유령 방지)
--
--   5BR(PH) (1건): 6800 $30M
--     · 유일 활성 → 기존 rep 유지, 가격 동일 ($30M)
--     · last_seen만 갱신
--
-- 대표 변동 요약:
--   2BR    : 2302+7703 → 3805 ($5,888,888, 1812sqft, 2.5ba) [교체]
--   3BR    : 5301+7601 → 5401 ($8,900,000, 2340sqft, 3.5ba) [교체]
--   4BR    : 3800 → 없음 [매물 소진]
--   5BR(PH): 6800 유지 ($30,000,000)
--
-- 분양가/임대 (도 조사값):
--   3805: original $3,476,000 / rent $6,374
--   5401: original $5,375,000 / rent $7,695
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (2BR 3805, 3BR 5401) ──────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana'),
   '2BR', '3805', 1812, 3476000, 5888888, 6374,
   NULL, 'Ocean', NULL, '2bd 2.5ba', true, CURRENT_DATE, CURRENT_DATE),
  ((SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana'),
   '3BR', '5401', 2340, 5375000, 8900000, 7695,
   NULL, 'Ocean', NULL, '3bd 3.5ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 2BR 활성 2302 비활성 (rep 자격 상실, Zillow는 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2302'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');

-- ── 3) 기존 2BR 활성 7703 비활성 (rep 자격 상실, Zillow는 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '7703'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');

-- ── 4) 기존 3BR 활성 5301 비활성 (Zillow에서 사라짐) ──────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '5301'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');

-- ── 5) 기존 3BR 활성 7601 비활성 (Zillow에서 사라짐) ──────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '7601'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');

-- ── 6) 기존 4BR 활성 3800 비활성 (4BR 매물 소진) ──────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3800'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');

-- ── 7) 기존 5BR(PH) 6800 last_seen 갱신 (rep 유지, $30M 동일) ──
UPDATE units
   SET last_seen = CURRENT_DATE
 WHERE unit_no = '6800'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana');

-- ── 8) 점검: Park Lane 타입별 상태 ────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 9) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Park Lane Ala Moana')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
