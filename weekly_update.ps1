# weekly_update.ps1 — 주간 업데이트 한 번에 실행
# 사용법: .\weekly_update.ps1

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Ward Village 시세맵 주간 업데이트" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

# venv 파이썬을 항상 사용 (활성화 안 해도 됨). 없으면 시스템 python으로 폴백.
$py = Join-Path $PSScriptRoot ".venv\Scripts\python.exe"
if (-not (Test-Path $py)) { $py = "python" }

Write-Host "[1/3] Supabase에서 데이터 가져오기..." -ForegroundColor Yellow
& $py build_data.py
if ($LASTEXITCODE -ne 0) { Write-Host "build_data.py 실패!" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "[2/3] 지난주 대비 변경 사항 확인..." -ForegroundColor Yellow
& $py diff_data.py
if ($LASTEXITCODE -ne 0) { Write-Host "diff_data.py 실패!" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "[3/3] 시세맵 HTML 빌드..." -ForegroundColor Yellow
& $py build_html.py
if ($LASTEXITCODE -ne 0) { Write-Host "build_html.py 실패!" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  주간 업데이트 완료!" -ForegroundColor Green
Write-Host "  브라우저로 output/index.html 새로고침하세요." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
