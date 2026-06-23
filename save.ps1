# ============================================================
# save.ps1 — 현재 상태를 git에 저장(커밋)하고 GitHub에 올림
#
# 사용법:
#   .\save.ps1           → 자동 메모(날짜+시간)로 저장
#   .\save.ps1 "메모"    → 직접 메모로 저장  (예: .\save.ps1 "Waiea 2BR 정리")
# ============================================================

param([string]$msg)

# 이 스크립트가 있는 폴더에서 실행 (어디서 호출해도 안전)
Set-Location -Path $PSScriptRoot

# 메모를 안 주면 날짜+시간으로 자동 생성
if ([string]::IsNullOrWhiteSpace($msg)) {
    $msg = "update " + (Get-Date -Format "yyyy-MM-dd HH:mm")
}

# 바뀐 파일 전부 담기
git add .

# 담긴 변경이 있는지 확인 (없으면 커밋 건너뜀)
git diff --cached --quiet
if ($LASTEXITCODE -eq 0) {
    Write-Host "변경된 내용이 없어요 — 커밋할 게 없습니다." -ForegroundColor Yellow
    exit 0
}

# 스냅샷 저장
git commit -m $msg
Write-Host "커밋 완료: $msg" -ForegroundColor Green

# GitHub에 올리기 (원격/업스트림 미설정이면 경고만 하고 넘어감)
git push 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "GitHub 푸시 완료 ✅" -ForegroundColor Green
} else {
    Write-Host "로컬 커밋은 됐어요. 푸시는 건너뜀(원격 미설정 등) — 필요하면 'git push' 직접 실행." -ForegroundColor Yellow
}
