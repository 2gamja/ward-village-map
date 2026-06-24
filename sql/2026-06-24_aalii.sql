-- ============================================================
-- 2026-06-24  'A'ali'i (987 Queen St) 주간 업데이트
-- 규칙: 타입별 대표 = 활성 매물 중 "2번째 최고가" (현행 룰 유지)
-- Pending(808)은 비활성 취급, AUC는 활성 포함
-- 2BR 쪼개기: 908(787sqft·2bd/1ba)을 "2BR(소형)"으로 분리
-- 2500 분양가: 세금 역산 추정치라 신뢰도 낮음 → original_price NULL 처리(상승률 미산정).
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ── 1) 신규 대표 INSERT (1BR / 2BR / 2BR소형) ─────────────
INSERT INTO units (
  tower_id, unit_type, unit_no, living_sqft,
  original_price, current_list_price, est_rent_monthly,
  hoa_monthly, view_type, listing_url, notes,
  is_active, first_seen, last_seen
) VALUES
  ((SELECT id FROM towers WHERE building_name = '''A''ali''i'),
   '1BR', '2500', 559, NULL, 900000, 3531,   -- 분양가 NULL (세금 역산 추정치 제외)
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = '''A''ali''i'),
   '2BR', '4015', 828, 1145615, 1350000, 4558,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE),

  ((SELECT id FROM towers WHERE building_name = '''A''ali''i'),
   '2BR(소형)', '908', 787, 957505, 1060000, 4010,
   NULL, NULL, NULL, NULL, true, CURRENT_DATE, CURRENT_DATE);

-- ── 2) 변동 없는 대표 last_seen 갱신 (Studio 3506) ────────
UPDATE units
   SET current_list_price = 589000,
       last_seen = CURRENT_DATE,
       is_active = true
 WHERE unit_no = '3506'
   AND tower_id = (SELECT id FROM towers WHERE building_name = '''A''ali''i');

-- ── 3) 직전 대표 비활성화 (가격·임대 보존) ────────────────
--    1BR 3517 / 2BR 3714 (둘 다 이번엔 각 타입 최고가라 제외)
UPDATE units
   SET is_active = false,
       last_seen = CURRENT_DATE
 WHERE unit_no IN ('3517', '3714')
   AND tower_id = (SELECT id FROM towers WHERE building_name = '''A''ali''i');

-- ── 4) 점검: 'A'ali'i 활성 대표 ───────────────────────────
-- SELECT unit_type, unit_no, living_sqft, original_price,
--        current_list_price, est_rent_monthly, is_active, last_seen
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = '''A''ali''i')
--  ORDER BY is_active DESC, unit_type, unit_no;

-- ── 5) 중복 점검 ──────────────────────────────────────────
-- SELECT unit_no, unit_type, count(*)
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = '''A''ali''i')
--  GROUP BY unit_no, unit_type HAVING count(*) > 1;
