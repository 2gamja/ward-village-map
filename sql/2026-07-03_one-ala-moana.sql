-- ============================================================
-- 2026-07-03  ONE Ala Moana (1555 Kapiolani Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow ONE Ala Moana Active (2026-07-03 캡처, 총 8건)
--
--   1BR (2건): 914 $1.124M / 1714 $1.068M
--     · 2nd 최고가 = 1714 [신규 rep]
--     · 기존 rep 914는 Zillow 활성 유지 but rep 아님 → 비활성
--
--   2BR (4건): 1706 $1.879M / 1105 $1.65M(AUC) = 808 $1.65M / 1109 $1.6M
--     · 2nd 최고가 = $1.65M 동률(1105, 808)
--     · 기존 rep 1105가 동률 그룹 안에 있으므로 rep 유지
--     · 기존 활성 1706은 최고가 위치 → rep 자격 상실 → 비활성
--
--   3BR (2건): 2002 $3.3M / 900 $2.18M(AUC)
--     · 2nd 최고가 = 900 [기존 rep 유지]
--     · 기존 활성 1300은 Zillow 리스트에서 사라짐 → 비활성
--
--   3BR(PH) (0건): Zillow 매물 없음
--     · 기존 rep 2302 비활성
--
-- 대표 변동 요약:
--   1BR    : 914 → 1714 ($1,068,000, 881sqft) [교체]
--   2BR    : 1105 유지 ($1,650,000, 1278sqft); 1706 legacy 정리
--   3BR    : 900 유지 ($2,180,000, 1800sqft); 1300 legacy 정리
--   3BR(PH): 2302 → 없음 [매물 소진]
--
-- 분양가/임대 (도 조사값):
--   1714: original $796,000 / rent $2,906
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR 1714) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'ONE Ala Moana'),
   '1BR', '1714', 881, 796000, 1068000, 2906,
   NULL, 'Ocean', NULL, '1bd 1ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 1BR rep 914 비활성 (rep 자격 상실, Zillow는 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '914'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana');

-- ── 3) 기존 2BR 활성 1706 비활성 (rep 자격 상실, Zillow는 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '1706'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana');

-- ── 4) 기존 2BR rep 1105 last_seen 갱신 (rep 유지, $1.65M 동일) ──
UPDATE units
   SET last_seen = CURRENT_DATE
 WHERE unit_no = '1105'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana');

-- ── 5) 기존 3BR 활성 1300 비활성 (Zillow에서 사라짐) ──────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '1300'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana');

-- ── 6) 기존 3BR rep 900 last_seen 갱신 (rep 유지, $2.18M 동일) ──
UPDATE units
   SET last_seen = CURRENT_DATE
 WHERE unit_no = '900'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana');

-- ── 7) 기존 3BR(PH) rep 2302 비활성 (매물 소진) ───────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2302'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana');

-- ── 8) 점검: ONE Ala Moana 타입별 상태 ────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 9) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'ONE Ala Moana')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
