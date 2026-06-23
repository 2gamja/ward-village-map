-- ============================================================
-- 01_raw_listings.sql
-- 목적: units 테이블을 "raw 매물 기록" 계층으로 전환.
--       대표 선정(타입별 시세 1개)은 더 이상 손으로 고르지 않고
--       build_data.py가 규칙대로 자동 계산한다.
--
-- 한 번만 실행하면 됨. Supabase SQL Editor에 통째로 붙여넣고 Run.
-- (IF NOT EXISTS / COALESCE 로 작성돼 있어 재실행해도 안전)
-- ============================================================

-- 1) 매물 상태/이력 컬럼 추가
--    is_active   : 현재 시장에 올라와 있는 매물인가 (true=활성, false=내려감)
--    first_seen  : 이 매물을 처음 기록한 날
--    last_seen   : 이 매물을 마지막으로 확인한 날 (stale 판단 기준)
ALTER TABLE units ADD COLUMN IF NOT EXISTS is_active  boolean NOT NULL DEFAULT true;
ALTER TABLE units ADD COLUMN IF NOT EXISTS first_seen date;
ALTER TABLE units ADD COLUMN IF NOT EXISTS last_seen  date;

-- 2) 기존 데이터 백필
--    현재 매물가(current_list_price)가 비어 있던 행 = 매물이 내려간 상태로 간주 → 비활성.
--    가격이 있던 행 = 활성.
UPDATE units
   SET is_active = (current_list_price IS NOT NULL);

--    날짜가 비어 있으면 오늘 날짜로 초기화 (이력의 출발점).
UPDATE units
   SET first_seen = COALESCE(first_seen, CURRENT_DATE),
       last_seen  = COALESCE(last_seen,  CURRENT_DATE);

-- 3) 조회 성능용 인덱스 (대표 선정은 type+활성 기준으로 자주 묶음)
--    FK 컬럼명(tower_id 등)에 의존하지 않도록 type+is_active 로만 구성.
CREATE INDEX IF NOT EXISTS idx_units_type_active ON units (unit_type, is_active);

-- ============================================================
-- 확인 쿼리 (선택): 활성/비활성 분포 보기
-- ============================================================
-- SELECT is_active, count(*) FROM units GROUP BY is_active;
