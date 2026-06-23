"""
build_data.py — Supabase 데이터를 가져와서 파생값 계산 + 정렬 + JSON 저장
Day 5 업데이트: unit_type 기준 의미적 정렬 + 매물 유무별 정렬
"""

import os
import json
from datetime import datetime
from collections import defaultdict
from dotenv import load_dotenv
from supabase import create_client

load_dotenv()
url = os.getenv("SUPABASE_URL")
key = os.getenv("SUPABASE_KEY")
supabase = create_client(url, key)


# ============================================================
# 계산 함수
# ============================================================

def compute_appreciation(original, current):
    if original is None or current is None or original == 0:
        return None
    return round((current - original) / original * 100, 2)


def compute_capital_gain(original, current):
    if original is None or current is None:
        return None
    return current - original


def compute_price_per_sqft(price, sqft):
    if price is None or sqft is None or sqft == 0:
        return None
    return round(price / sqft, 2)


def compute_rental_yield(rent_monthly, price):
    if rent_monthly is None or price is None or price == 0:
        return None
    return round((rent_monthly * 12) / price * 100, 2)


# ============================================================
# Unit 정렬 함수
# ============================================================

# unit_type 순서 정의 (작은 평수 → 큰 평수)
UNIT_TYPE_ORDER = {
    "Studio": 0,
    "1BR": 1,
    "1BR-01": 1,
    "1BR-02": 1,
    "1BR Pod": 1,
    "1BR Tower": 2,
    "1BR(PH)": 2,
    "2BR": 3,
    "2BR-01": 3,
    "2BR-02": 3,
    "2BR(2b3b)": 3,
    "2BR(대형)": 4,
    "2BR Pod": 3,
    "2BR Tower": 4,
    "Tower 2BR": 4,
    "3BR": 5,
    "3BR(PT)": 5,
    "3BR(PH)": 5,
    "3BR Pod": 5,
    "3BR Tower": 6,
    "Tower 3BR": 6,
    "4BR": 7,
    "5BR(PH)": 8,
    "Villa": 7,
    "PH": 8,
    "PT": 9,
}


def unit_sort_key(u):
    """
    unit 정렬 키 생성
    1순위: 침실 수 (UNIT_TYPE_ORDER)
    2순위: 같은 타입 내에서 매물 있는 것 먼저 (current_list_price 존재 여부)
    3순위: 매물가 오름차순 (NULL은 맨 뒤)
    """
    unit_type = u.get("unit_type", "")
    type_order = UNIT_TYPE_ORDER.get(unit_type, 99)
    
    has_price = u.get("current_list_price") is not None
    price = u.get("current_list_price") if has_price else float("inf")
    
    # has_price=True가 먼저 오게 하기 위해 False=1, True=0
    return (type_order, 0 if has_price else 1, price)


# ============================================================
# 대표 매물 선정 (타입별 시세 1개)
# ============================================================

def _is_active_listing(u):
    """현재 시장에 올라와 있는(가격이 있는) 매물인가.
    is_active 컬럼이 없던 옛 데이터도 안전: 가격이 있으면 활성으로 간주."""
    return bool(u.get("is_active", True)) and u.get("current_list_price") is not None


def select_representatives(units):
    """
    한 building의 unit들을 unit_type별로 묶어 '대표 1개'씩 선정한다.

    규칙 — 활성 매물 중 '2번째 최고가'.
      (최고가는 허위/과대호가일 수 있어 한 칸 깎아서 본다)
        · 활성 3개 이상 : 가격 내림차순 2번째
        · 활성 2개      : 둘 중 낮은 쪽 (= 2번째 최고가)
        · 활성 1개      : 그 1개
        · 활성 0개      : 가격이 남아 있는 비활성 매물 중 최신(last_seen)을
                          '직전 호가(stale)'로 표시. 그것도 없으면 타입 자체를 숨김.

    각 대표 unit에 메타를 부여:
        listing_count : 그 타입의 현재 활성 매물 수
        is_stale      : 활성 0개라 과거 값으로 대체했는가
        as_of         : stale일 때 그 값의 기준일(last_seen), 아니면 None
    """
    by_type = defaultdict(list)
    for u in units:
        by_type[u.get("unit_type", "")].append(u)

    reps = []
    for _unit_type, group in by_type.items():
        actives = sorted(
            [u for u in group if _is_active_listing(u)],
            key=lambda u: u["current_list_price"],
            reverse=True,
        )

        if len(actives) >= 2:
            rep = dict(actives[1])          # 2번째 최고가
            rep["is_stale"] = False
            rep["as_of"] = None
        elif len(actives) == 1:
            rep = dict(actives[0])
            rep["is_stale"] = False
            rep["as_of"] = None
        else:
            # 활성 0개 → 직전 호가(stale). 가격이 남아 있는 비활성 매물 중 최신.
            priced = [u for u in group if u.get("current_list_price") is not None]
            if not priced:
                continue                    # 보여줄 시세가 전혀 없음 → 표시 안 함
            priced.sort(key=lambda u: (u.get("last_seen") or ""), reverse=True)
            rep = dict(priced[0])
            rep["is_stale"] = True
            rep["as_of"] = rep.get("last_seen")

        rep["listing_count"] = len(actives)
        reps.append(rep)

    return reps


