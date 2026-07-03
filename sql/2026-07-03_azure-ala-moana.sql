-- ============================================================
-- 2026-07-03  Azure Ala Moana (629 Keeaumoku St)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Azure Ala Moana Active (2026-07-03 캡처, 25건 중 Pending 1807 제외 → 활성 24건)
--
--   1BR (4건, Pending 1807 제외):
--     3305 $849k / 3105 $799k / 1708 $759k / 1905 $755k
--     · 2nd 최고가 = 3105 [기존 rep 유지, $799k 동일]
--
--   2BR (21건): 3101 $1.85M / 2312 $1.555M / 3211 $1.53M
--               / 3212 $1.5M / 2911·2511 $1.399M / …
--     · 2nd 최고가 = 2312 [신규 rep]
--     · 기존 rep 3212는 4위로 밀림, rep 자격 상실 → 비활성
--
--   3BR (2건): 3801 $2.35M / 3401 $2.3M
--     · 2nd 최고가 = 3401 [신규 rep]
--     · 기존 rep 3801은 최고가 위치, rep 자격 상실 → 비활성
--
-- 대표 변동 요약:
--   1BR : 3105 유지 ($799,000, 658sqft)
--   2BR : 3212 → 2312 ($1,555,000, 1092sqft, 2ba) [교체]
--   3BR : 3801 → 3401 ($2,300,000, 1464sqft, 3ba) [교체]
--
-- 분양가/임대 (도 조사값):
--   2312: original $1,185,905 / rent $5,336
--   3401: original $2,179,250 / rent $5,931
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (2BR 2312, 3BR 3401) ──────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Azure Ala Moana'),
   '2BR', '2312', 1092, 1185905, 1555000, 5336,
   NULL, 'Ocean', NULL, '2bd 2ba', true, CURRENT_DATE, CURRENT_DATE),
  ((SELECT id FROM towers WHERE building_name = 'Azure Ala Moana'),
   '3BR', '3401', 1464, 2179250, 2300000, 5931,
   NULL, 'Ocean', NULL, '3bd 3ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 1BR rep 3105 last_seen 갱신 (rep 유지, $799k 동일) ──
UPDATE units
   SET last_seen = CURRENT_DATE
 WHERE unit_no = '3105'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Azure Ala Moana');

-- ── 3) 기존 2BR rep 3212 비활성 (rep 자격 상실, Zillow는 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3212'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Azure Ala Moana');

-- ── 4) 기존 3BR rep 3801 비활성 (rep 자격 상실, Zillow는 유지) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3801'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Azure Ala Moana');

-- ── 5) 점검: Azure Ala Moana 타입별 상태 ──────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Azure Ala Moana')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 6) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Azure Ala Moana')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
