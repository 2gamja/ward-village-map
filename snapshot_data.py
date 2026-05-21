"""
snapshot_data.py — 현재 데이터를 "지난주" 스냅샷으로 저장
주간 운영 시작 시 실행: python snapshot_data.py

흐름:
1. ward_village_data.json (현재) 읽기
2. snapshots/ward_village_YYYY-MM-DD.json 으로 저장
3. snapshots/latest.json 으로 별칭 저장 (diff 도구가 사용)
"""

import json
import shutil
from datetime import datetime
from pathlib import Path

BASE_DIR = Path(__file__).parent
DATA_FILE = BASE_DIR / "ward_village_data.json"
SNAPSHOT_DIR = BASE_DIR / "snapshots"

# snapshots 폴더 없으면 생성
SNAPSHOT_DIR.mkdir(exist_ok=True)

if __name__ == "__main__":
    if not DATA_FILE.exists():
        print("ward_village_data.json 파일이 없습니다.")
        print("먼저 python build_data.py 를 실행하세요.")
        exit(1)
    
    # 1. 날짜별 스냅샷 저장
    today = datetime.now().strftime("%Y-%m-%d")
    snapshot_path = SNAPSHOT_DIR / f"ward_village_{today}.json"
    shutil.copy2(DATA_FILE, snapshot_path)
    
    # 2. latest.json으로도 저장 (diff 도구가 참조)
    latest_path = SNAPSHOT_DIR / "latest.json"
    shutil.copy2(DATA_FILE, latest_path)
    
    # 3. 결과 출력
    file_size = snapshot_path.stat().st_size
    
    with open(DATA_FILE, "r", encoding="utf-8") as f:
        data = json.load(f)
    
    print("=" * 60)
    print(f"스냅샷 저장 완료")
    print("=" * 60)
    print(f"  날짜:    {today}")
    print(f"  파일:    snapshots/ward_village_{today}.json")
    print(f"  별칭:    snapshots/latest.json")
    print(f"  크기:    {file_size:,} bytes")
    print(f"  콘도:    {data['total_towers']}개")
    print(f"  매물:    {data['total_units']}개")
    print()
    print("다음 단계: 데이터 업데이트 후 python diff_data.py 실행")
