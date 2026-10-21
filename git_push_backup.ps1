# Git 저장소 및 백업 경로 설정
$repoPath = "G:\icl.github"
$backupPath = "E:\icl.website"
$logFile = "$repoPath\backup_log.txt"

function Log($text) { Add-Content -Path $logFile -Value $text }

# 로그 기록 시작 (예전 기록은 지우지 않고 아래에 덧붙입니다)
Log ""
Log "$(Get-Date) - Sync started"

# Git 저장소로 이동
Set-Location -Path $repoPath
$ErrorActionPreference = 'Continue'

# 1. 관리자 페이지(admin.html)에서 저장한 내용을 먼저 받아오기
git pull --ff-only origin main 2>&1 | ForEach-Object { Log "$_" }
if ($LASTEXITCODE -ne 0) {
    Write-Host "GitHub의 최신 내용을 받지 못했습니다. backup_log.txt 를 확인하세요." -ForegroundColor Yellow
}

# 2. 이 PC에서 직접 고치고 커밋한 내용이 있으면 올리기 (예전과 같음)
git push origin main 2>&1 | ForEach-Object { Log "$_" }

# 3. 백업 (ROBOCOPY, 결과는 로그에 덧붙임)
Robocopy $repoPath $backupPath /MIR /XD .git /NP /NFL /NDL "/LOG+:$logFile" | Out-Null
if ($LASTEXITCODE -lt 8) {
    # 자동 백업(auto_backup.ps1)이 같은 내용을 다시 백업하지 않도록 기록
    Set-Content -Path "$repoPath\.git\icl_last_backup" -Value ("$(git rev-parse HEAD)".Trim())
} else {
    Write-Host "E: 백업에 실패했습니다. E: 드라이브를 확인하세요." -ForegroundColor Yellow
}

# 로그 기록 완료
Log "$(Get-Date) - Backup Completed"

# 콘솔에 완료 메시지 출력
Write-Host "Pull, push and backup have completed. (details: backup_log.txt)"
