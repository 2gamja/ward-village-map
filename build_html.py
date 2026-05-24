"""
build_html.py — JSON 데이터를 HTML 시세맵으로 빌드
v2: 5개 페이지 빌드 시스템 (대표 + 지역별 4개)
"""

import json
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

BASE_DIR = Path(__file__).parent
TEMPLATE_DIR = BASE_DIR / "templates"
OUTPUT_DIR = BASE_DIR
DATA_FILE = BASE_DIR / "ward_village_data.json"

OUTPUT_DIR.mkdir(exist_ok=True)

# ============================================================
# 콘도 약자 매핑 (31개)
# ============================================================
TOWER_ABBR = {
    # Ward Village (13개) — 기존
    "Waiea": "Wa",
    "Anaha": "An",
    "Ae'o": "Ae",
    "Ke Kilohana": "Ke",
    "'A'ali'i": "Aa",
    "Ko'ula": "Ko",
    "Victoria Place": "VP",
    "Ulana": "Ul",
    "The Park Ward Village": "Pa",
    "Kalae": "Ka",
    "The Launiu": "La",
    "'Ilima": "Il",
    "Melia": "Me",

    # Waikiki (6개)
    "Ritz-Carlton Residences Waikiki Beach": "RC",
    "Ka Lai Waikiki Beach": "KL",
    "Waikiki Beach Tower": "WBT",
    "Allure Waikiki": "AL",
    "The Watermark": "WM",
    "Waikiki Banyan": "WB",

    # Ala Moana (6개)
    "Park Lane Ala Moana": "PL",
    "ONE Ala Moana": "ONE",
    "Hokua": "HK",
    "Azure Ala Moana": "AZ",
    "Sky Ala Moana": "SKY",
    "Kapiolani Residence": "KR",

    # Salt (6개)
    "The Collection": "TC",
    "Keauhou Place": "KP",
    "Symphony Honolulu": "SY",
    "Alia": "AA",
    "Kaliu": "KU",
    "Kahuina": "KH",
}

# ============================================================
# 지역별 색상 (4색)
# ============================================================
REGION_COLORS = {
    "Ward Village": "#3B82F6",  # 블루
    "Waikiki":      "#A855F7",  # 퍼플
    "Ala Moana":    "#F97316",  # 오렌지
    "Salt":         "#10B981",  # 그린
}

# ============================================================
# 페이지 설정 (5개)
# ============================================================
PAGES = [
    {
        "filename": "index.html",
        "regions": None,  # None = 전체
        "title": "호놀룰루 콘도 시세맵",
        "subtitle": "워드빌리지 · 와이키키 · 알라모아나 · 솔트",
        "nav_key": "all",
    },
    {
        "filename": "ward-village.html",
        "regions": ["Ward Village"],
        "title": "워드빌리지 시세맵",
        "subtitle": "Howard Hughes Ward Village Master Plan",
        "nav_key": "ward-village",
    },
    {
        "filename": "waikiki.html",
        "regions": ["Waikiki"],
        "title": "와이키키 시세맵",
        "subtitle": "와이키키 럭셔리 + condotel 시장",
        "nav_key": "waikiki",
    },
    {
        "filename": "ala-moana.html",
        "regions": ["Ala Moana"],
        "title": "알라모아나 시세맵",
        "subtitle": "알라모아나 럭셔리 (Hokua → Park Lane → Azure)",
        "nav_key": "ala-moana",
    },
    {
        "filename": "salt.html",
        "regions": ["Salt"],
        "title": "솔트 시세맵",
        "subtitle": "Our Kakaako Increment I (완공) + II (분양 중)",
        "nav_key": "salt",
    },
]

# ============================================================
# 데이터 로딩 + 필터링
# ============================================================
def load_data():
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def filter_data_by_regions(data, regions):
    """
    regions=None이면 전체, 리스트면 해당 neighborhood만 필터링.
    통계도 필터링된 데이터 기준으로 재계산해야 정확하지만, 
    일단 v1은 전체 통계 그대로 쓰고 v2에서 개선.
    """
    if regions is None:
        return data
    
    filtered_towers = [t for t in data["towers"] if t.get("neighborhood") in regions]
    
    # 필터링된 데이터 기준으로 통계 재계산
    from collections import defaultdict
    
    all_units = []
    for t in filtered_towers:
        for u in t.get("units", []):
            u_copy = dict(u)
            u_copy["building_name"] = t["building_name"]
            all_units.append(u_copy)
    
    def is_luxury(unit):
        unit_type = unit.get("unit_type", "")
        sqft = unit.get("living_sqft") or 0
        price = unit.get("current_list_price")
        if "PT" in unit_type or "Villa" in unit_type:
            return True
        is_3br_plus = "3BR" in unit_type or "PH" in unit_type
        is_big = sqft >= 1400
        is_expensive = price is None or price >= 2_000_000
        return is_3br_plus and is_big and is_expensive
    
    luxury_units = [u for u in all_units if is_luxury(u)]
    
    def stats_for(units, label):
        with_price = [u for u in units if u.get("current_list_price")]
        with_apprec = [u for u in units if u.get("appreciation_pct") is not None]
        with_yield = [u for u in units if u.get("rental_yield_pct") is not None]
        
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
    
    filtered_stats = {
        "overall": stats_for(all_units, "전체 시장"),
        "luxury": stats_for(luxury_units, "럭셔리 (3BR+ / 1,400sqft+)"),
    }
    
    total_units = sum(len(t.get("units", [])) for t in filtered_towers)
    
    return {
        "build_timestamp": data["build_timestamp"],
        "total_units": total_units,
        "total_towers": len(filtered_towers),
        "towers": filtered_towers,
        "stats": filtered_stats,
    }


# ============================================================
# 빌드
# ============================================================
def build_page(data, page_config):
    env = Environment(
        loader=FileSystemLoader(TEMPLATE_DIR),
        autoescape=False,
    )
    template = env.get_template("map_template.html.j2")
    
    return template.render(
        stats=data.get("stats"),
        build_timestamp=data["build_timestamp"],
        total_units=data["total_units"],
        total_towers=data["total_towers"],
        towers=data["towers"],
        towers_json=json.dumps(data["towers"], ensure_ascii=False),
        tower_abbr=TOWER_ABBR,
        region_colors=REGION_COLORS,
        region_colors_json=json.dumps(REGION_COLORS, ensure_ascii=False),
        page_title=page_config["title"],
        page_subtitle=page_config["subtitle"],
        current_nav=page_config["nav_key"],
        is_overview=(page_config["regions"] is None),
    )


def save_output(html_content, filename):
    output_path = OUTPUT_DIR / filename
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    return output_path


# ============================================================
# 메인
# ============================================================
if __name__ == "__main__":
    print("=" * 70)
    print("JSON 데이터 로딩 중...")
    full_data = load_data()
    print(f"전체: {full_data['total_towers']}개 콘도, {full_data['total_units']}개 매물")
    print("=" * 70)
    
    for page in PAGES:
        print(f"\n📄 {page['filename']} 빌드 중...")
        page_data = filter_data_by_regions(full_data, page["regions"])
        print(f"   콘도: {page_data['total_towers']}개, 매물: {page_data['total_units']}개")
        
        html = build_page(page_data, page)
        output_path = save_output(html, page["filename"])
        print(f"   저장: {output_path} ({output_path.stat().st_size:,} bytes)")
    
    print("\n" + "=" * 70)
    print(f"✅ 5개 페이지 빌드 완료")
    print("=" * 70)
    print(f"\n브라우저로 열기: file:///{OUTPUT_DIR / 'index.html'}")