# ============================================================
# 럭셔리 정의 + 통계 계산
# ============================================================

def is_luxury(unit):
    """
    럭셔리 매물 판별
    조건 1: PT 또는 Villa 타입 (무조건 럭셔리)
    조건 2: 3BR/PH 이상 AND 면적 1,400sqft 이상 AND (매물가 $2M 이상 또는 매물 없음)
    """
    unit_type = unit.get("unit_type", "")
    sqft = unit.get("living_sqft") or 0
    price = unit.get("current_list_price")
    
    # 조건 1: PT, Villa는 무조건 럭셔리
    if "PT" in unit_type or "Villa" in unit_type:
        return True
    
    # 조건 2: 3BR 이상 OR PH(Penthouse) — 단, 면적 + 가격 조건도 충족해야 함
    # 1BR(PH) 같은 작은 PH는 면적 조건에서 자연스럽게 걸러짐
    is_3br_plus = "3BR" in unit_type or "PH" in unit_type
    is_big = sqft >= 1400
    is_expensive = price is None or price >= 2_000_000
    
    return is_3br_plus and is_big and is_expensive


def compute_stats(towers_data):
    """
    전체 시장 + 럭셔리 시장 통계 계산
    """
    # 모든 unit 수집
    all_units = []
    for t in towers_data:
        for u in t["units"]:
            u_with_tower = dict(u)
            u_with_tower["building_name"] = t["building_name"]
            all_units.append(u_with_tower)
    
    # 럭셔리 / 일반 분리
    luxury_units = [u for u in all_units if is_luxury(u)]
    
    def stats_for(units, label):
        """주어진 unit 리스트의 통계 계산"""
        # 매물 있는 unit만 (가격 계산 가능한 것)
        with_price = [u for u in units if u.get("current_list_price")]
        with_apprec = [u for u in units if u.get("appreciation_pct") is not None]
        with_yield = [u for u in units if u.get("rental_yield_pct") is not None]
        
        # TOP/BOTTOM 찾기
        top_apprec = max(with_apprec, key=lambda x: x["appreciation_pct"]) if with_apprec else None
        bottom_apprec = min(with_apprec, key=lambda x: x["appreciation_pct"]) if with_apprec else None
        top_yield = max(with_yield, key=lambda x: x["rental_yield_pct"]) if with_yield else None
        
        def avg(items, attr):
            if not items:
                return None
            return round(sum(i[attr] for i in items) / len(items), 2)
        
        return {
            "label": label,
            "total_units": len(units),
            "listed_units": len(with_price),
            "avg_appreciation_pct": avg(with_apprec, "appreciation_pct"),
            "avg_yield_pct": avg(with_yield, "rental_yield_pct"),
            "top_appreciation": {
                "building_name": top_apprec["building_name"],
                "unit_type": top_apprec["unit_type"],
                "unit_no": top_apprec["unit_no"],
                "value": top_apprec["appreciation_pct"],
            } if top_apprec else None,
            "bottom_appreciation": {
                "building_name": bottom_apprec["building_name"],
                "unit_type": bottom_apprec["unit_type"],
                "unit_no": bottom_apprec["unit_no"],
                "value": bottom_apprec["appreciation_pct"],
            } if bottom_apprec else None,
            "top_yield": {
                "building_name": top_yield["building_name"],
                "unit_type": top_yield["unit_type"],
                "unit_no": top_yield["unit_no"],
                "value": top_yield["rental_yield_pct"],
            } if top_yield else None,
        }
    
    return {
        "overall": stats_for(all_units, "전체 시장"),
        "luxury": stats_for(luxury_units, "럭셔리 (3BR+ / 1,400sqft+)"),
    }


# ============================================================
# 데이터 처리
# ============================================================

