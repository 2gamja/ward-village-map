-- ============================================================
-- 2026-07-03  Hokua (1288 Ala Moana Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Hokua Active (2026-07-03 캡처, 총 4건)
--
--   2BR (3건): 37I $3.985M / 29F $3.3M / 29B $2.68M
--     · 2nd 최고가 = 29F [기존 rep 유지, $3.3M 동일]
--     · 기존 활성 31D는 Zillow 리스트에서 사라짐 → 비활성
--
--   3BR (1건): 8A $3.095M
--     · 유일 활성 → 기존 rep 유지
--     · DB current_list $3.3M → Zillow $3.095M (하락, $205k) → 갱신
--
--   PH (0건): Zillow 매물 없음
--     · 기존 rep PH-C 비활성
--
-- 대표 변동 요약:
--   2BR : 29F 유지 ($3,300,000, 1532sqft); 31D legacy 정리
--   3BR : 8A 유지 (가격 $3.3M → $3.095M 갱신, 2325sqft)
--   PH  : PH-C → 없음 [매물 소진]
--
-- 신규 rep 없음 → original/rent 조사 불필요.
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 기존 2BR rep 29F last_seen 갱신 (rep 유지, $3.3M 동일) ──
UPDATE units
   SET last_seen = CURRENT_DATE
 WHERE unit_no = '29F'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Hokua');

-- ── 2) 기존 2BR 활성 31D 비활성 (Zillow에서 사라짐) ────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '31D'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Hokua');

-- ── 3) 기존 3BR rep 8A 가격 갱신 ($3.3M → $3.095M) ────────
UPDATE units
   SET current_list_price = 3095000,
       last_seen = CURRENT_DATE
 WHERE unit_no = '8A'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Hokua');

-- ── 4) 기존 PH rep PH-C 비활성 (매물 소진) ────────────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = 'PH-C'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Hokua');

-- ── 5) 점검: Hokua 타입별 상태 ────────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Hokua')
--  ORDER BY is_active DESC, unit_type, unit_no;
