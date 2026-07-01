-- ============================================================
-- 2026-06-24  1BR/2BR 병합 보정 (PM=3BR+ 럭셔리 수요자 반영)
-- 정책: 맵에서 1BR·2BR은 침실 수당 단일 대표.
--   · 소형/대형 세분 → 단일 '1BR'/'2BR'로 병합 (소형 등은 inactive raw로 보관)
--   · 단일 대표 = 원래 전체풀 2번째 최고가(=기존 '대형'/메인 대표)를 활성 유지
--   · 펜트하우스(PH/GPH/1BR(PH)/2BR(PH))는 침실 수 무관 '별도 타입' 그대로 유지 → 안 건드림
--   · 3BR·3BR(PH) 등 3BR+ 상세 유지 → 안 건드림
-- 모든 콘도 SQL은 이미 Run된 상태. 아래는 기존 행 UPDATE(멱등).
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

-- ───────────────────────── Ae'o ─────────────────────────
-- 2BR(대형) 2604 → '2BR' 단일 대표(활성 유지) / 2BR(소형) 2415 → '2BR' inactive
UPDATE units SET unit_type = '2BR'
 WHERE unit_no = '2604' AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o');
UPDATE units SET unit_type = '2BR', is_active = false
 WHERE unit_no = '2415' AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ae''o');
-- (PH 3915 그대로, Studio/1BR/3BR 그대로)

-- ──────────────────────── 'A'ali'i ──────────────────────
-- 2BR 4015 단일 대표(활성 유지) / 2BR(소형) 908 → '2BR' inactive
UPDATE units SET unit_type = '2BR'
 WHERE unit_no = '4015' AND tower_id = (SELECT id FROM towers WHERE building_name = '''A''ali''i');
UPDATE units SET unit_type = '2BR', is_active = false
 WHERE unit_no = '908'  AND tower_id = (SELECT id FROM towers WHERE building_name = '''A''ali''i');

-- ───────────────────────── Ko'ula ───────────────────────
-- 1BR(대형) 2802 → '1BR' 단일 대표(활성 유지)
UPDATE units SET unit_type = '1BR'
 WHERE unit_no = '2802' AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');
-- 1BR(소형) 3403, 1BR(대형)이던 비활성 2901 → '1BR' inactive
UPDATE units SET unit_type = '1BR', is_active = false
 WHERE unit_no IN ('3403','2901') AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');
-- 2BR(대형) 3504 → '2BR' inactive (2607·3810 이미 '2BR'). 활성 0 → stale 2607 유지
UPDATE units SET unit_type = '2BR', is_active = false
 WHERE unit_no = '3504' AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ko''ula');
-- (PH 4002 / GPH 4115 그대로, 3BR 2100 그대로)

-- ──────────────────── Victoria Place ────────────────────
-- 2BR(대형) 1002 → '2BR' 단일 대표(활성 유지)
UPDATE units SET unit_type = '2BR'
 WHERE unit_no = '1002' AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');
-- 2BR(소형) 1010 → '2BR' inactive / 비활성 2810·3402 → '2BR'
UPDATE units SET unit_type = '2BR', is_active = false
 WHERE unit_no = '1010' AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');
UPDATE units SET unit_type = '2BR'
 WHERE unit_no IN ('2810','3402') AND tower_id = (SELECT id FROM towers WHERE building_name = 'Victoria Place');
-- (1BR 1606 / 1BR(PH) 4007 / 2BR(PH) 3802 / 3BR 700 / 3BR(PH) 2700 그대로)

-- ──────────────────── 점검 ──────────────────────────────
-- 각 콘도 타입별 활성 대표 1개씩인지(+PH/3BR 분리 유지) 확인:
-- SELECT t.building_name, u.unit_type, u.unit_no, u.current_list_price, u.is_active
--   FROM units u JOIN towers t ON u.tower_id=t.id
--  WHERE t.building_name IN ('Ae''o','''A''ali''i','Ko''ula','Victoria Place')
--    AND u.is_active = true
--  ORDER BY t.building_name, u.unit_type;
