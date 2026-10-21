# 홈페이지 자동 백업
#  - 관리자 페이지(admin.html)에서 GitHub에 저장한 내용을 G:\icl.github 로 받아오고
#  - 마지막 백업 이후 바뀐 것이 있으면 E:\icl.website 에 백업합니다 (git_push_backup 과 같은 방식).
#  - 작업 스케줄러가 하루에 한 번(매일 12:00, 그 시간에 PC가 꺼져 있었으면 켜진 뒤 바로) 조용히 실행합니다.
#    바뀐 것이 없으면 아무것도 하지 않습니다.
#  - G: 나 E: 가 연결되어 있지 않거나 인터넷이 안 되면 건너뛰고 다음 실행 때 다시 합니다.

$repoPath   = "G:\icl.github"
$backupPath = "E:\icl.website"
$logFile    = "$repoPath\backup_log.txt"
$marker     = "$repoPath\.git\icl_last_backup"    # 마지막으로 백업한 커밋 (git_push_backup 도 같이 씀)
$noticeFile = "$repoPath\.git\icl_last_notice"    # 같은 경고를 매일 반복해서 쓰지 않기 위한 기록

function Log($text) { Add-Content -Path $logFile -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [자동] $text" }
function ReadFile($p) { if (Test-Path $p) { (Get-Content $p -Raw).Trim() } else { "" } }
function NoticeOnce($key, $text) {
    if ((ReadFile $noticeFile) -ne $key) { Log $text; Set-Content -Path $noticeFile -Value $key }
}

if (-not (Test-Path "$repoPath\.git")) { exit 0 }          # G: 가 연결되어 있지 않음
Set-Location -Path $repoPath
$ErrorActionPreference = 'Continue'

# 1. GitHub 에 새 내용이 있는지 확인
git fetch --quiet origin main 2>$null
if ($LASTEXITCODE -eq 0) {
    $head   = "$(git rev-parse HEAD)".Trim()
    $remote = "$(git rev-parse origin/main)".Trim()
    if ($head -ne $remote) {
        $base = "$(git merge-base HEAD origin/main)".Trim()
        if ($base -eq $head) {
            # 관리자 페이지에서 저장한 새 내용 → 받아오기
            $dirty = @(git status --porcelain --untracked-files=no)
            if ($dirty.Count -gt 0) {
                NoticeOnce "dirty-$remote" ("GitHub에 새 내용이 있지만 이 PC에서 고치고 있는 파일이 있어 받아오지 않았습니다. " +
                    "고친 파일을 커밋한 뒤 git pushbackup 을 실행하세요: " + (($dirty | ForEach-Object { "$_".Trim() }) -join ', '))
            } else {
                $out = git pull --ff-only --quiet origin main 2>&1
                if ($LASTEXITCODE -eq 0) { Log "관리자 페이지에서 저장한 내용을 받았습니다 ($($head.Substring(0,7)) → $($remote.Substring(0,7)))" }
                else { NoticeOnce "pullfail-$remote" "GitHub 내용을 받지 못했습니다: $out" }
            }
        } elseif ($base -ne $remote) {
            NoticeOnce "diverged-$remote" "이 PC와 GitHub에 서로 다른 변경이 있습니다. git pushbackup 을 실행해 합쳐주세요."
        }
        # base == remote 이면 이 PC에만 있는 커밋(아직 안 올림) → git pushbackup 이 올림
    }
}

# 2. 마지막 백업 이후 바뀐 것이 있으면 E: 에 백업
$head = "$(git rev-parse HEAD)".Trim()
if ($head -and $head -ne (ReadFile $marker)) {
    if (-not (Test-Path (Split-Path $backupPath -Qualifier))) { exit 0 }   # E: 가 연결되면 다음 실행 때 백업
    Robocopy $repoPath $backupPath /MIR /XD .git /NP /NFL /NDL /NJH "/LOG+:$logFile" | Out-Null
    if ($LASTEXITCODE -lt 8) {
        Set-Content -Path $marker -Value $head
        Log "$backupPath 백업 완료 (커밋 $($head.Substring(0,7)): $("$(git log -1 --format=%s)".Trim()))"
    } else {
        Log "백업 실패 (robocopy 오류 코드 $LASTEXITCODE). E: 드라이브를 확인하세요."
    }
}
exit 0
