"""
build_html.py — JSON 데이터를 HTML 시세맵으로 빌드
Day 4 업데이트: 범례도 데이터 기반으로 자동 생성
"""

import json
import os
from pathlib import Path
from jinja2 import Environment, FileSystemLoader

BASE_DIR = Path(__file__).parent
TEMPLATE_DIR = BASE_DIR / "templates"
OUTPUT_DIR = BASE_DIR  # GitHub Pages는 루트의 index.html을 찾음
DATA_FILE = BASE_DIR / "ward_village_data.json"

OUTPUT_DIR.mkdir(exist_ok=True)

# 콘도 약자 매핑 (한 곳에서 관리)
TOWER_ABBR = {
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
}


def load_data():
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        return json.load(f)


def build_html(data):
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
    )


def save_output(html_content):
    output_path = OUTPUT_DIR / "index.html"
    with open(output_path, "w", encoding="utf-8") as f:
        f.write(html_content)
    return output_path


if __name__ == "__main__":
    print("JSON 데이터 로딩 중...")
    data = load_data()
    print(f"총 {data['total_towers']}개 콘도, {data['total_units']}개 매물 로드 완료")

    print("\nHTML 빌드 중...")
    html = build_html(data)

    output_path = save_output(html)
    print(f"\n빌드 완료!")
    print(f"  파일: {output_path}")
    print(f"  크기: {output_path.stat().st_size:,} bytes")
    print(f"\n브라우저로 열기: file:///{output_path}")



