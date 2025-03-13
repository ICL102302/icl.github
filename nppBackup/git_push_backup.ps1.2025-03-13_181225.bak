# Git 저장소 및 백업 경로 설정
$repoPath = "G:\icl.github"
$backupPath = "E:\icl.website"
$logFile = "$repoPath\backup_log.txt"

# 로그 기록 시작
Add-Content -Path $logFile -Value "$(Get-Date) - Git Push Detected, Starting Backup..."

# Git 저장소로 이동
Set-Location -Path $repoPath

# git push 실행 (사용자가 수동으로 실행하는 것과 동일)
git push origin main 2>&1 | Tee-Object -FilePath $logFile -Append

# 백업 실행 (ROBOCOPY 사용)
Robocopy $repoPath $backupPath /MIR /XD .git > $logFile 2>&1

# 로그 기록 완료
Add-Content -Path $logFile -Value "$(Get-Date) - Backup Completed after Git Push"

