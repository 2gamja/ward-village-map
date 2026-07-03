-- ============================================================
-- 2026-07-03  Sky Ala Moana (East 1390 / West 1388 Kapiolani Blvd)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가"
-- 소스: Zillow Sky Ala Moana East For-sale (2026-07-03 캡처, 15건)
--       Sky Ala Moana West For-sale = 0건 (도 확인)
--
--   Studio(east) — 13건 활성 (902는 2BR/1BA 598sqft $459k = Affordable Housing
--                             프로그램 매물로 판단, 시장 왜곡 방지 위해 제외)
--     3808 $798k / 3608 $773k / 3204 $729.5k / 3104 $699k / 3002 $690k
--     / 3507 $680k / 3311 $659k / 3107 $659k / 3407 $650k / 3203 $625k
--     / 3704 $580k / 3306 $560k / 3308 $545k
--     · 2nd 최고가 = 3608 [신규 rep]
--     · 기존 rep 3607은 Zillow 리스트에서 사라짐 → 비활성
--
--   1BR(east) — 1건: 3603 $970k
--     · 유일 활성 → 기존 rep 유지
--     · DB current_list $1,000,000 → Zillow $970,000 (하락 $30k) → 갱신
--
--   2BR(east) — 0건 (902 제외 후)
--     · 기존 NULL 플레이스홀더 그대로 유지 (변경 없음)
--
--   1BR(west) — 0건 (West 매물 소진)
--     · 기존 rep 2703 비활성
--
--   2BR(west) — 0건 (West 매물 소진)
--     · 기존 rep 3501 비활성
--
-- 대표 변동 요약:
--   Studio(east): 3607 → 3608 ($773,000, 388sqft) [교체]
--   1BR(east)   : 3603 유지 (가격 $1M → $970k 갱신, 605sqft)
--   1BR(west)   : 2703 → 없음 [매물 소진]
--   2BR(west)   : 3501 → 없음 [매물 소진]
--
-- 분양가/임대 (도 조사값):
--   3608: original $635,900 / rent $2,287
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (Studio(east) 3608) ───────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Sky Ala Moana'),
   'Studio(east)', '3608', 388, 635900, 773000, 2287,
   NULL, 'City', NULL, 'studio 1ba', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 Studio(east) rep 3607 비활성 (Zillow에서 사라짐) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3607'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Sky Ala Moana');

-- ── 3) 기존 1BR(east) rep 3603 가격 갱신 ($1,000,000 → $970,000) ──
UPDATE units
   SET current_list_price = 970000,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3603'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Sky Ala Moana');

-- ── 4) 기존 1BR(west) rep 2703 비활성 (West 매물 0건) ─────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2703'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Sky Ala Moana');

-- ── 5) 기존 2BR(west) rep 3501 비활성 (West 매물 0건) ─────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3501'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Sky Ala Moana');

-- ── 6) 점검: Sky Ala Moana 타입별 상태 ────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Sky Ala Moana')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 7) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Sky Ala Moana')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
