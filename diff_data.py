"""
diff_data.py — 지난주 스냅샷과 현재 데이터 비교
주간 운영의 핵심 도구.

흐름:
1. snapshots/latest.json (지난주) 읽기
2. ward_village_data.json (이번주) 읽기
3. 모든 unit을 비교
4. 변경 사항 출력:
   - 가격 상승 / 하락
   - 신규 매물 (null → 가격)
   - 사라진 매물 (가격 → null)
   - 신규 unit (이전에 없던 unit)
"""

import json
from pathlib import Path
from collections import defaultdict

BASE_DIR = Path(__file__).parent
CURRENT_FILE = BASE_DIR / "ward_village_data.json"
SNAPSHOT_FILE = BASE_DIR / "snapshots" / "latest.json"


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def build_unit_index(data):
    """
    각 unit을 (콘도, 호수, 타입)으로 식별 가능하게 인덱싱
    반환: {(building_name, unit_no, unit_type): unit_data}
    """
    index = {}
    for tower in data["towers"]:
        for u in tower["units"]:
            key = (tower["building_name"], u.get("unit_no") or "?", u["unit_type"])
            index[key] = u
    return index


def format_money(v):
    if v is None:
        return "매물 없음"
    return f"${v:,.0f}"


def format_change_pct(old, new):
    if old is None or new is None or old == 0:
        return ""
    pct = (new - old) / old * 100
    sign = "+" if pct >= 0 else ""
    return f"({sign}{pct:.1f}%)"


def main():
    if not CURRENT_FILE.exists():
        print("ward_village_data.json 파일이 없습니다. python build_data.py 먼저 실행하세요.")
        return
    
    if not SNAPSHOT_FILE.exists():
        print("snapshots/latest.json 파일이 없습니다. python snapshot_data.py 먼저 실행하세요.")
        return
    
    current = load_json(CURRENT_FILE)
    snapshot = load_json(SNAPSHOT_FILE)
    
    current_index = build_unit_index(current)
    snapshot_index = build_unit_index(snapshot)
    
    # 변경 분류
    price_up = []      # 가격 상승
    price_down = []    # 가격 하락
    new_listing = []   # 신규 매물 (이전 null → 현재 가격)
    gone_listing = []  # 매물 사라짐 (이전 가격 → 현재 null)
    new_unit = []      # 신규 unit (이전엔 아예 없던)
    
    # 현재 데이터의 각 unit 검사
    for key, u_now in current_index.items():
        u_prev = snapshot_index.get(key)
        
        if u_prev is None:
            # 이전에 없던 unit — 신규 추가
            new_unit.append((key, u_now))
            continue
        
        price_now = u_now.get("current_list_price")
        price_prev = u_prev.get("current_list_price")
        
        if price_prev is None and price_now is not None:
            new_listing.append((key, u_now, price_now))
        elif price_prev is not None and price_now is None:
            gone_listing.append((key, u_prev, price_prev))
        elif price_prev is not None and price_now is not None and price_prev != price_now:
            if price_now > price_prev:
                price_up.append((key, price_prev, price_now))
            else:
                price_down.append((key, price_prev, price_now))
    
    # 사라진 unit 확인 (이전에 있던 unit이 지금 없음)
    deleted_unit = []
    for key, u_prev in snapshot_index.items():
        if key not in current_index:
            deleted_unit.append((key, u_prev))
    
    # 결과 출력
    print("=" * 70)
    print(f"  변경 사항 분석 ({snapshot['build_timestamp'][:10]} → {current['build_timestamp'][:10]})")
    print("=" * 70)
    
    if not (price_up or price_down or new_listing or gone_listing or new_unit or deleted_unit):
        print()
        print("  변경 사항 없음 — 지난주와 동일")
        print()
        return
    
    if price_up:
        print()
        print(f"📈 가격 상승 ({len(price_up)}건):")
        for (b, no, t), old, new in price_up:
            change = format_change_pct(old, new)
            print(f"   {b} {t} {no}: {format_money(old)} → {format_money(new)} {change}")
    
    if price_down:
        print()
        print(f"📉 가격 하락 ({len(price_down)}건):")
        for (b, no, t), old, new in price_down:
            change = format_change_pct(old, new)
            print(f"   {b} {t} {no}: {format_money(old)} → {format_money(new)} {change}")
    
    if new_listing:
        print()
        print(f"🆕 신규 매물 ({len(new_listing)}건):")
        for (b, no, t), u, price in new_listing:
            sqft = u.get("living_sqft") or "?"
            print(f"   {b} {t} {no} ({sqft} sqft): {format_money(price)}")
    
    if gone_listing:
        print()
        print(f"❌ 매물 사라짐 ({len(gone_listing)}건):")
        for (b, no, t), u, price in gone_listing:
            print(f"   {b} {t} {no}: {format_money(price)} → 매물 없음")
            print(f"      (거래 완료 가능성)")
    
    if new_unit:
        print()
        print(f"➕ 신규 Unit ({len(new_unit)}건):")
        for (b, no, t), u in new_unit:
            price = u.get("current_list_price")
            print(f"   {b} {t} {no}: {format_money(price)}")
    
    if deleted_unit:
        print()
        print(f"➖ 삭제된 Unit ({len(deleted_unit)}건):")
        for (b, no, t), u in deleted_unit:
            print(f"   {b} {t} {no}")
    
    # 요약 통계
    total_changes = len(price_up) + len(price_down) + len(new_listing) + len(gone_listing) + len(new_unit) + len(deleted_unit)
    total_units_now = current["total_units"]
    
    print()
    print("=" * 70)
    print(f"  요약: 전체 {total_units_now}개 매물 중 {total_changes}건 변경")
    print(f"        상승 {len(price_up)} | 하락 {len(price_down)} | 신규 {len(new_listing)} | 사라짐 {len(gone_listing)}")
    print("=" * 70)


if __name__ == "__main__":
    main()