def fetch_and_enrich():
    """towers 기준으로 조회, units를 함께 가져옴"""
    
    response = (
        supabase
        .table("towers")
        .select(
            "id, building_name, neighborhood, year_completed, status, latitude, longitude, notes, "
    "units(id, unit_type, unit_no, living_sqft, "
          "original_price, current_list_price, est_rent_monthly, "
          "hoa_monthly, view_type, listing_url, notes, "
          "is_active, first_seen, last_seen)"
        )
        .order("year_completed")
        .execute()
    )
    
    towers_output = []
    total_units = 0
    
    for tower in response.data:
        # 각 unit에 파생값 계산
        enriched_units = []
        for u in tower.get("units", []):
            u["appreciation_pct"] = compute_appreciation(u["original_price"], u["current_list_price"])
            u["capital_gain"] = compute_capital_gain(u["original_price"], u["current_list_price"])
            u["price_per_sqft"] = compute_price_per_sqft(u["current_list_price"], u["living_sqft"])
            u["rental_yield_pct"] = compute_rental_yield(u["est_rent_monthly"], u["current_list_price"])
            enriched_units.append(u)
        
        # 타입별 대표 1개 자동 선정 (raw 매물 → 시세 1개)
        representatives = select_representatives(enriched_units)

        # 의미적 정렬 적용 (대표들끼리 침실 수 순)
        representatives.sort(key=unit_sort_key)

        total_units += len(representatives)

        towers_output.append({
            "building_name": tower["building_name"],
    "neighborhood": tower["neighborhood"],
    "year_completed": tower["year_completed"],
    "status": tower["status"],
    "latitude": tower["latitude"],
    "longitude": tower["longitude"],
    "notes": tower.get("notes"),
    "units": representatives,
    "unit_count": len(representatives),
    "active_listings": sum(1 for u in enriched_units if _is_active_listing(u)),
        })
    
    # 통계 계산
    market_stats = compute_stats(towers_output)
    
    return {
        "build_timestamp": datetime.now().isoformat(),
        "total_units": total_units,
        "total_towers": len(towers_output),
        "towers": towers_output,
        "stats": market_stats,
    }


# ============================================================
# 출력 함수
# ============================================================

def format_pct(v):
    if v is None:
        return "-"
    return f"{v:+.1f}%"


def format_money(v):
    if v is None:
        return "-"
    return f"${v:,.0f}"


def print_tower_report(tower_data):
    units = tower_data["units"]
    name = tower_data["building_name"]
    year = tower_data["year_completed"]
    status_label = "완공" if tower_data["status"] == "completed" else "완공 예정"
    
    print()
    print("=" * 90)
    print(f"  {name} ({year}, {status_label}) — {len(units)}개 매물")
    print("=" * 90)
    
    if not units:
        print("  (매물 데이터 없음 — 위치 마커만 표시)")
        return
    
    print(f"  {'타입':<14} {'호수':<8} {'면적':>6} {'분양가':>13} {'매물가':>13} {'상승률':>9} {'임대수익률':>11}")
    print("  " + "-" * 86)
    
    for u in units:
        unit_type = u["unit_type"]
        unit_no = u["unit_no"] if u["unit_no"] else "-"
        sqft = f"{u['living_sqft']}" if u["living_sqft"] else "-"
        original = format_money(u["original_price"])
        current = format_money(u["current_list_price"])
        appreciation = format_pct(u["appreciation_pct"])
        yield_pct = format_pct(u["rental_yield_pct"])
        
        print(f"  {unit_type:<14} {unit_no:<8} {sqft:>6} {original:>13} {current:>13} {appreciation:>9} {yield_pct:>11}")


# ============================================================
# 메인
# ============================================================

if __name__ == "__main__":
    print("Supabase에서 데이터 가져오는 중...")
    output = fetch_and_enrich()
    print(f"총 {output['total_towers']}개 콘도, {output['total_units']}개 unit 조회 완료\n")
    
    for tower_data in output["towers"]:
        print_tower_report(tower_data)
    
    json_path = "ward_village_data.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    
    # 통계 출력
    print()
    print("=" * 90)
    print("  시장 통계")
    print("=" * 90)
    for key in ["overall", "luxury"]:
        s = output["stats"][key]
        print()
        print(f"  [{s['label']}] {s['listed_units']}/{s['total_units']}개 매물")
        if s["avg_appreciation_pct"] is not None:
            print(f"    평균 상승률:    {s['avg_appreciation_pct']:+.1f}%")
        if s["avg_yield_pct"] is not None:
            print(f"    평균 임대수익률: {s['avg_yield_pct']:.2f}%")
        if s["top_appreciation"]:
            t = s["top_appreciation"]
            print(f"    상승률 TOP:     {t['building_name']} {t['unit_type']} {t['unit_no']} ({t['value']:+.1f}%)")
        if s["bottom_appreciation"]:
            b = s["bottom_appreciation"]
            print(f"    상승률 BOTTOM:  {b['building_name']} {b['unit_type']} {b['unit_no']} ({b['value']:+.1f}%)")
        if s["top_yield"]:
            y = s["top_yield"]
            print(f"    수익률 TOP:     {y['building_name']} {y['unit_type']} {y['unit_no']} ({y['value']:.2f}%)")
    
    print()
    print("=" * 90)
    print(f"  빌드 완료")
    print(f"    콘도: {output['total_towers']}개 (완공 + 완공 예정)")
    print(f"    매물: {output['total_units']}개 (정렬 적용)")
    print(f"    저장: {json_path}")
    print(f"    타임스탬프: {output['build_timestamp']}")
    print("=" * 90)


