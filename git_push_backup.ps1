# 설정된 Git 저장소 및 백업 경로
$repoPath = "G:\icl.github"
$backupPath = "E:\icl.website"
$logFile = "$repoPath\backup_log.txt"

# 로그 기록 시작
Add-Content -Path $logFile -Value "$(Get-Date) - Git Push & Backup Started"

# Git 저장소로 이동
Set-Location -Path $repoPath

# 변경사항 확인 후 git push 실행
$gitStatus = git status --porcelain
if ($gitStatus -ne "") {
    git add .
    git commit -m "Auto commit before push"
}

# git push 실행
git push origin main 2>&1 | Tee-Object -FilePath $logFile -Append

# 백업 실행 (ROBOCOPY 사용)
Robocopy $repoPath $backupPath /MIR /XD .git > $logFile 2>&1

# 로그 기록 완료
Add-Content -Path $logFile -Value "$(Get-Date) - Git Push & Backup Completed"
