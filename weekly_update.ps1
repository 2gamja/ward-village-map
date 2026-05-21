# weekly_update.ps1 — 주간 업데이트 한 번에 실행
# 사용법: .\weekly_update.ps1

Write-Host ""
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  Ward Village 시세맵 주간 업데이트" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/3] Supabase에서 데이터 가져오기..." -ForegroundColor Yellow
python build_data.py
if ($LASTEXITCODE -ne 0) { Write-Host "build_data.py 실패!" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "[2/3] 지난주 대비 변경 사항 확인..." -ForegroundColor Yellow
python diff_data.py
if ($LASTEXITCODE -ne 0) { Write-Host "diff_data.py 실패!" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "[3/3] 시세맵 HTML 빌드..." -ForegroundColor Yellow
python build_html.py
if ($LASTEXITCODE -ne 0) { Write-Host "build_html.py 실패!" -ForegroundColor Red; exit 1 }

Write-Host ""
Write-Host "================================================================" -ForegroundColor Green
Write-Host "  주간 업데이트 완료!" -ForegroundColor Green
Write-Host "  브라우저로 output/index.html 새로고침하세요." -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host ""
