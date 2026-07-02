-- ============================================================
-- 2026-07-02  Waikiki Banyan (201 S Ohua Ave)
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가" (AUC 포함)
-- 소스: Zillow Waikiki Banyan Active 22건 (AUC 3건 포함, 전부 1BR)
--   최고가: 3513 $900k  (여전히 활성)
--   2nd  : T1-3201 $890k (신규 대표)
--
-- 대표 변동 요약:
--   1BR : 2312 $785k + 3513 $900k (둘 다 active) → 3201 $890,000 [신규]
--         · 3513: 여전히 Zillow 활성이지만 최고가라 rep 제외 → 비활성
--         · 2312: Zillow 리스트에 없음(시장에서 내려감) → 비활성
--
-- 분양가 출처: Fee Conveyance 2008-05-16 $77,100
--   (Waikiki Banyan은 1978 완공 leasehold → 2007~2008 Fee 전환)
--   기존 3513($195k)·2312($225k)와 동일 원칙(전환기 fee 매입가) 적용
--
-- 임대: $2,437 (도 조사값)
--
-- unit_no 표기: Zillow "T1-3201" → DB는 순수 숫자 컨벤션 유지 → '3201'
--
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 활성 대표 INSERT (1BR 3201) ────────────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = 'Waikiki Banyan'),
   '1BR', '3201', 533, 77100, 890000, 2437,
   NULL, 'Ocean', NULL, '1bd 1ba (Tower 1)', true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 기존 3513 비활성 (여전히 Zillow 활성이지만 최고가라 rep 아님) ──
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '3513'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Banyan');

-- ── 3) 기존 2312 비활성 (시장에서 내려감) ─────────────────
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no = '2312'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Banyan');

-- ── 4) 점검: Waikiki Banyan 타입별 상태 ───────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Banyan')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 5) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Waikiki Banyan')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
