-- ============================================================
-- 2026-06-24  Ulana (988 Halekauwila 인근, 예약 주거) 주간 업데이트
-- 상태: 예약 주거 빌딩(2~10년 매매제한) → 현재 시장 매물 0건.
-- 처리: 기존 활성 810호를 비활성 + 현재호가/임대 비움
--       → 직전호가(stale)도 안 뜨고 맵에 "매물 없음"으로 표시.
--       (분양가 original_price는 이력으로 보존)
-- Supabase SQL Editor에 통째로 붙여넣고 Run.
-- ============================================================

UPDATE units
   SET is_active = false,
       current_list_price = NULL,
       est_rent_monthly = NULL,
       last_seen = CURRENT_DATE
 WHERE unit_no = '810'
   AND tower_id = (SELECT id FROM towers WHERE building_name = 'Ulana');

-- (선택) 빌딩 노트에 매물 없음 명시
UPDATE towers
   SET notes = '예약 주거 빌딩, 2~10년 매매제한 (현재 매물 없음)'
 WHERE building_name = 'Ulana';

-- ── 점검: Ulana에 활성/가격 있는 매물이 없어야 함 ─────────
-- SELECT unit_no, unit_type, is_active, current_list_price
--   FROM units
--  WHERE tower_id = (SELECT id FROM towers WHERE building_name = 'Ulana');
