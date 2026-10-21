# 자동 백업 설치 (한 번만 실행) / 제거: install_auto_backup.ps1 -Remove
#  1) 새 백업 파일들을 커밋하고
#  2) 하루에 한 번 auto_backup 이 실행되도록 작업 스케줄러에 등록하고
#  3) git pushbackup 명령이 git_push_backup.ps1 을 쓰는지 확인한 뒤
#  4) git pushbackup 과 같은 방식으로 올리고 E: 에 백업합니다.
param([switch]$Remove)

$repoPath = "G:\icl.github"
$taskName = "ICL Homepage Auto Backup"
$ErrorActionPreference = 'Continue'
function Step($msg) { Write-Host ""; Write-Host "== $msg" -ForegroundColor Cyan }

if ($Remove) {
    schtasks /Delete /TN $taskName /F
    Write-Host "자동 백업을 껐습니다. (git pushbackup 은 그대로 쓸 수 있습니다)" -ForegroundColor Green
    exit 0
}

Set-Location -Path $repoPath

Step "1/4 새 파일 커밋하기"
git pull --ff-only origin main
git add -- auto_backup.ps1 auto_backup.vbs install_auto_backup.ps1 install_auto_backup.bat uninstall_auto_backup.bat git_push_backup.ps1 admin.html
git diff --cached --quiet
if ($LASTEXITCODE -ne 0) {
    git commit -m "$(Get-Date -Format 'yyMMdd') auto backup added"
} else { Write-Host "커밋할 것이 없습니다 (이미 커밋되어 있음)." }

Step "2/4 작업 스케줄러에 등록 (매일 12:00, 창 없이 실행)"
schtasks /Create /TN $taskName /TR "wscript.exe $repoPath\auto_backup.vbs" /SC DAILY /ST 12:00 /F | Out-Host
if ($LASTEXITCODE -ne 0) { Write-Host "등록하지 못했습니다. 위 메시지를 확인하세요." -ForegroundColor Red; exit 1 }
try {   # 노트북 배터리일 때도 실행, 꺼져 있다 켜지면 놓친 실행을 바로 함
    $t = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
    $t.Settings.DisallowStartIfOnBatteries = $false
    $t.Settings.StopIfGoingOnBatteries = $false
    $t.Settings.StartWhenAvailable = $true
    Set-ScheduledTask -InputObject $t | Out-Null
} catch { }

Step "3/4 git pushbackup 명령 확인"
$alias = "$(git config --global --get alias.pushbackup)".Trim()
Write-Host "지금 설정: $(if ($alias) { $alias } else { '(없음)' })"
if ($alias -notmatch 'git_push_backup') {
    $ans = Read-Host "git pushbackup 이 git_push_backup.ps1 (받아오기 → 올리기 → E: 백업)을 실행하도록 바꿀까요? (Y/N)"
    if ($ans -match '^[Yy]') {
        git config --global alias.pushbackup "!powershell.exe -NoProfile -ExecutionPolicy Bypass -File G:/icl.github/git_push_backup.ps1"
        Write-Host "바꿨습니다."
    }
} else { Write-Host "그대로 쓰면 됩니다." }

Step "4/4 git pushbackup 과 같이 올리고 E: 에 백업"
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$repoPath\git_push_backup.ps1"
Get-Content "$repoPath\backup_log.txt" -Tail 5

Write-Host ""
Write-Host "완료했습니다. 관리자 페이지에서 저장한 내용은 매일 한 번(12:00, 그때 PC가 꺼져 있었으면 켜진 뒤) E:\icl.website 에 백업됩니다." -ForegroundColor Green
Write-Host "바로 백업하려면 git pushbackup 을 실행하세요."
Write-Host "기록은 G:\icl.github\backup_log.txt 에 남습니다. 끄려면 uninstall_auto_backup.bat 을 실행하세요."
